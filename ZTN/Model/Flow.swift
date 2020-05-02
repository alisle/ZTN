//
//  Flow.swift
//  ZTN
//
//  Created by Alex Lisle on 5/1/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation
enum FlowDirection : Int {
    case any = 0
    case inbound = 1
    case outbound = 2

    static func fromString(value : String) -> FlowDirection? {
        guard let value = Int(value) else {
            return nil
        }
        
        return FlowDirection(rawValue: value)
    }
}

enum FlowProtocol : Int {
    case TCP = 0
    case UDP = 1
    
    static func fromString(value : String) -> FlowProtocol? {
        guard let value = Int(value) else {
            return nil
        }
        
        if value == IPPROTO_TCP {
            return .TCP
        }
        
        
        if value == IPPROTO_UDP {
            return .UDP
        }
                
        return nil
    }
}

struct FlowFactory {
    let dnsResolver : DNSResolver
    let processResolver : ProcessResolver
    let serviceResolver :  ServiceResolver
    
    func generate(flow flowInfo:[String: String]) -> Flow?{
        guard let id = UUID.init(uuidString: flowInfo[FlowInfoKey.id.rawValue]!) else {
            return nil
        }
        
        let localAddress = IPAddress(flowInfo[FlowInfoKey.localAddress.rawValue]!)
        let remoteAddress = IPAddress(flowInfo[FlowInfoKey.remoteAddress.rawValue]!)
        
        let resolvedHostname = self.dnsResolver.get(remoteAddress)
        
        let local = SocketAddress(
            hostname: nil,
            address: localAddress,
            port: Int(flowInfo[FlowInfoKey.localPort.rawValue]!)!
        )
        
        let remote = SocketAddress(
            hostname: resolvedHostname,
            address: remoteAddress,
            port: Int(flowInfo[FlowInfoKey.remotePort.rawValue]!)!
        )
        
        guard let direction = FlowDirection.fromString(value: flowInfo[FlowInfoKey.direction.rawValue]!) else {
            return nil
        }
        
        guard let proto = FlowProtocol.fromString(value: flowInfo[FlowInfoKey.proto.rawValue]!) else {
            return nil
        }
        
        let process = self.processResolver.get(token: flowInfo[FlowInfoKey.auditTokenString.rawValue]!)
        

        let service : PortServiceDetails? = {
            switch direction {
            case .inbound: return self.serviceResolver.get(local)
            case .outbound: return self.serviceResolver.get(remote)
            default: return self.serviceResolver.get(remote)
            }
        }()
        
        return Flow(
            id: id,
            local: local,
            remote: remote,
            direction: direction,
            process: process,
            proto: proto,
            service: service
        )
    }
}


struct Flow {
    let id : UUID
    let local : SocketAddress
    let remote : SocketAddress
    let direction : FlowDirection
    let process : ProcessDetails?
    let proto : FlowProtocol
    let service : PortServiceDetails?
    let timestamp = Date()
}
