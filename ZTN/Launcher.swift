//
//  Launcher.swift
//  ZTN
//
//  Created by Alex Lisle on 4/28/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation
import os.log

class Launcher : NSObject {
    let extensionLauncher = ExtensionLauncher()
    let dnsResolver = DNSResolver()
    let processResolver = ProcessResolver()
    let serviceResolver = ServiceResolver()
    let flowFactory : FlowFactory
    
    override init() {
        self.flowFactory = FlowFactory(
            dnsResolver: self.dnsResolver,
            processResolver: self.processResolver,
            serviceResolver: self.serviceResolver
        )
        
        super.init()
    }
    
    func launch() {
        extensionLauncher.load(delegate: self)
        extensionLauncher.startFilter()
        
    }
    
    func terminate() {
        extensionLauncher.stopFilter()
        extensionLauncher.terminate()
    }
}

extension Launcher : AppCommunication {
    func flow(aboutFlow flowInfo: [String: String], responseHandler:@escaping (Bool) -> Void) {
        
        os_log("NEW FLOW - %@:  %@:%@->%@:%@",
               flowInfo[FlowInfoKey.id.rawValue]!,
               flowInfo[FlowInfoKey.localAddress.rawValue]!,
               flowInfo[FlowInfoKey.localPort.rawValue]!,
               flowInfo[FlowInfoKey.remoteAddress.rawValue]!,
               flowInfo[FlowInfoKey.remotePort.rawValue]!
        )
        
        
        if let flow = self.flowFactory.generate(flow: flowInfo) {
            print("Got flow! \(flow.remote.hostname ?? "Not Known")")
        } else {
            print("Flow abandoned =(")
        }
        
        
        responseHandler(true)
        
    }
    
    func dnsPacket(aboutFlow flowInfo: [String : String]) {
        print("got dns packet")
        if let response = DNSResponse(flowDescription: flowInfo) {
            self.dnsResolver.update(response)
        }                
    }
    
    func flowReport(aboutFlow flowInfo: [String : String]) {
        os_log("NEW REPORT- %@: IN: %@ OUT: %@ TYPE: %@",
            flowInfo[FlowReportKey.id.rawValue]!,
            flowInfo[FlowReportKey.bytesInboundCount.rawValue]!,
            flowInfo[FlowReportKey.bytesOutboundCount.rawValue]!,
            flowInfo[FlowReportKey.eventType.rawValue]!
        )
    }
    
}
