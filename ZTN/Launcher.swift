//
//  Launcher.swift
//  ZTN
//
//  Created by Alex Lisle on 4/28/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation
import os.log

class Launcher : NSObject {
    // View State
    let decisionsViewState :  DecisionsViewState
    
    let flowFactory : FlowFactory
    let extensionLauncher = ExtensionLauncher()
    let dnsResolver = DNSResolver()
    let processResolver = ProcessResolver()
    let serviceResolver = ServiceResolver()
    let locationResolver = LocationResolver()
    let decisionEngine = DecisionEngine()
    let flows = Flows()

    
    override init() {
        self.flowFactory = FlowFactory(
            dnsResolver: self.dnsResolver,
            processResolver: self.processResolver,
            serviceResolver: self.serviceResolver,
            locationResolver: self.locationResolver
        )
        
        self.decisionsViewState = DecisionsViewState(flows: self.flows)
        super.init()
    }
    
    func launch() {                
        extensionLauncher.load(delegate: self)
        extensionLauncher.startFilter()
        
    }
    
    func terminate() {
        extensionLauncher.stopFilter()
        extensionLauncher.terminate()
    }
    
    
}

extension Launcher : AppCommunication {
    func flow(aboutFlow flowInfo: [String: String], responseHandler:@escaping (Bool) -> Void) {
        if let flow = self.flowFactory.generate(flow: flowInfo) {
            decisionEngine.add(flow: flow, handler: responseHandler)
        } else {
            // MARK: This is really bad, need to change this.
            responseHandler(true)
        }
    }
    
    func dnsPacket(aboutFlow flowInfo: [String : String]) {
        if let response = DNSResponse(flowDescription: flowInfo) {
            self.dnsResolver.update(response)
        }                
    }
    
    func flowReport(aboutFlow flowInfo: [String : String]) {
        guard
            let id = flowInfo[FlowReportKey.id.rawValue],
            let bytesIn = flowInfo[FlowReportKey.bytesInboundCount.rawValue],
            let bytesOut = flowInfo[FlowReportKey.bytesOutboundCount.rawValue],
            let eventType = flowInfo[FlowReportKey.eventType.rawValue]
        else {
            return
        }

        if let id = UUID(uuidString: id),
           let bytesIn = Int(bytesIn),
           let bytesOut = Int(bytesOut),
           let eventType = Int(eventType) {
            
            EventManager.shared.triggerEvent(event: UpdatedFlowEvent(id: id, bytesIn: bytesIn, bytesOut: bytesOut))
            if(eventType == 3) {
                EventManager.shared.triggerEvent(event: ClosedFlowEvent(id: id))
            }
        }
        
    }
    
}


#if DEBUG

func generateDebugLocalSocketAddress() -> SocketAddress {
    let localPort = Int.random(in: 1025..<40000)

    return SocketAddress(
        hostname: nil,
        address: IPAddress("127.0.0.1"),
        port: localPort
    )
}

