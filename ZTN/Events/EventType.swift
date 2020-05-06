//
//  EventType.swift
//  ZTN
//
//  Created by Alex Lisle on 5/4/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation


public enum EventType : CaseIterable {
    case
    NewDeferredFlow,
    NewAllowedFlow,
    NewDeniedFlow,
    ClosedFlow,
    UpdatedFlow
}
