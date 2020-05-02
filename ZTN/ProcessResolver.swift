//
//  ProcessResolver.swift
//  ZTN
//
//  Created by Alex Lisle on 4/30/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation
import os.log
import AppKit
import CommonCrypto

class ProcessResolver {

    
    func get(token : String) -> ProcessDetails?{
        let data = Data.init(base64Encoded: token)!

        return self.get(token: data)
    }
    
    func get(pid: pid_t,
             generatePeers : Bool = true,
             generateParent : Bool = true
    ) -> ProcessDetails? {
        guard let proc = self.getKinfo(pid: pid),
              let secCode = self.extractStaticCode(pid) else {
            return nil
        }
        
    
        let ppid = proc.kp_eproc.e_ppid
        let uid = Int(proc.kp_eproc.e_ucred.cr_uid)
        let username = getUsername(uid: proc.kp_eproc.e_ucred.cr_uid)
        let bundle = extractBundleDetails(secCode)
        let path = extractPath(secCode)
        let parent = (ppid != 0 && generateParent) ? self.get(pid: ppid, generatePeers: false) :  nil
        let sha256 = generateSHA256(path: bundle?.executable ?? path)
        let md5 = generateMD5(path: bundle?.executable ?? path)
        let peers = generatePeers ? self.listChildren(pid: ppid).compactMap{ get(pid: $0, generatePeers: false, generateParent: false) } : []
        
        return ProcessDetails(
            pid: Int(pid),
            ppid: Int(ppid),
            uid: uid,
            username: username,
            path: path!,
            parent: parent,
            bundle: bundle,
            sha256: sha256,
            md5: md5,
            peers: peers)
    }
    
    func get(token : Data) -> ProcessDetails? {
        let auditToken = extractAuditToken(data: token)
        let pid = audit_token_to_pid(auditToken)
        
        return get(pid: pid)
    }
    
