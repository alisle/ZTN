//
//  GlobeShape.swift
//  ZeroTrust FW
//
//  Created by Alex Lisle on 11/11/19.
//  Copyright © 2019 Alex Lisle. All rights reserved.
//

import SwiftUI
import IP2Location
import Topojson

struct MapGraph: View {
    let points : [MapPoint]
    
    var body: some View {
        ZStack {
            MapShape()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(
                            colors: [
                                .red,
                                .yellow,
                                .green,
                                .blue,
                                .purple,
                                .red
                        ]),
                        center: .center
                    )
            ).drawingGroup()
            
            ForEach(points) { point in
                CoordShape(point: point, count: point.count)
                .fill(
                    AngularGradient(
                        gradient: Gradient(
                            colors: [
                                .purple,
                                .white,
                                .green,
                        ]),
                        center: .top
                    )
                )
                .opacity(0.6)
                
                CoordShape(point: point, count: point.count)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(
                            colors: [
                                .white,
                                .yellow,
                        ]),
                        center: .center
                    ),
                    lineWidth: 1
                )
                .opacity(0.6)
            }.animation(.easeInOut(duration: 0.5))

        }.aspectRatio(2.0, contentMode: .fit)
    }
}

struct CoordShape : Shape {
    let map : Map = Map.shared
    let point: MapPoint
    var count : CGFloat
    
    var animatableData : CGFloat {
         get {
            return self.count
         }
         set {
            self.count = newValue
         }
     }

    func path(in rect: CGRect) -> Path {
        let size = (((rect.size.height > rect.size.width) ? rect.size.height : rect.size.width) / 100) * (1.5 * CGFloat(self.count))
        let absolutePoint = map.scale(point: point, rect: rect)
        let pointRect = CGRect(
            origin: .init(x: absolutePoint.x - (size / 2), y: (absolutePoint.y  - size / 2)),
            size: .init(width: size, height: size)
        )
        
        var path = Path()
        path.addEllipse(in: pointRect)
        return path
    }
}

struct MapShape : Shape {
    let map : Map = Map.shared
    
    func path(in rect: CGRect) -> Path {
        var world = Path()
        
        map.paths(rect: rect).forEach {
            world.addPath($0)
        }
        
        
        return world
    }
}

struct GlobeGraph_Previews: PreviewProvider {
    static var previews: some View {
        let view = MapGraph(
            points: [
                Map.shared.createPoint(latitude: 51.509865, longitude: -0.118092),
                Map.shared.createPoint(latitude: 38.89511, longitude: -77.03637),
                Map.shared.createPoint(latitude: -35.282001, longitude: 149.128998)
            ]
        )
        .frame(width: 400, height: 240, alignment: .center)
        
        
        return view
    }
}
