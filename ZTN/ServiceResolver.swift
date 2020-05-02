//
//  ServicetResolver.swift
//  ZTN
//
//  Created by Alex Lisle on 5/1/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation

class ServiceResolver {
    private let Port2Protocol : [Int: PortServiceDetails]
    
    init() {
        let protocols : [PortServiceDetails] = Bundle.loadJSON("protocols.json")
        var map = [Int: PortServiceDetails]()
        protocols.forEach {
            map[$0.port] = $0
        }
        
        Port2Protocol = map
    }
    
    
    func get(_ port : Int) -> PortServiceDetails? {
        return Port2Protocol[port]
    }
    
    func get(_ socket : SocketAddress) -> PortServiceDetails? {
        return self.get(socket.port)
    }
    
}
