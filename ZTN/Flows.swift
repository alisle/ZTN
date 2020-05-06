//
//  Flows.swift
//  ZTN
//
//  Created by Alex Lisle on 5/5/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation
import Logging

class Flows : EventListener {
    private let logger = Logger(label: "com.zerotrustnetworks.ZTN.Flows")
    private let queue = DispatchQueue(label: "com.zerotrustnetworks.ZTN.FlowsQueue", attributes: .concurrent)

    private var flows : [UUID:Flow] = [:]
    
    
    init() {
        EventManager.shared.addListener(type: .NewAllowedFlow, listener: self)
        EventManager.shared.addListener(type: .NewDeniedFlow, listener: self)
        EventManager.shared.addListener(type: .NewDeferredFlow, listener: self)
        EventManager.shared.addListener(type: .UpdatedFlow, listener: self)
        EventManager.shared.addListener(type: .ClosedFlow, listener: self)
    }
    
    func getDeferred() -> [Flow] {
        return self.queue.sync { [weak self] in
            guard let self = self else {
                return []
            }
            
            return Array(self.flows.values.filter{ $0.decision == .deferred }.map{ $0.clone() })
        }
    }
    
    func getNonDeferred() -> [Flow] {
        return self.queue.sync { [weak self] in
            guard let self = self else {
                return []
            }
            
            let array = Array(self.flows.values.filter{ $0.decision != .deferred }.map{ $0.clone() })
            return array
        }
    }
    
    
    
    func eventTriggered(event: BaseEvent) {
        self.queue.sync { [weak self] in
            guard let self = self else {
                return
            }
            
            switch(event.type) {
            case .NewAllowedFlow:
                let event = event as! NewAllowedFlowEvent
                self.flows.updateValue(event.flow, forKey: event.flow.id)
            case .NewDeniedFlow:
                let event = event as! NewDeniedFlowEvent
                self.flows.updateValue(event.flow, forKey: event.flow.id)
            case .NewDeferredFlow:
                let event = event as! NewDeferredFlowEvent
                self.flows.updateValue(event.flow, forKey: event.flow.id)
            case .UpdatedFlow:
                let event = event as! UpdatedFlowEvent
                guard var flow = self.flows[event.id] else {
                    return
                }
                
                flow = flow.update(bytesIn: event.bytesIn, bytesOut: event.bytesOut)
                self.flows.updateValue(flow, forKey: flow.id)
            case .ClosedFlow:
                let event = event as! ClosedFlowEvent
                guard var flow = self.flows[event.id] else {
                    return
                }
                
                flow = flow.close()
                self.flows.updateValue(flow, forKey: flow.id)
                
            default:
                return
            }

        }
    }
}
