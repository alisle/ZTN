//
//  IPAddress.swift
//  ZTN
//
//  Created by Alex Lisle on 4/27/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation


public class IPAddress {
    public enum Version {
        case IPv4, IPv6
    }
    
    public let version : Version
    public let address : String
    
    public init(_ address: String) {
        self.address = address
        if address.contains(":") {
            self.version = .IPv6
        } else {
            self.version = .IPv4
        }
    }
    
    public convenience init?(UInt32NetworkByteOrder bytes: UInt32) {
        var addr = in_addr(s_addr: bytes)
        let length = Int(INET_ADDRSTRLEN) + 2
        var buffer : Array<CChar> = Array(repeating: 0, count: length)
        
        guard let hostCString = inet_ntop(AF_INET, &addr, &buffer, socklen_t(length)) else {
            return nil
        }
        
        self.init(String.init(cString: hostCString))
    }
}


extension IPAddress : Hashable {
    public static func ==(lhs: IPAddress, rhs: IPAddress) -> Bool {
        return lhs.address == rhs.address
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.address)
    }
}

extension IPAddress : CustomStringConvertible {
    public var description: String {
        return self.address
    }
}

extension IPAddress : CustomDebugStringConvertible {
    public var debugDescription: String {
            return "\(self.address):\(self.version)"
    }
}


