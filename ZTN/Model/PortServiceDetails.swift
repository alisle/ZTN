//
//  PortServiceDetails.swift
//  ZTN
//
//  Created by Alex Lisle on 4/27/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import Foundation

public struct PortServiceDetails : Codable {
    var name: String
    var port : Int
    var description : String
    var url: String
}
