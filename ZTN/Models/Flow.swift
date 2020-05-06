//
//  Flow.swift
//  ZTN
//
//  Created by Alex Lisle on 5/1/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation
import IP2Location

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

enum FlowDecision : Int {
    case allowed = 0
    case denied = 1
    case deferred = 2
}

enum FlowState : Int {
    case open = 0
    case closed = 1
}

struct FlowFactory {
    let dnsResolver : DNSResolver
    let processResolver : ProcessResolver
    let serviceResolver :  ServiceResolver
    let locationResolver : LocationResolver
    
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
        
        let location = self.locationResolver.get(remote.address.address)
        
        let service : PortServiceDetails? = {
            switch direction {
            case .inbound: return self.serviceResolver.get(local)
            case .outbound: return self.serviceResolver.get(remote)
            default: return self.serviceResolver.get(remote)
            }
        }()
        
        return Flow(
            id: id,
            state: .open,
            decision: .deferred,
            bytesIn: 0,
            bytesOut: 0,
            local: local,
            remote: remote,
            location: location,
            direction: direction,
            process: process,
            proto: proto,
            service: service,
            timestamp: Date(),
            endTimestamp: nil
        )
    }
}


struct Flow : Identifiable {
    let id : UUID
    let state : FlowState
    let decision : FlowDecision
    let bytesIn : Int
    let bytesOut : Int
    let local : SocketAddress
    let remote : SocketAddress
    let location : IP2LocationRecord?
    let direction : FlowDirection
    let process : ProcessDetails?
    let proto : FlowProtocol
    let service : PortServiceDetails?
    let timestamp : Date
    let endTimestamp : Date?
    
    func decision(decision : FlowDecision) -> Flow {
        return Flow(
            id: self.id,
            state: self.state,
            decision: decision,
            bytesIn: self.bytesIn,
            bytesOut: self.bytesOut,
            local: self.local,
            remote: self.remote,
            location: self.location,
            direction: self.direction,
            process: self.process,
            proto: self.proto,
            service: self.service,
            timestamp: self.timestamp,
            endTimestamp: self.endTimestamp
        )
    }
    func clone() -> Flow {
        return Flow(
            id: self.id,
            state: self.state,
            decision: self.decision,
            bytesIn: self.bytesIn,
            bytesOut: self.bytesOut,
            local: self.local,
            remote: self.remote,
            location: self.location,
            direction: self.direction,
            process: self.process,
            proto: self.proto,
            service: self.service,
            timestamp: self.timestamp,
            endTimestamp: self.endTimestamp
        )
    }
    
    func close() -> Flow {
        return Flow(
            id: self.id,
            state: .closed,
            decision: self.decision,
            bytesIn: self.bytesIn,
            bytesOut: self.bytesOut,
            local: self.local,
            remote: self.remote,
            location: self.location,
            direction: self.direction,
            process: self.process,
            proto: self.proto,
            service: self.service,
            timestamp: self.timestamp,
            endTimestamp: Date()
        )
        
    }
    
    func update(bytesIn: Int, bytesOut: Int) -> Flow {
        return Flow(
            id: self.id,
            state: self.state,
            decision: self.decision,
            bytesIn: bytesIn,
            bytesOut: bytesOut,
            local: self.local,
            remote: self.remote,
            location: self.location,
            direction: self.direction,
            process: self.process,
            proto: self.proto,
            service: self.service,
            timestamp: self.timestamp,
            endTimestamp: self.endTimestamp
        )
    }
}


extension Flow : Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

extension Flow: Equatable {
    public static func ==(lhs: Flow, rhs: Flow) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Flow: CustomStringConvertible {
    public var description: String {
        return "\(self.decision) - \(self.timestamp) \(self.local)->\(self.remote)"
    }
}
