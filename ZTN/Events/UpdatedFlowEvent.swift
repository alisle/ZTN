//
//  UpdatedFlowEvent.swift
//  ZTN
//
//  Created by Alex Lisle on 5/4/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation


class UpdatedFlowEvent : BaseEvent {
    let id : UUID
    let bytesIn : Int
    let bytesOut: Int
    
    init(id: UUID, bytesIn: Int, bytesOut: Int) {
        self.id = id
        self.bytesIn = bytesIn
        self.bytesOut = bytesOut
        super.init(.UpdatedFlow)
    }
}
