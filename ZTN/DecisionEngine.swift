//
//  DecisionEngine.swift
//  ZTN
//
//  Created by Alex Lisle on 4/30/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation

enum Decision : Int {
    case Allow
    case Deny
    case Defer
}

struct Query  {
    let flow : Flow
    let handler: (Bool) -> Void
}

extension Query : Equatable {
    public static func ==(lhs: Query, rhs: Query) -> Bool {
        return lhs.flow.id == rhs.flow.id
    }
}

extension Query : Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.flow.id)
    }
}


class DecisionEngine {
    private let queue = DispatchQueue(label: "com.zerotrustnetworks.ZTN.decisionQueue", attributes: .concurrent)
    private var deferred : [Query] = []
    
    func add(flow: Flow, handler: @escaping (Bool) -> Void) {
        switch self.decide(flow: flow) {
        case .Allow:
            handler(true)
            queue.async {
              EventManager.shared.triggerEvent(event: NewAllowedFlowEvent(flow: flow.decision(decision: .allowed)))
            }
        case .Deny:
            handler(false)
            queue.async { 
                EventManager.shared.triggerEvent(event: NewDeniedFlowEvent(flow: flow.decision(decision: .denied)))
            }
        case .Defer:
            // We don't know what to do with this yet, let's defer it.
            let query = Query(flow: flow, handler: handler)
            queue.async { [ weak self ] in
                guard let self = self else {
                    return
                }
                
                self.deferred.append(query)
                EventManager.shared.triggerEvent(event: NewDeferredFlowEvent(flow: flow.decision(decision: .deferred)))
            }
        }
    }
    
    func decide(flow : Flow) -> Decision {
        return .Allow
    }
    
}
