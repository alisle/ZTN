//
//  ProcessInfo.swift
//  ZeroTrust FW
//
//  Created by Alex Lisle on 2/28/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation
import SwiftUI


public struct BundleDetails {
    let signedIdentifier : String?
    let id : String?
    let version : String?
    let name : String?
    let displayName : String?
    let executable : String?
    let iconFile : NSImage?
}

public class ProcessDetails {
    public let pid : Int
    public let ppid: Int
    public let uid : Int
    public let username : String?
    public let path : String
    public let parent : ProcessDetails?
    public let bundle : BundleDetails?
    public let sha256 : String?
    public let md5 : String?
    public let peers : [ProcessDetails]
    public let displayName: String
    
    public var hasPeers : Bool {
        get {
            return  self.peers.count != 0
        }
    }
    
    public init(pid : Int,
                ppid: Int,
                uid : Int,
                username : String?,
                path : String,
                parent : ProcessDetails?,
                bundle: BundleDetails?,
                sha256: String?,
                md5: String?,
                peers : [ProcessDetails]
                ) {
        self.pid = pid
        self.ppid = ppid
        self.uid = uid
        self.username = username
        self.path = path
        self.parent = parent
        self.bundle = bundle
        self.sha256 = sha256
        self.md5 = md5
        self.peers = peers
        self.displayName = bundle?.displayName ?? path
    }
}

extension ProcessDetails : CustomStringConvertible {
    public var description: String  {
        return "PID:\(self.pid), PPID:\(self.ppid), USER: \(self.username ?? "unknown")(\(String(describing: self.uid))) - COMMAND: \(self.path)"
    }
    
    public var shortDescription : String {
        return "PID:\(self.pid) - UID:\(self.uid) - \(self.path)"
    }
}

extension ProcessDetails : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(pid)
        hasher.combine(ppid)
        hasher.combine(uid)
        hasher.combine(path)
    }
}


extension ProcessDetails : Equatable {
    public static func ==(lhs:ProcessDetails, rhs: ProcessDetails) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension ProcessDetails : Identifiable {
    public var id: Int {
        get {
            return self.hashValue
        }
    }
}
