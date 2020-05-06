//
//  main.swift
//  NetworkExtension
//
//  Created by Alex Lisle on 5/5/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation
import NetworkExtension

autoreleasepool {
    NEProvider.startSystemExtensionMode()
    IPCConnection.shared.startListener()
}

dispatchMain()
