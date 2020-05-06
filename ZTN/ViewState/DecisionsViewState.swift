//
//  DecisionsViewState.swift
//  ZTN
//
//  Created by Alex Lisle on 5/5/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation
import Logging

class DecisionsViewState : ObservableObject {
    private let logger = Logger(label: "com.zerotrustnetworks.ZTN.Events.EventManager")
    private let flows : Flows
    
    @Published var deferredDecisions : [Flow] = []
    @Published var madeDecisions : [Flow] = []
    
    init(flows: Flows) {
        self.flows = flows
        self.updatePublishedValues()
    }
    
    private func updatePublishedValues() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0)  { [ weak self ] in
            guard let self = self else {
                return
            }
            
            let shadowDeferred = self.flows.getDeferred().sorted(by: { lhs, rhs in lhs.timestamp > rhs.timestamp})
            let shadowMade = self.flows.getNonDeferred().sorted(by: { lhs, rhs in lhs.timestamp > rhs.timestamp})
            
            self.madeDecisions  = (shadowMade.count > 100) ? shadowMade.dropLast(shadowMade.count - 100) : shadowMade
            self.deferredDecisions = (shadowDeferred.count > 100) ? shadowDeferred.dropLast(shadowDeferred.count - 100) : shadowDeferred
            
            self.updatePublishedValues()
        }
    }
}
