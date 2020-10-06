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
    static let bus = Bus(label: "global", queue: globalQueue)

    /// Subscriptions can have the following statuses:
    enum SubscriptionStatus {
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
        public private(set) var label: String

        /// Queue on which to execute publish/subscribe actions to ensure thread safety
        public private(set) var queue: DispatchQueue

        /// Initialize a Causality Event Bus
        /// - Parameter label: name to give the bus
        /// - Parameter queue: Queue for bookkeeping (e.g. to ensure publish/subscribe is thread safe)
        public init(label: String, queue: DispatchQueue = globalQueue) {
            self.label = label
            self.queue = queue
        }

        // MARK: Event

        internal var eventSubscribers: [SubscriptionId:CausalityAnyEventSubscription] = [:]

        // MARK: State

        internal var stateSubscribers: [SubscriptionId:CausalityAnyStateSubscription] = [:]
        internal var state: [Causality.AnyHashableState:Causality.AnyStateValue] = [:]

    }
}
