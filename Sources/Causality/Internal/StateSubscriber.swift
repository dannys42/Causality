//
//  StateSubscriber.swift
//  
//
//  Created by Danny Sung on 09/28/2020.
//

import Foundation

public protocol AnyStateSubscriber: AnySubscriber {

}

internal class StateSubscriber<State: Causality.StateValue>: AnyStateSubscriber {
    typealias SubscriptionHandler = (AnyStateSubscriber, State)->Void

    let id: Causality.SubscriptionId
    let bus: Causality.Bus
    let event: Causality.State<State>
    let handler: SubscriptionHandler
    let workQueue: WorkQueue
    var state: Causality.SubscriptionState

    init(bus: Causality.Bus, event: Causality.State<State>, handler: @escaping SubscriptionHandler, workQueue: WorkQueue) {
        self.id = UUID()
        self.bus = bus
        self.event = event
        self.handler = handler
        self.workQueue = workQueue
        self.state = .continue
    }

    public func unsubscribe() {
        self.bus.unsubscribe(self)
    }
}