    private func getKinfo(pid: pid_t) -> kinfo_proc? {
        var kinfo = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib = [ CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        
        guard sysctl(&mib, 4, &kinfo, &size, nil, 0) == 0 else {
            return nil
        }

        return kinfo
    }
    
    private func getUsername(uid: uid_t) -> String? {
        guard let userinfo = getpwuid(UInt32(uid)) else {
            return Optional.none
        }
        
        return String(cString: userinfo.pointee.pw_name)
    }
    
    private func extractAuditToken(data: Data) -> audit_token_t {
        var token = Array<UInt32>(repeating: 0, count: data.count/MemoryLayout<UInt32>.stride)
        _ = token.withUnsafeMutableBytes { data.copyBytes(to: $0) }
        let auditToken = audit_token_t(val: (token[0], token[1], token[2], token[3], token[4], token[5], token[6], token[7]))
        return auditToken
    }
    
    private func extractStaticCode(_ pid: pid_t) -> SecStaticCode? {
        var codeQ: SecCode? = nil
        var err = SecCodeCopyGuestWithAttributes(nil, [
            kSecGuestAttributePid: pid
        ] as NSDictionary, [], &codeQ)
        guard err == errSecSuccess else {
            return nil
        }
        
        let code = codeQ!
        
        var staticCodeQ: SecStaticCode? = nil
        err = SecCodeCopyStaticCode(code, [], &staticCodeQ)
        guard err == errSecSuccess else {
            return nil
        }
        let staticCode = staticCodeQ!
        
        return staticCode

    }
    
    private func extractStaticCode(_ data: Data) -> SecStaticCode? {
        var codeQ: SecCode? = nil
        var err = SecCodeCopyGuestWithAttributes(nil, [
            kSecGuestAttributeAudit: data
        ] as NSDictionary, [], &codeQ)
        guard err == errSecSuccess else {
            return nil
        }
        
        let code = codeQ!
        
        var staticCodeQ: SecStaticCode? = nil
        err = SecCodeCopyStaticCode(code, [], &staticCodeQ)
        guard err == errSecSuccess else {
            return nil
        }
        let staticCode = staticCodeQ!
        
        return staticCode
    }
    
    private func extractPath(_ staticCode: SecStaticCode) -> String? {
        var url : CFURL? = nil
        guard SecCodeCopyPath(staticCode, [], &url) == errSecSuccess else {
            return nil
        }
                        
        return String(cString: (url! as NSURL).fileSystemRepresentation)
    }
    
    private func extractBundleDetails(_ staticCode : SecStaticCode) -> BundleDetails? {
        var infoQ: CFDictionary? = nil
        guard SecCodeCopySigningInformation(staticCode, [], &infoQ) == errSecSuccess else {
            return nil
        }
        
        
        let info = infoQ! as! [String:Any]
        
        guard
            let plist = info[kSecCodeInfoPList as String] as? [String:Any]
        else {
            return nil
        }
        
        let url = info[kSecCodeInfoMainExecutable as String] as? NSURL
        let identifier = info[kSecCodeInfoIdentifier as String] as? String
        let bundleID = plist[kCFBundleIdentifierKey as String] as? String
        let bundleVersion = plist[kCFBundleVersionKey as String] as? String
        let bundleName = plist[kCFBundleNameKey as String] as? String
        let bundleDisplayName = plist["CFBundleDisplayName"] as? String
        let bundleIconFilename =  plist["CFBundleIconFile"] as? String
        let executable = (url != nil) ? String(cString: url!.fileSystemRepresentation) : nil
        let iconFile = extractIconFile(executable: executable, iconFilePath: bundleIconFilename)
        

        return BundleDetails(
            signedIdentifier: identifier,
            id: bundleID,
            version: bundleVersion,
            name: bundleName,
            displayName: bundleDisplayName,
            executable : executable,
            iconFile: iconFile
        )
    }
    
    private func extractIconFile(executable: String?, iconFilePath: String?) -> NSImage? {
        guard
            var path = executable,
            let iconFilePath = iconFilePath else {
                return nil
        }
        
        guard let range = path.range(of: ".app", options: .backwards) else {
            return nil
        }
        
        path = String(path[..<range.upperBound])
        
        var bundle = Bundle(path: path)
        while !path.isEqual("/") && !path.isEqual("") && bundle == nil {
            let index = path.lastIndex(of: "/") ?? path.startIndex
            let substring = path[..<index]
            path = String(substring)
            bundle = Bundle(path: path)
        }
        
        if let bundle = bundle {
            var iconType = "icns"
            var iconFile = iconFilePath
            
            if let index = iconFile.lastIndex(of: (".")) {
                iconFile = String(iconFilePath[...index].dropLast())
                iconType = String(iconFilePath[index...].dropFirst())
            }
            guard let iconPath = bundle.path(forResource: iconFile, ofType: iconType) else {
                return Optional.none
            }
            
            return NSImage(byReferencingFile: iconPath)
        }
        
        return nil

    }
    
    public func generateSHA256(path: String?) -> String? {
        guard let path = path else {
            return nil
        }
        
        let bufferSize = 1024 * 1024
        guard let file = FileHandle(forReadingAtPath: path) else {
            return nil
        }
        defer {
            file.closeFile()
        }

        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)

        while autoreleasepool(invoking: {
            let data = file.readData(ofLength: bufferSize)
            if data.count > 0 {
                data.withUnsafeBytes {
                    _ = CC_SHA256_Update(&context, $0, numericCast(data.count))
                }
                return true
            } else {
                return false
            }
        }) { }

        var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        digest.withUnsafeMutableBytes {
            _ = CC_SHA256_Final($0, &context)
        }
                
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    public func generateMD5(path: String?) -> String? {

        guard let path = path else {
            return nil
        }

        let bufferSize = 1024 * 1024
        guard let file = FileHandle(forReadingAtPath: path) else {
            return nil
        }
        defer {
            file.closeFile()
        }

        var context = CC_MD5_CTX()
        CC_MD5_Init(&context)
        
        while autoreleasepool(invoking: {
            let data = file.readData(ofLength: bufferSize)
            if data.count > 0 {
                data.withUnsafeBytes {
                    _ = CC_MD5_Update(&context, $0, numericCast(data.count))
                }
                return true
            } else {
                return false
            }
        }) { }

        var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        digest.withUnsafeMutableBytes {
            _ = CC_MD5_Final($0, &context)
        }
            
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    public func listChildren(pid: Int32) -> [Int32] {
        do {
            let task = Process()
            let pipe = Pipe()
            
            task.executableURL = URL(fileURLWithPath: "/bin/sh")
            task.arguments = ["-c", "pgrep -P \(pid)"]
            task.standardOutput = pipe
            
            try task.run()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: String.Encoding.utf8) {
                let ppids = output.split(separator: "\n").map{ Int($0) }.filter{ $0 != nil }.map{ Int32($0!) }
                task.waitUntilExit()
                return ppids
            }
            
            task.waitUntilExit()

        } catch {
            return []
        }
        
        return []
    }


}
