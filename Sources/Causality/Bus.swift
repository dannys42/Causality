//
//  Bus.swift
//
//
//  Created by Danny Sung on 09/20/2020.
//

import Foundation

public extension Causality {

    /// The queue used by the default bus for thread-safety.  Also the default queue used for all buses (unless specified on initialization).
    static let globalQueue = DispatchQueue(label: "Causality.global", qos: .default, attributes: [], autoreleaseFrequency: .inherit, target: .global(qos: .default))
    /// A default/global bus
    static let bus = Bus(name: "global", queue: globalQueue)

    /// Subscriptions can be in the following states:
    enum SubscriptionState {
        /// handler will be called when appropriate
        case active

        /// handler will no longer be called.  The subscription will be removed at the next opportunity.
        case unsubscribePending
    }

    /// Subscription identifier used by subscribers to be able to unsubscribe.
    /// Callers should make no assumptions about the underlying type of a `Subscription`.  (i.e. it may change to a struct, class, or protocol at some point)
    typealias SubscriptionId = UUID


    /// A Bus for events to go from publishers to subscribers
    class Bus {
        /// A name for the bus.
        public private(set) var name: String

        /// Queue on which to execute publish/subscribe actions to ensure thread safety
        public private(set) var queue: DispatchQueue

        /// Initialize a Causality Event Bus
        /// - Parameter name: name to give the bus
        /// - Parameter queue: Queue for bookkeeping (e.g. to ensure publish/subscribe is thread safe)
        public init(name: String, queue: DispatchQueue = globalQueue) {
            self.name = name
            self.queue = queue
        }

        // MARK: Event

        internal var eventSubscribers: [SubscriptionId:CausalityEventSubscription] = [:]

        // MARK: State

        internal var stateSubscribers: [SubscriptionId:CausalityStateSubscription] = [:]
        internal var state: [AnyState:Causality.AnyStateValue] = [:]

    }
}
