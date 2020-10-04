//
//  EventSubscriber.swift
//  
//
//  Created by Danny Sung on 09/20/2020.
//

import Foundation

/// An event subscription.  Used to unsubscribe.
public protocol CausalityAnyEventSubscription: CausalityAnySubscription {

}

extension Causality {

    /// Subscription handler for Events.
    /// Used to `unsubscribe()` or determine the `bus` or `state` that triggered an update.
    public class EventSubscription<Event: Causality.AnyEvent<Message>, Message: Causality.Message>: CausalityAnyEventSubscription {
        typealias SubscriptionHandler = (EventSubscription<Event,Message>, Message)->Void

        public let id: Causality.SubscriptionId
        public let bus: Causality.Bus
        public let event: Causality.AnyEvent<Message>
        internal let handler: SubscriptionHandler
        internal let workQueue: WorkQueue
        public var status: Causality.SubscriptionStatus

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

}
