//
//  LocationResolver.swift
//  ZTN
//
//  Created by Alex Lisle on 5/6/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation
import Logging
import IP2Location

public class LocationResolver {
    private let logger = Logger(label: "com.zerotrust.client.Main")
    private let ipdb : IP2DBLocate?

    public init() {
        if let filepath = Bundle.main.url(forResource: "IP2LOCATION-LITE-DB11", withExtension: "BIN") {
            do {
                logger.info("loading IP2Location DB")
                self.ipdb = try IP2DBLocate(file: filepath)
            } catch  {
                logger.error("Unable to load IP2Location database")
                self.ipdb = nil
            }
        } else {
            self.ipdb = nil
        }
    }
    
    
    public func get(_ address: String) -> IP2LocationRecord? {
        return self.ipdb?.find(address)
    }
}
