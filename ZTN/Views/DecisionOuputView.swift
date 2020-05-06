//
//  DecisionOuputView.swift
//  ZTN
//
//  Created by Alex Lisle on 5/5/20.
//  Copyright © 2020 Alex Lisle. All rights reserved.
//

import SwiftUI

 struct FlowListView: View {
    let flows : [Flow]
    var body: some View {
        List() {
            ForEach(flows) { flow  in
                HStack {
                    Text("\(flow.description)")
                        .font(.system(size: 10, design: .monospaced))
                    Spacer()
                }.listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }.listStyle(PlainListStyle())
    }
}

struct DecisionsListView: View {
    @EnvironmentObject var state : DecisionsViewState
    
    var body: some View {
        return VStack(alignment: .leading, spacing: 1.4) {
            Text("Made Decisions")
                .padding(.init(top: 1, leading: 5, bottom: 1, trailing: 1))
            FlowListView(flows: state.madeDecisions)
        }
    }
}

struct DeferredDecisionsListView: View {
    @EnvironmentObject var state : DecisionsViewState
    
    var body: some View {
        return VStack(alignment: .leading, spacing: 1.4) {
            Text("Pending Decisions")
                .padding(.init(top: 1, leading: 5, bottom: 1, trailing: 1))
            
            FlowListView(flows: state.deferredDecisions)
        }
    }
}

struct CombinedDecisionsListView: View {
    @EnvironmentObject var state : DecisionsViewState
    
    var body: some View {
        HStack {
            DecisionsListView()
            DeferredDecisionsListView()
        }
    }
}

struct DecisionOuputView_Previews: PreviewProvider {
    static var previews: some View {
        let flows = Flows()
        let state = DecisionsViewState(flows: flows)
        (0..<10).forEach { _ in
            let allowed = NewAllowedFlowEvent(flow: generateDebugFlow(decision: .allowed, direction: .inbound))
            
            let deferred = NewDeferredFlowEvent(flow: generateDebugFlow(decision: .deferred, direction: .inbound))
            
            flows.eventTriggered(event: allowed)
            flows.eventTriggered(event: deferred)
        }
        
        return VStack {
               CombinedDecisionsListView()
        }.environmentObject(state)
    }
}
