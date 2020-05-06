//
//  DNSResponse.swift
//  ZTN
//
//  Created by Alex Lisle on 4/27/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation
import os.log


public class DNSResponse {
    public let localSocket : SocketAddress
    public let remoteSocket : SocketAddress
    
    // DNS Headers
    public let id : UInt16
    public let flags : UInt16
    public let questionCount : UInt16
    public let answerCount : UInt16
    public let authorityCount : UInt16
    public let additionalCount : UInt16
    public let questions : [String]
    public let arecords : [(url: String, ip:IPAddress)]
    public let cnames : [(url: String, cname: String)]
    
    
    init?(flowDescription info : [String:String]) {
        guard let localAddress = info[DNSPacketKey.localAddress.rawValue],
            let localPort = info[DNSPacketKey.localPort.rawValue],
            let remoteAddress =  info[DNSPacketKey.remoteAddress.rawValue],
            let remotePort = info[DNSPacketKey.remotePort.rawValue],
            let packet = info[DNSPacketKey.packet.rawValue] else {
                return nil
        }

        
        self.localSocket = SocketAddress(
            hostname: nil,
            address: IPAddress(localAddress),
            port: Int(localPort)!
        )
        
        self.remoteSocket = SocketAddress(
            hostname: nil,
            address: IPAddress(remoteAddress),
            port: Int(remotePort)!
        )
        
        guard let data = Data.init(base64Encoded: packet) else {
            return nil
        }
        
        self.id = data.withUnsafeBytes { rawBufferPointer in
            let rawPointer = rawBufferPointer.baseAddress!
            return rawPointer.load(as: UInt16.self).bigEndian
        }
        
        self.flags = data.withUnsafeBytes{ rawBufferPointer in
            let rawPointer = rawBufferPointer.baseAddress!
            return UInt16((rawPointer.load(as: UInt32.self).bigEndian << 16) >> 16)
        }
        
        let questionCount : UInt16 = data.withUnsafeBytes{ rawBufferPointer in
            let rawPointer = rawBufferPointer.baseAddress!
            return rawPointer.load(fromByteOffset: 4, as: UInt16.self).bigEndian
        }
        
        let answerCount : UInt16 = data.withUnsafeBytes{ rawBufferPointer in
            let rawPointer = rawBufferPointer.baseAddress!
            return UInt16((rawPointer.load(fromByteOffset: 4, as: UInt32.self).bigEndian << 16) >> 16)
        }
        
        self.authorityCount = data.withUnsafeBytes{ rawBufferPointer in
            let rawPointer = rawBufferPointer.baseAddress!
            return rawPointer.load(fromByteOffset: 8, as: UInt16.self).bigEndian
        }
        
        self.additionalCount = data.withUnsafeBytes{ rawBufferPointer in
            let rawPointer = rawBufferPointer.baseAddress!
            return UInt16((rawPointer.load(fromByteOffset: 8, as: UInt32.self).bigEndian << 16) >> 16)
        }
        
        var offset = 12
        self.questions = data.withUnsafeBytes { rawBufferPointer in
            let rawPointer = rawBufferPointer.baseAddress!
            return DNSResponse.grabQuestions(pointer: rawPointer, numberOfQuestions: questionCount, byteOffset: &offset)
        }
        
        let result : (arecords: [(url: String, ip:IPAddress)], cnames: [(url: String, cname: String)])? = data.withUnsafeBytes { rawBufferPointer in
            let rawPointer = rawBufferPointer.baseAddress!
            var arecords : [(url: String, ip:IPAddress)] = []
            var cnames : [(url: String, cname: String)] = []
            
            (0..<answerCount).forEach { _ in
                if let values = DNSResponse.grabAnswer(pointer: rawPointer, byteOffset: &offset)  {
                    if  let ip = values.ip {
                        arecords.append((url: values.url, ip: ip))
                    }
                    
                    if let cname = values.cname {
                        cnames.append((url: values.url, cname: cname))
                    }
                }
            }
                        
            return (arecords: arecords, cnames: cnames)
        }
        
        self.arecords = result?.arecords ?? []
        self.cnames = result?.cnames ?? []
        
        self.questionCount = questionCount
        self.answerCount = answerCount
    }
    
