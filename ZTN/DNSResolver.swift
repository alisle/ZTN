//
//  DNSResolver.swift
//  ZTN
//
//  Created by Alex Lisle on 4/28/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation

class DNSResolver {
    enum RecordType : Int {
        case ARecord = 0,
        CNameRecord = 1,
        QuestionAnsweredRecord = 2
    }

    
    struct Record : Hashable, CustomStringConvertible {
        let type: RecordType
        let url: String
        let ip : IPAddress
        
        init(type: RecordType, url: String, ip: IPAddress) {
            self.type = type
            self.url = url
            self.ip = ip
        }
        
        public var description: String {
            return String("Type:\(type) URL: \(url) IP: \(ip)")
        }
    }
    
    private var ARecord2IPs = [String: Set<IPAddress>]()
    private var ARecord2CNames = [String: Set<String>]()
    private var CName2ARecord = [String: String]()
    private var Bindings = [IPAddress: Record]()
    private let queue = DispatchQueue(label: "com.zerotrust.ZTN.DNSResolver")

    func update(_ response: DNSResponse) {
        response.questions.forEach {
            self.update(question: $0)
        }
        
        response.arecords.forEach {
            self.update(url: $0.url, ip: $0.ip)
        }
        
        response.cnames.forEach {
            self.update(url: $0.url, cName: $0.url)
        }
    }
    
    func update(question: String) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            if let ips = self.ARecord2IPs[question]  {
                // We have an ARecord which was a question.
                ips.forEach {
                    self.Bindings[$0] = Record(type:RecordType.QuestionAnsweredRecord, url:question, ip:$0)
                }
            }

            var record : String? = question
            var searching = true
            
            while searching {
                record = self.CName2ARecord[record!]
                if record != nil {
                    if self.ARecord2IPs[record!] != nil {
                        searching = false
                    }
                } else {
                    // we're done here.
                    searching = false
                }
            }
            
            if record != nil {
                if let ips = self.ARecord2IPs[record!] {
                    ips.forEach {
                        self.Bindings[$0] = Record(type:RecordType.QuestionAnsweredRecord, url: question, ip: $0)
                    }
                }
            }
        }
    }
    
    func update(url: String, ip: IPAddress) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            if let record = self.Bindings[ip] {
                if record.type == RecordType.ARecord {
                    // Replace it with the new one, else this is a CName, generally keep the CNames as they make more sense.
                    self.Bindings[ip] = Record(type: RecordType.ARecord, url: url, ip: ip)
                }
            } else {
                self.Bindings[ip] = Record(type: RecordType.ARecord, url: url, ip: ip)
            }
            
            var records = self.ARecord2IPs[url] ?? []
            records.insert(ip)
            
            self.ARecord2IPs.updateValue(records, forKey: url)
            
            if let cNames = self.ARecord2CNames[url] {
                // See if we have any CNames which point to this URL, if so update our IPs to reflect that.
                if let record = self.Bindings[ip] {
                    // We over-write an A Record
                    if record.type == RecordType.ARecord {
                        self.Bindings[ip] = Record(type: RecordType.CNameRecord, url: cNames.first!, ip: ip)
                    }
                }
            }

        }
    }
    
    
    func get(_ ip: IPAddress) -> String? {
        return queue.sync {
            self.Bindings[ip]?.url
        }
    }
    
    func update(url: String, cName: String) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            
            self.CName2ARecord[cName] = url
            
            var records : Set<String> = self.ARecord2CNames[url] ?? []
            records.insert(cName)
            self.ARecord2CNames.updateValue(records, forKey: url)
            
            // Update all IPs which pointed to that ARecord to point to the CName instead
            if let ips = self.ARecord2IPs[url] {
                ips.forEach {
                    if let record = self.Bindings[$0] {
                        // If the type is CName, we will keep it.
                        if record.type == RecordType.ARecord {
                            self.Bindings[$0] = Record(type: RecordType.CNameRecord, url: cName, ip: $0)
                        }
                    }
                }
            }
        }
    }
}
