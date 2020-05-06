//
//  NewAllowedFlow.swift
//  ZTN
//
//  Created by Alex Lisle on 5/4/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation


class NewAllowedFlowEvent : BaseEvent {
    let flow : Flow
    
    init(flow: Flow) {
        self.flow = flow
        super.init(.NewAllowedFlow)
    }
}