    private static func grabQuestions(pointer: UnsafeRawPointer, numberOfQuestions count: UInt16, byteOffset offset: inout Int) -> [String] {
        return (0..<count).map { _ in
            let url = DNSResponse.grabURL(pointer: pointer, byteOffset: &offset)
            offset += 4
            return url
        }
    }
    
    
    
    private static func grabURL(pointer: UnsafeRawPointer, byteOffset offset: inout Int) -> String {
        var size = pointer.load(fromByteOffset: offset, as: UInt8.self).bigEndian
        var array: [UInt8] = []
        
        while(size != 0x0) {
            offset = offset + 1
            (0..<size).forEach { _ in
                array.append(pointer.load(fromByteOffset: offset, as: UInt8.self))
                offset += 1
            }
            
            size = pointer.load(fromByteOffset: offset, as: UInt8.self).bigEndian
            array.append(UInt8.init(ascii: "."))
            
            if size == 0xC0 {
                //fatalError("Oh dear, I didn't believe we would see this")
                var jumpedOffset = UInt16(pointer.load(fromByteOffset: offset, as: UInt8.self)) << 8 | UInt16(pointer.load(fromByteOffset: offset + 1, as: UInt8.self))
                jumpedOffset = jumpedOffset & (0xFFFF - 0xC000)
                offset = Int(jumpedOffset)
                
                size = pointer.load(fromByteOffset: offset, as: UInt8.self).bigEndian
            }
        }
        
        array = array.dropLast()
        array.append(UInt8.init(0x0))
        
        offset += 1
        
        return String(cString: array)
    }
    
    private static func grabAnswer(pointer: UnsafeRawPointer, byteOffset offset: inout Int) -> (url: String, ip: IPAddress?, cname: String?)? {
        // We need to be 16bit aligned to use load, so if we grab two lots of 8bit then we'll always be correctly aligned.

        var answerOffset = UInt16(pointer.load(fromByteOffset: offset, as: UInt8.self)) << 8 | UInt16(pointer.load(fromByteOffset: offset + 1, as: UInt8.self))
        var compressed = false
        if answerOffset & 0xC000 == 0xC000 {
            answerOffset = answerOffset & (0xFFFF - 0xC000)
            compressed.toggle()
        }
                
        
        let qtype = UInt16(bigEndian: UInt16(pointer.load(fromByteOffset:offset + 2, as: UInt8.self)) << 8 | UInt16(pointer.load(fromByteOffset: offset + 3, as: UInt8.self))).bigEndian
        if qtype != 0x1 && qtype != 0x5 {
            // We have an invalid type
                return nil
        }
        
        // We've read 4 bytes and we've got 6 bytes which we aren't interested in.
        offset += 10
        
        let length = UInt16(bigEndian: UInt16(pointer.load(fromByteOffset:offset, as: UInt8.self)) << 8 | UInt16(pointer.load(fromByteOffset: offset + 1, as: UInt8.self))).bigEndian
        offset += 2
        
        switch(qtype) {
        case 0x1:
    
            guard length == 4 else {
                return nil
            }
    
            var updatedOffset = Int(answerOffset)
            let url = grabURL(pointer: pointer, byteOffset: &updatedOffset)
            
            let firstHalf = UInt16(pointer.load(fromByteOffset:offset, as: UInt8.self)) << 8 | UInt16(pointer.load(fromByteOffset: offset + 1, as: UInt8.self))
            let secondHalf = UInt16(pointer.load(fromByteOffset:offset + 2, as: UInt8.self)) << 8 | UInt16(pointer.load(fromByteOffset: offset + 3, as: UInt8.self))
            let ip = IPAddress(UInt32NetworkByteOrder: (UInt32(firstHalf) << 16 | UInt32(secondHalf)).bigEndian)

            offset += Int(length)
            return (url: url, ip: ip, cname: nil)
        
            // Need to return something!
        case 0x5:
            var updatedOffset = Int(answerOffset)
            var simpleOffset = Int(offset)
            
            let cname = grabURL(pointer: pointer, byteOffset: &updatedOffset)
            let url = grabURL(pointer: pointer, byteOffset: &simpleOffset)
            
            offset += Int(length)
            return (url: url, ip: nil, cname: cname)
        default:
            return nil
        }
    }
}
