//
//  Launcher.swift
//  ZTN
//
//  Created by Alex Lisle on 4/22/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation
import Darwin

import os.log
import SystemExtensions
import NetworkExtension

enum ExtensionLauncherStatus  {
    case loading
    case loaded
    case running
    case stopped
    case unknown
}



class ExtensionLauncher : NSObject {
    lazy var extensionBundle: Bundle = {
        let extensionsDirectoryURL = URL(fileURLWithPath: "Contents/Library/SystemExtensions", relativeTo: Bundle.main.bundleURL)
        let extensionURLs : [URL]
        
        do {
            extensionURLs = try FileManager.default.contentsOfDirectory(at: extensionsDirectoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        } catch let error {
            fatalError("Failed to get the contents of \(extensionsDirectoryURL.absoluteString): \(error.localizedDescription)")
        }
        
        guard let extensionURL = extensionURLs.first else {
            fatalError("Failed to find any system extensions")
        }
        
        guard let extensionBundle = Bundle(url: extensionURL) else {
            fatalError("Failed to create a bunlde with URL \(extensionURL.absoluteString)")
        }
        
        return extensionBundle
    }()
    
    var delegate : AppCommunication? = nil
    var status : ExtensionLauncherStatus = .stopped
    var observer: Any?
    
    func load(delegate : AppCommunication) {
        self.delegate = delegate
        self.status = .loading
        os_log("entered into launcher")
        loadFilterConfiguration { success in
            self.observer = NotificationCenter.default.addObserver(forName: .NEFilterConfigurationDidChange, object: NEFilterManager.shared(), queue: .main) {
                [weak self] _ in
                self?.queryStatus()
            }

            if !success {
                os_log("Failed to load filter configuration")
            }
        }
    }
    
    
    func terminate() {
        os_log("exited from launcher")
        
        guard let changeObserver = observer else {
            return
        }

        NotificationCenter.default.removeObserver(changeObserver, name: .NEFilterConfigurationDidChange, object: NEFilterManager.shared())
        while( self.status == .unknown) {
            // Waiting to finish.
            sleep(5)
        }
    }
    
    
    // MARK: Filter Configuration
    func loadFilterConfiguration(completionHandler: @escaping (Bool) -> Void) {
        NEFilterManager.shared().loadFromPreferences { loadError in
            DispatchQueue.main.async {
                var success = true
                if let error = loadError {
                    os_log("Failed to load the filter configuration: %@", error.localizedDescription)
                    success = false
                } else {
                    os_log("Successfully loaded filter configuration")
                }
                
                completionHandler(success)
            }
        }
    }
    
    // MARK: Provider Creation
    func registerWithProvider() {
        IPCConnection.shared.register(withExtension: extensionBundle, delegate: self.delegate!) { success in
            DispatchQueue.main.async {
                self.status =  (success ? .running : .stopped)
                
                if success {
                    os_log("Successfully registered with Provider")
                } else {
                    os_log("Unable to register with Provider")
                }
            }
            
        }
    }
    
    func startFilter() {
        status = .unknown
        if NEFilterManager.shared().isEnabled {
            // We are already enabled, check that the IPC connection is still going.
            registerWithProvider()
            return
        }
        
        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            // We don't know what our extension is.
            self.status = .stopped
            return
        }
        
        let activationRequest = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: .main)
        activationRequest.delegate = self
        OSSystemExtensionManager.shared.submitRequest(activationRequest)
    }
    
    func stopFilter() {
        let filterManager = NEFilterManager.shared()
        
        status = .unknown
        if !filterManager.isEnabled {
            status = .stopped
            return
        }
        
        loadFilterConfiguration { success in
            guard success else {
                self.status = .running
                return
            }

            filterManager.isEnabled = false
            filterManager.saveToPreferences { saveError in
                DispatchQueue.main.async {
                    if let error = saveError {
                        os_log("Failed to disable the filter configuration: #@", error.localizedDescription)
                        self.status = .running
                        return
                    }
                    
                    self.status = .stopped
                }
            }
        }
    }
    
    func queryStatus() {
        if NEFilterManager.shared().isEnabled {
            registerWithProvider()
        } else {
            self.status = .stopped
        }
    }
    
    func enableFilterConfiguration() {
        let filterManager = NEFilterManager.shared()
/*
        if filterManager.isEnabled {
            registerWithProvider()
            return
        }
  */
        
        let providerConfiguration = NEFilterProviderConfiguration()
        providerConfiguration.filterSockets = true
        providerConfiguration.filterPackets = false        
        filterManager.providerConfiguration = providerConfiguration
        if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            filterManager.localizedDescription = appName
        }

        filterManager.isEnabled =  true
        filterManager.saveToPreferences { saveError in
            DispatchQueue.main.async {
                if let error = saveError {
                    os_log("Failed to save the filter configuration: $@", error.localizedDescription)
                    self.status = .stopped
                    return
                } else {
                    os_log("Successfully enabled filter")
                }
                
                self.registerWithProvider()
            }
            
        }

        /*
        loadFilterConfiguration { success in
            guard success else {
                self.status = .stopped
                return
            }
            
            //if filterManager.providerConfiguration == nil {
            //}
            
        }
 */
    }
}

extension ExtensionLauncher : OSSystemExtensionRequestDelegate {
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        guard result == .completed else {
            os_log("Unexpected result %d for system extension request", result.rawValue)
            return
        }
        
        enableFilterConfiguration()
    }

    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        os_log("System extension request failed: %@", error.localizedDescription)
    }

    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {

        os_log("Extension %@ requires user approval", request.identifier)
    }

    func request(_ request: OSSystemExtensionRequest,
                 actionForReplacingExtension existing: OSSystemExtensionProperties,
                 withExtension extension: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {

        os_log("Replacing extension %@ version %@ with version %@", request.identifier, existing.bundleShortVersion, `extension`.bundleShortVersion)
        return .replace
    }

}
