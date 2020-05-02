//
//  IPAddress.swift
//  ZTN
//
//  Created by Alex Lisle on 4/27/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation


class IPAddress {
    public enum Version {
        case IPv4, IPv6
    }
    
    let version : Version
    let address : String
    
    init(_ address: String) {
        self.address = address
        if address.contains(":") {
            self.version = .IPv6
        } else {
            self.version = .IPv4
        }
    }
    
    convenience init?(UInt32NetworkByteOrder bytes: UInt32) {
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

extension IPAddress : CustomDebugStringConvertible {
     var debugDescription: String {
            return "\(self.address):\(self.version)"
    }
}
