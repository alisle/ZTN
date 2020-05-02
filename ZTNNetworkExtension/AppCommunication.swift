//
//  AppCommunication.swift
//  ZTN
//
//  Created by Alex Lisle on 4/26/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation

enum FlowInfoKey: String {
    case id
    case localPort
    case localAddress
    case remotePort
    case remoteAddress
    case pid
    case auditTokenString
    case direction
    case proto
    case type
    case family
}

enum DNSPacketKey : String {
    case localPort
    case localAddress
    case remotePort
    case remoteAddress
    case packet
    case offset
    case size
}

enum FlowReportKey : String {
    case id
    case bytesInboundCount
    case bytesOutboundCount
    case eventType
}

@objc protocol AppCommunication {
    func flow(aboutFlow flowInfo: [String: String], responseHandler:@escaping (Bool) -> Void)
    func dnsPacket(aboutFlow flowInfo: [String: String])
    func flowReport(aboutFlow flowInfo: [String: String])
}
