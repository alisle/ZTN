//
//  ClosedFlowEvent.swift
//  ZTN
//
//  Created by Alex Lisle on 5/4/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation

class ClosedFlowEvent : BaseEvent {
    let id : UUID
    
    init(id: UUID) {
        self.id = id
        super.init(.ClosedFlow)
    }
}
