//
//  StateSubscriber.swift
//  
//
//  Created by Danny Sung on 09/28/2020.
//

import Foundation

/// A state change subscription.  Used to unsubscribe.
public protocol CausalityAnyStateSubscription: CausalityAnySubscription {

}

public extension Causality {
    /// Subscription handler for States.
    /// Used to `unsubscribe()` or determine the `bus` or `state` that triggered an update.
    class StateSubscription<State: Causality.AnyState<Value>, Value: Causality.StateValue>: CausalityAnyStateSubscription {
        typealias SubscriptionHandler = (Causality.StateSubscription<State,Value>, Value)->Void

        /// A unique identifier for the subscription
        public let id: Causality.SubscriptionId
        /// The bus that the subscription is listening on
        public let bus: Causality.Bus
        /// The state that was subscribed to
        public let state: State
        /// The running status of the subscription
        public var status: Causality.SubscriptionStatus

        internal let handler: SubscriptionHandler
        internal let workQueue: WorkQueue

        internal init(bus: Causality.Bus, state: State, handler: @escaping SubscriptionHandler, workQueue: WorkQueue) {
            self.id = UUID()
            self.bus = bus
            self.state = state
            self.handler = handler
            self.workQueue = workQueue
            self.status = .active
        }

        public func unsubscribe() {
            self.bus.unsubscribe(self)
        }
    }
}
