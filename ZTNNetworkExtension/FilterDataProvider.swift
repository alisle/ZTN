//
//  FilterDataProvider.swift
//  ZTNNetworkExtension
//
//  Created by Alex Lisle on 4/22/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import NetworkExtension
import os.log
import Darwin

class FilterDataProvider: NEFilterDataProvider {
    /*

    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        completionHandler(nil)
    }
    
    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Add code to clean up filter resources.
        completionHandler()
    }
    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        guard let socketFlow = flow as? NEFilterSocketFlow,
            let remoteEndpoint = socketFlow.remoteEndpoint as? NWHostEndpoint,
            let localEndpoint = socketFlow.localEndpoint as? NWHostEndpoint else {
                return .allow()
        }
        
        let auditTokenString = flow.sourceAppAuditToken?.base64EncodedString()
        os_log("Got a new flow with local endpoint %@, remote endpoint %@", localEndpoint, remoteEndpoint)

        let flowInfo = [
            FlowInfoKey.id.rawValue : flow.identifier.uuidString,
            FlowInfoKey.localAddress.rawValue : localEndpoint.hostname,
            FlowInfoKey.localPort.rawValue : localEndpoint.port,
            FlowInfoKey.remoteAddress.rawValue : remoteEndpoint.hostname,
            FlowInfoKey.remotePort.rawValue : remoteEndpoint.port,
            FlowInfoKey.auditTokenString.rawValue : auditTokenString!,
            FlowInfoKey.direction.rawValue : String("\(flow.direction.rawValue)"),
            FlowInfoKey.proto.rawValue : String("\(socketFlow.socketProtocol)"),
            FlowInfoKey.type.rawValue : String("\(socketFlow.socketType)"),
            FlowInfoKey.family.rawValue : String("\(socketFlow.socketFamily)"),
        ]
                
        if remoteEndpoint.port == "53" && socketFlow.socketProtocol == IPPROTO_UDP {
            // This is a DNS packet, we want to extract the goodness before we allow it.
            return .filterDataVerdict(withFilterInbound: true, peekInboundBytes: 1024, filterOutbound: false, peekOutboundBytes: 1)
        } else {
            let prompted = IPCConnection.shared.flow(aboutFlow: flowInfo) { allow in
                let verdict: NEFilterNewFlowVerdict = allow ? .allow() : .drop()
                verdict.shouldReport = true
                //verdict.statisticsReportFrequency = .medium
                self.resumeFlow(flow, with: verdict)
            }
            
            if !prompted {
                return .allow()
            }
        }
        
        return .pause()
    }
    
    override func handleInboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
        guard let socketFlow = flow as? NEFilterSocketFlow,
            let remoteEndpoint = socketFlow.remoteEndpoint as? NWHostEndpoint,
            let localEndpoint = socketFlow.localEndpoint as? NWHostEndpoint else {
                return .allow()
        }

        let flowInfo = [
            DNSPacketKey.localAddress.rawValue : localEndpoint.hostname,
            DNSPacketKey.localPort.rawValue : localEndpoint.port,
            DNSPacketKey.remoteAddress.rawValue : remoteEndpoint.hostname,
            DNSPacketKey.remotePort.rawValue : remoteEndpoint.port,
            DNSPacketKey.packet.rawValue : readBytes.base64EncodedString(),
            DNSPacketKey.offset.rawValue : String("\(offset)"),
            DNSPacketKey.size.rawValue : String("\(readBytes.count)")
        ]
            
        let _ = IPCConnection.shared.dnsPacket(aboutFlow: flowInfo)
        
        return .allow()
    }

    override func handle(_ report: NEFilterReport) {
        guard let id = report.flow?.identifier.uuidString else {
            return
        }
        
        let flowInfo = [
            FlowReportKey.id.rawValue : id,
            FlowReportKey.bytesInboundCount.rawValue : String("\(report.bytesInboundCount)"),
            FlowReportKey.bytesOutboundCount.rawValue : String("\(report.bytesOutboundCount)"),
            FlowReportKey.eventType.rawValue : String("\(report.event.rawValue)")
        ]
        
        let _ = IPCConnection.shared.flowReport(aboutFlow: flowInfo)
    }
 */
}