func generateDebugRemoteSocketaddress() -> SocketAddress {
    let remotePort = [ 80, 443, 22, 21, 8100].randomElement()
    let addresses = [ "41.111.221.137", "159.133.25.245", "5.52.20.109", "47.134.92.77",
                      "135.103.201.30", "68.201.84.111", "98.181.189.80", "1.124.8.150",
                      "94.62.192.225", "196.142.11.103", "116.107.170.84", "161.128.90.145",
                      "203.57.95.112", "117.57.83.46", "77.168.59.226", "100.196.38.176",
                      "66.0.184.214","11.4.123.219","240.138.102.221","242.104.216.219",
                      "23.161.174.226","200.223.1.75","145.70.40.208", "68.12.228.61",
                      "207.209.151.29", "200.144.11.208", "18.164.155.37","145.56.162.174",
                      "228.1.63.60","108.74.5.158","10.244.231.189","134.174.113.246",
                      "81.6.53.101","100.121.164.1","62.152.60.228","90.58.71.198",
                      "194.49.167.180","212.52.33.216","151.249.236.242","207.184.191.10",
                      "235.222.89.219","245.137.231.1","180.25.238.8","239.120.152.64",
                      "193.79.237.81","119.119.39.230","196.141.241.244","248.51.35.58",
                      "1.214.136.144","43.13.177.223","231.3.201.82","76.213.40.23",
                      "218.79.58.81","142.201.119.62","236.187.9.146","139.19.156.42",
                      "102.61.154.68","109.228.67.123","90.218.24.100","58.77.236.135",
                      "135.112.88.80","134.112.26.147","213.242.60.25","64.41.99.212"]
    
    let hostnames = [ "google.com", "youtube.com", "tmall.com", "baidu.com", "qq.com",
                      "sohu.com", "facebook.com", "taobao.com","login.tmall.com","yahoo.com",
                      "wikipedia.org","amazon.com","360.cn","jd.com","sina.com.cn","live.com",
                      "reddit.com","weibo.com","pages.tmall.com","vk.com","netflix.com", "blogspot.com",
                      "alipay.com", "csdn.net","okezone.com","yahoo.co.jp","office.com","bing.com",
                      "instagram.com","microsoft.com","google.com.hk","xinhuanet.com","ebay.com",
                      "babytree.com","naver.com","stackoverflow.com","google.co.in","twitter.com",
                      "msn.com","aliexpress.com","yandex.ru","force.com","tribunnews.com","amazon.co.jp",
                      "twitch.tv","soso.com","apple.com","microsoftonline.com","dropbox.com","tianya.cn",
                      "linkedin.com","mail.ru","bongacams.com","wordpress.com","imdb.com","booking.com",
                      "adobe.com","google.com.br","zhanqi.tv","hao123.com","amazon.in","panda.tv",
                      "google.co.jp","caijing.com.cn","google.de","so.com","china.com.cn","myshopify.com",
                      "imgur.com","amazonaws.com","ok.ru","chase.com","trello.com","gmw.cn","detail.tmall.com",
                      "tumblr.com","fandom.com","medium.com","bbc.com","mama.cn","indeed.com","youth.cn",
                      "amazon.co.uk","w3schools.com","google.ru","spotify.com","pixnet.net","soundcloud.com",
                      "rednet.cn","cnn.com","blogger.com","whatsapp.com","aparat.com","amazon.de","nytimes.com",
                      "detik.com"]
    
    return SocketAddress(
        hostname: hostnames.randomElement()!,
        address: IPAddress(addresses.randomElement()!),
        port: remotePort!)
}

func generateDebugBundleDetails() -> BundleDetails {
    let bundle = BundleDetails(
        signedIdentifier: "apple.com",
        id: "apple.com",
        version: "8.8.1.2",
        name: "Know Idea",
        displayName: "/usr/bin/sh",
        executable: "/usr/bin/sh",
        iconFile: nil
    )
    
    return bundle
}

func generateDebugProcessInfo(_ generateParents : Bool = true, _ generatePeers : Bool = true) -> ProcessDetails {
    let process = ["Chrome.app", "/usr/bin/ssh", "WhatsApp.app"].randomElement()
    
    let parent : ProcessDetails? = (generateParents) ? generateDebugProcessInfo(false, false) : nil
    let peers : [ProcessDetails] = (generatePeers) ? (0..<10).map{ _ in generateDebugProcessInfo(false, false) } : []

    let details = ProcessDetails(
        pid: Int.random(in: 1000...4000),
        ppid: Int.random(in: 100...999),
        uid: 1000,
        username: "alisle",
        path: process!,
        parent: parent,
        bundle: generateDebugBundleDetails(),
        sha256: "012012",
        md5: "1231",
        peers: peers
    )
    
    return details
}

func generateDebugPortService() -> PortServiceDetails {
    return PortServiceDetails(
        name: "HTTP",
        port: 80,
        description: "The Hypertext Transfer Protocol (HTTP) is an application protocol for distributed, collaborative, hypermedia information systems. HTTP is the foundation of data communication for the World Wide Web, where hypertext documents include hyperlinks to other resources that the user can easily access, for example by a mouse click or by tapping the screen in a web browser.",
        url: "https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol"
    )
}

func generateDebugFlow(decision: FlowDecision = .allowed, direction: FlowDirection = .outbound) -> Flow {
    let flow = Flow(
        id: UUID(),
        state: .open,
        decision: decision,
        bytesIn: 0,
        bytesOut: 0,
        local: generateDebugLocalSocketAddress(),
        remote: generateDebugRemoteSocketaddress(),
        location: nil,
        direction: direction,
        process: generateDebugProcessInfo(),
        proto: .TCP,
        service: generateDebugPortService(),
        timestamp: Date(),
        endTimestamp: nil
    )
    
    return flow
}

#endif
