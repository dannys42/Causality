//
//  EventSubscriber.swift
//  
//
//  Created by Danny Sung on 09/20/2020.
//

import Foundation

/// An event subscription.  Used to unsubscribe.
public protocol CausalityEventSubscription: CausalityAnySubscription {

}

internal class EventSubscriber<Message: Causality.Message>: CausalityEventSubscription {
    typealias SubscriptionHandler = (CausalityEventSubscription, Message)->Void

    let id: Causality.SubscriptionId
    let bus: Causality.Bus
    let event: Causality.AnyEvent<Message>
    let handler: SubscriptionHandler
    let workQueue: WorkQueue
    var status: Causality.SubscriptionStatus

    init(bus: Causality.Bus, event: Causality.AnyEvent<Message>, handler: @escaping SubscriptionHandler, workQueue: WorkQueue) {
        self.id = UUID()
        self.bus = bus
        self.event = event
        self.handler = handler
        self.workQueue = workQueue
        self.status = .active
    }

    public func unsubscribe() {
        self.bus.unsubscribe(self)
    }
}

