//
//  SocketAddress.swift
//  ZTN
//
//  Created by Alex Lisle on 4/27/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation


public struct SocketAddress {
    public let hostname : String?
    public let address : IPAddress
    public let port : Int
}

extension SocketAddress : CustomStringConvertible {
    public var description: String {
        return "\(hostname ?? address.description):\(port)"
    }
}
