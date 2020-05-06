//
//  GeoMap.swift
//  ZeroTrust FW
//
//  Created by Alex Lisle on 10/23/19.
//  Copyright © 2019 Alex Lisle. All rights reserved.
//

import Foundation
import Topojson
import SwiftUI
import Logging

struct MapPoint {
    let latitude : Double
    let longitude : Double
    let translated : CGPoint
    let count : CGFloat
}

extension MapPoint : Identifiable {
    var id : Int {
        get {
            return self.hashValue
        }
    }
}


extension MapPoint : Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
                
    }
}

struct Map {
    static public let shared = Map()!

    private let logger = Logger(label: "com.zerotrustnetworks.ZTN.Models.MapCoordinates")
    private let size : CGSize

    let topo : Topojson

    init?() {
        //if let filepath = Bundle.main.url(forResource: "countries", withExtension: "topojson") {
        if let filepath = Bundle.main.url(forResource: "land-110m", withExtension: "json") {
            do {
                logger.info("loading TopoJson file")
                self.topo = try Topojson(filepath)
            } catch  {
                logger.error("unable to load TopoJson file")
                return nil
            }
        } else {
            logger.error("unable to find countries topojson file")
            return nil
        }
        
        var min : (Int, Int) = (Int.max, Int.max)
        var max : (Int, Int) = (Int.min, Int.min)
        
        self.topo.arcs.forEach {
            $0.forEach {
                let x = $0.0
                let y = $0.1
                
                if x < min.0 {
                    min.0 = x
                }
                
                if x > max.0 {
                    max.0 = x
                }
                
                if y < min.1 {
                    min.1 = y
                }
                
                if y > max.1 {
                    max.1 = y
                }
            }
        }
        
        self.size = CGSize(width: max.0 - min.0, height: max.1 - min.1)
    }
    
    func coords() -> [[CGPoint]] {
        self.topo.arcs.map{ $0.map { CGPoint(x: $0.0, y: $0.1) } }
    }
    
    func createPoint(latitude: Double, longitude: Double) -> MapPoint {
        var x = longitude
        var y = latitude
        
        if let translate = self.topo.translate {
            x -= translate.0
            y -= translate.1
        }
        
        if let scale = self.topo.scale {
            x /= scale.0
            y /= scale.1
        }
        
        return MapPoint(
            latitude: latitude,
            longitude: longitude,
            translated: .init(x: x, y: y),
            count: 1.0
        )
    }
    
    func scale(point: CGPoint, rect: CGRect) -> CGPoint {
        let xScale = rect.size.width / self.size.width
        let yScale = rect.size.height / self.size.height
        
        return CGPoint(
            x: point.x * xScale,
            y: rect.size.height - (point.y * yScale)
        )

    }
    
    func scale(point: MapPoint, rect: CGRect) -> CGPoint {
        return scale(point: point.translated, rect: rect)
    }
    
    
    func paths(rect : CGRect) -> [Path] {
        let xScale = rect.size.width / self.size.width
        let yScale = rect.size.height / self.size.height
        
        return self.coords().map {
            var path = Path()
            path.move(to: $0[0])
            path.addLines($0.map{ CGPoint(x: $0.x * xScale, y: rect.size.height - ($0.y * yScale))})
            return path
        }
    }
}

