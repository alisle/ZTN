//
//  EventManager.swift
//  ZTN
//
//  Created by Alex Lisle on 5/4/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation
import Logging

public class BaseEvent {
    public let type : EventType
    
    init(_ type: EventType) {
        self.type = type
    }
}


public protocol EventListener {
    func eventTriggered(event: BaseEvent)
}

class EventManager {
    static public let shared = EventManager()
    private let listenerQueue = DispatchQueue(label: "com.zerotrustnetworks.ZTN.eventQueue", attributes: .concurrent)
    let logger = Logger(label: "com.zerotrustnetworks.ZTN.Events.EventManager")
    
    private var all : [EventType: [EventListener]] = [:]
    
    public func addListener(type: EventType, listener : EventListener) {
        logger.info("adding new listener for type: \(type)")
        self.listenerQueue.sync { [weak self] in
            guard let self = self else {
                return
            }
            
            
            if self.all[type] == nil {
                self.all[type] = []
            }
            self.all[type]!.append(listener)
        }
    }
    
    public func triggerEvent(event: BaseEvent) {
        logger.debug("triggering event for: \(event.type)")

        self.listenerQueue.sync { [weak self] in
            guard let self = self else {
                return
            }
            
            if let listeners = self.all[event.type] {
                listeners.forEach{ $0.eventTriggered(event: event) }
            }
        }

    }

}
