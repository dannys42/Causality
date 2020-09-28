//
//  StateSubscriber.swift
//  
//
//  Created by Danny Sung on 09/28/2020.
//

import Foundation

/// A state change subscription.  Used to unsubscribe.
public protocol CausalityStateSubscription: CausalityAnySubscription {

}

internal class StateSubscriber<State: Causality.StateValue>: CausalityStateSubscription {
    typealias SubscriptionHandler = (CausalityStateSubscription, State)->Void

    let id: Causality.SubscriptionId
    let bus: Causality.Bus
    let state: Causality.State<State>
    let handler: SubscriptionHandler
    let workQueue: WorkQueue
    var subscriptionState: Causality.SubscriptionState

    init(bus: Causality.Bus, state: Causality.State<State>, handler: @escaping SubscriptionHandler, workQueue: WorkQueue) {
        self.id = UUID()
        self.bus = bus
        self.state = state
        self.handler = handler
        self.workQueue = workQueue
        self.subscriptionState = .active
    }

    public func unsubscribe() {
        self.bus.unsubscribe(self)
    }
}
