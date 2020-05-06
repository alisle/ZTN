//
//  IPCConnection.swift
//  ZTN
//
//  Created by Alex Lisle on 4/23/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation
import os.log
import Network

@objc protocol ProviderCommunication {
    func register(_ completionHandler: @escaping (Bool) -> Void)
}

class IPCConnection: NSObject {
    var listener : NSXPCListener?
    var currentConnection: NSXPCConnection?
    weak var delegate: AppCommunication?
    static let shared = IPCConnection()
    
    
    // Used to extract the NEMachServiceName Key from the Info.plist
    private func extensionMachServiceName(from bundle: Bundle) -> String {

        guard let networkExtensionKeys = bundle.object(forInfoDictionaryKey: "NetworkExtension") as? [String: Any],
            let machServiceName = networkExtensionKeys["NEMachServiceName"] as? String else {
                fatalError("Mach service name is missing from the Info.plist")
        }

        return machServiceName
    }
    
    // Used to start the listener, this happens on the Network Extension side
    func startListener(overrideMachServiceName : String? = nil) {
        let machServiceName = overrideMachServiceName ?? extensionMachServiceName(from: Bundle.main)
        
        os_log("Starting XPC listener for mach service #@", machServiceName)
        
        let newListener = NSXPCListener(machServiceName: machServiceName)
        newListener.delegate = self
        newListener.resume()
        
        listener = newListener
    }
    
    // This is called by the App to register it's self.
    func register(withExtension bundle: Bundle, delegate: AppCommunication, completionHandler: @escaping (Bool) -> Void) {
        self.delegate = delegate
        
        guard currentConnection == nil else {
            os_log("Already registered with provider")
            completionHandler(true)
            return
        }
        
        let machServiceName = extensionMachServiceName(from: bundle)
        let newConnection = NSXPCConnection(machServiceName: machServiceName, options: [])
        
        newConnection.exportedInterface = NSXPCInterface(with: AppCommunication.self)
        newConnection.exportedObject = delegate
        
        newConnection.remoteObjectInterface = NSXPCInterface(with: ProviderCommunication.self)
        
        currentConnection = newConnection
        newConnection.resume()
        
        guard let providerProxy = newConnection.remoteObjectProxyWithErrorHandler({ registerError in
            os_log("Failed to register with the provider: %@", registerError.localizedDescription)
            self.currentConnection?.invalidate()
            self.currentConnection = nil
            
            completionHandler(false)
        }) as? ProviderCommunication else {
            fatalError("Failed to create a remote object proxy for the provider")
        }
        
        providerProxy.register(completionHandler)
    }
    
    private func generateProxy() -> AppCommunication? {
        guard let connection = currentConnection else {
            os_log("No connection to pass new flow to")
            return nil
        }
        
        guard let appProxy = connection.remoteObjectProxyWithErrorHandler( { error in
            os_log("Failed to communication: $@", error.localizedDescription)
            self.currentConnection = nil
        }) as? AppCommunication else {
            fatalError("Unable to create remote object proxy")
        }

        return appProxy
    }
    
    func flow(aboutFlow flowInfo: [String: String], responseHandler:@escaping (Bool) -> Void) -> Bool {
        guard let appProxy = self.generateProxy() else {
            return false
        }
                        
        appProxy.flow(aboutFlow: flowInfo, responseHandler: responseHandler)
        
        return true
    }
    
    func dnsPacket(aboutFlow flowInfo: [String: String]) -> Bool {
        guard let appProxy = self.generateProxy() else {
            return false
        }

        appProxy.dnsPacket(aboutFlow: flowInfo)
        
        return true
    }
    
    func flowReport(aboutFlow flowInfo: [String: String]) -> Bool {
        guard let appProxy = self.generateProxy() else {
            return false
        }

        appProxy.flowReport(aboutFlow: flowInfo)
        
        return true
    }
}

// Deals with a new listener
extension IPCConnection: NSXPCListenerDelegate {
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: ProviderCommunication.self)
        newConnection.exportedObject = self
        
        newConnection.remoteObjectInterface = NSXPCInterface(with: AppCommunication.self)
        
        newConnection.invalidationHandler = {
            self.currentConnection = nil
        }
        
        newConnection.interruptionHandler = {
            self.currentConnection = nil
        }
        
        self.currentConnection = newConnection
        newConnection.resume()
        
        return true
    }
}

extension IPCConnection: ProviderCommunication {
    func register(_ completionHandler: @escaping (Bool) -> Void) {
        os_log("App registered")
        completionHandler(true)
    }
}

