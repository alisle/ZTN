//
//  ContentView.swift
//  ZTN
//
//  Created by Alex Lisle on 4/22/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        VStack {
            CombinedDecisionsListView()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        let flows = Flows()
        let state = DecisionsViewState(flows: flows)
        (0..<10).forEach { _ in
            let allowed = NewAllowedFlowEvent(flow: generateDebugFlow(decision: .allowed, direction: .inbound))
            
            let deferred = NewDeferredFlowEvent(flow: generateDebugFlow(decision: .deferred, direction: .inbound))
            
            flows.eventTriggered(event: allowed)
            flows.eventTriggered(event: deferred)
        }
        
        return ContentView().environmentObject(state)

    }
}
