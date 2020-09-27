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

    typealias Subscription = AnySubscriber

    enum SubscriptionState {
        case `continue`
        case terminate
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

        internal var subscribers: [SubscriptionId:AnySubscriber] = [:]

        // MARK: Publish With Message

        /// Publish an event to the bus.
        ///
        /// All subscribers to this event will have their handler called along with the associated message.
        /// - Parameters:
        ///   - event: Event to publish
        ///   - message: Message to send in event
        public func publish<Message: Causality.Message>(event: Causality.Event<Message>, message: Message) {

            self.publish(event: event, message: message, workQueue: .none)
        }


        // MARK: Publish With No Message

        /// Publish an event with no message
        /// - Parameter event: Event to publish
        public func publish(event: Causality.Event<Causality.NoMessage>) {
            let message = Causality.NoMessage.message
            self.publish(event: event, message: message, workQueue: .none)
        }

        // MARK: Subscribe w/ Subscription

        /// Add a subscriber to a specific event type
        /// - Parameters:
        ///   - event: The event type to subscribe to.
        ///   - handler: A handler that is called for each event of this type that occurs.  This handler will be called on the queue specified by the publisher (if given).  Otherwise there is no guarantee on what queue/thread the handler will be called on.
        @discardableResult
        public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, handler: @escaping (Subscription, Message)->Void) -> Subscription {

            return self.subscribe(event, workQueue: .none, handler: handler)
        }

        /// Add a subscriber to a specific event type
        /// - Parameters:
        ///   - event: The event type to subscribe to.
        ///   - queue: DispatchQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
        ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
        @discardableResult
        public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, queue: DispatchQueue?=nil, handler: @escaping (Subscription, Message)->Void) -> Subscription {
            let workQueue = WorkQueue(queue)
            return self.subscribe(event, workQueue: workQueue, handler: handler)
        }

        /// Add a subscriber to a specific event type
        /// - Parameters:
        ///   - event: The event type to subscribe to.
        ///   - queue: OperationQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
        ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
        @discardableResult
        public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, queue: OperationQueue, handler: @escaping (Subscription, Message)->Void) -> Subscription {

            return self.subscribe(event, workQueue: .operation(queue), handler: handler)
        }

        // MARK: Subscribe w/o Subscription

        /// Add a subscriber to a specific event type
        /// - Parameters:
        ///   - event: The event type to subscribe to.
        ///   - handler: A handler that is called for each event of this type that occurs.  This handler will be called on the queue specified by the publisher (if given).  Otherwise there is no guarantee on what queue/thread the handler will be called on.
        @discardableResult
        public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, handler: @escaping (Message)->Void) -> Subscription {

            return self.subscribe(event, workQueue: .none) { _, message in
                handler(message)
            }
        }

        /// Add a subscriber to a specific event type
        /// - Parameters:
        ///   - event: The event type to subscribe to.
        ///   - queue: DispatchQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
        ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
        @discardableResult
        public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, queue: DispatchQueue?=nil, handler: @escaping (Message)->Void) -> Subscription {
            let workQueue = WorkQueue(queue)
            return self.subscribe(event, workQueue: workQueue) { _, message in
                handler(message)
            }
        }

        /// Add a subscriber to a specific event type
        /// - Parameters:
        ///   - event: The event type to subscribe to.
        ///   - queue: OperationQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
        ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
        @discardableResult
        public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, queue: OperationQueue, handler: @escaping (Message)->Void) -> Subscription {

            return self.subscribe(event, workQueue: .operation(queue)) { _, message in
                handler(message)
            }
        }


        // MARK: Unsubscribe

        /// Stop a particular subscription handler from listening to events anymore.
        /// - Parameters:
        ///   - subsription: The Subscription that was returned from `subscribe()`
        public func unsubscribe(_ subscription: Subscription) {
            self.unsubscribe([subscription])
        }

        /// Unsubscribe an array of subscriptions
        /// - Parameter subscriptions: Subscriptions to unsubscribe from
        public func unsubscribe(_ subscriptions: [Subscription]) {
            self.queue.async {
                var newSubscribers = self.subscribers
                for subscription in subscriptions {
                    newSubscribers.removeValue(forKey: subscription.id)
                }
                self.subscribers = newSubscribers
            }
        }

        // MARK: - Private Methods

        /// Add a subscriber to a specific event type
        /// - Parameters:
        ///   - event: The event type to subscribe to.
        ///   - handler: A handler that is called for each event of this type that occurs
        private func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, workQueue: WorkQueue, handler: @escaping (Subscription, Message)->Void) -> Subscription {

            let subscriber = Subscriber(bus: self, event: event, handler: handler, workQueue: workQueue)
            self.queue.async {
                self.subscribers[subscriber.id] = subscriber
            }

            return subscriber
        }

        /// Publish an event to the bus.
        ///
        /// All subscribers to this event will have their handler called along with the associated message.
        /// - Parameters:
        ///   - event: Event to publish
        ///   - message: Message to send in event
        private func publish<Message: Causality.Message>(event: Causality.Event<Message>, message: Message, workQueue: WorkQueue) {

            self.queue.sync {
                let subscribers = self.subscribers
                for (_, someSubscriber) in subscribers {
                    guard let subscriber = someSubscriber as? Subscriber<Message> else {
                        continue
                    }
                    guard subscriber.state != .terminate else {
                        continue
                    }
                    var runQueue = subscriber.workQueue
                    if runQueue == .none {
                        runQueue = workQueue
                    }
                    runQueue.execute {
                        subscriber.handler(subscriber, message)
                    }
                }
            }
        }

    }
}
