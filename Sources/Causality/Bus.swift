//
//  Bus.swift
//
//
//  Created by Danny Sung on 09/20/2020.
//

import Foundation

public extension Causality {

    /// A default/global bus
    static let globalQueue = DispatchQueue(label: "Causality.global", qos: .default, attributes: [], autoreleaseFrequency: .inherit, target: .global(qos: .default))
    static let bus = Bus(name: "global", queue: globalQueue)

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

        /// Subscription identifier used by subscribers to be able to unsubscribe.
        /// Callers should make no assumptions about the underlying type of a `Subscription`.  (i.e. it may change to a struct, class, or protocol at some point)
        public typealias Subscription = UUID

        internal var subscribers: [Any] = []

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

        // MARK: Subscribe

        /// Add a subscriber to a specific event type
        /// - Parameters:
        ///   - event: The event type to subscribe to.
        ///   - handler: A handler that is called for each event of this type that occurs.  This handler will be called on the queue specified by the publisher (if given).  Otherwise there is no guarantee on what queue/thread the handler will be called on.
        @discardableResult
        public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, handler: @escaping (Message)->Void) -> Subscription {

            return self.subscribe(event, workQueue: .none, handler: handler)
        }

        /// Add a subscriber to a specific event type
        /// - Parameters:
        ///   - event: The event type to subscribe to.
        ///   - queue: DispatchQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
        ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
        @discardableResult
        public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, queue: DispatchQueue, handler: @escaping (Message)->Void) -> Subscription {

            return self.subscribe(event, workQueue: .dispatch(queue), handler: handler)
        }

        /// Add a subscriber to a specific event type
        /// - Parameters:
        ///   - event: The event type to subscribe to.
        ///   - queue: OperationQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
        ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
        @discardableResult
        public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, queue: OperationQueue, handler: @escaping (Message)->Void) -> Subscription {

            return self.subscribe(event, workQueue: .operation(queue), handler: handler)
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
                var newSubscribers: [Any] = []
                for subscriber in self.subscribers {
                    guard let subscriber = subscriber as? SubscriberId,
                          subscriptions.contains(subscriber.id)
                    else {
                        continue
                    }
                    newSubscribers.append(subscriber)
                }
                self.subscribers = newSubscribers
            }
        }

        // MARK: - Private Methods

        /// Add a subscriber to a specific event type
        /// - Parameters:
        ///   - event: The event type to subscribe to.
        ///   - handler: A handler that is called for each event of this type that occurs
        @discardableResult
        private func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, workQueue: WorkQueue, handler: @escaping (Message)->Void) -> Subscription {

            let subscriber = Subscriber(event: event, handler: handler, workQueue: workQueue)
            self.queue.async {
                self.subscribers.append(subscriber)
            }

            return subscriber.id
        }

        /// Publish an event to the bus.
        ///
        /// All subscribers to this event will have their handler called along with the associated message.
        /// - Parameters:
        ///   - event: Event to publish
        ///   - message: Message to send in event
        private func publish<Message: Causality.Message>(event: Causality.Event<Message>, message: Message, workQueue: WorkQueue) {

            // We have a choice of doing an async/each here instead, which might reduce the time of a publish() for the caller.  However, doing it this way results in slightly better timing between the publish() call and the subsequent subscription handler.  Since the handler will likely execute in another queue anyway, the preference here is to reduce the queue footprint.

            var subscribers: [Any] = []
            self.queue.sync {
                subscribers = self.subscribers
            }
            subscribers.each(event: event) { (subscriber) in
                var runQueue = subscriber.workQueue
                if runQueue == .none {
                    runQueue = workQueue
                }
                runQueue.execute {
                    subscriber.handler(message)
                }
            }
        }

    }
}


// MARK: - Array of Subscribers

fileprivate extension Array where Element == Any {

    /// Call every subscriber that matches the event
    /// - Parameters:
    ///   - event: An event description
    ///   - each: handler called for every subscriber that matches the event
    func each<Message: Causality.Message>(event: Causality.Event<Message>, _ each: (Subscriber<Message>)->Void) {

        for subscriber in self {
            guard let subscriber = subscriber as? Subscriber<Message>
            else {
                continue
            }
            each(subscriber)
        }
    }

}
