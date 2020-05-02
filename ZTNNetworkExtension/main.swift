//
//  main.swift
//  ZTNNetworkExtension
//
//  Created by Alex Lisle on 4/22/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation
import NetworkExtension

autoreleasepool {
    NEProvider.startSystemExtensionMode()
    IPCConnection.shared.startListener()
}

dispatchMain()
