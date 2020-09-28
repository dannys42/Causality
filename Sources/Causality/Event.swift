//
//  Event.swift
//  
//
//  Created by Danny Sung on 09/20/2020.
//

import Foundation

public extension Causality {
    /// Declare events to be used as endpoints for publish or subscribe calls.
    ///
    /// Example:
    /// ```
    /// static let SomeEvent = Causality.Event<Int>(name: "Some Event")
    /// ```
    /// This declares `SomeEvent` as an event that will require an `Int` on publish and will pass the same `Int` to the subscription handler.
    struct Event<Message: Causality.Message>: CausalityAnyEvent {
        /// `name` provides some context on the purpose of the event.  It does not have to be unique.  However, events of the same "name" will not be called even if they have the same message type.
        public let name: String

        internal let id = UUID()
    }

    typealias EventId = UUID

    struct StatefulEvent<State: Causality.State>: CausalityAnyStatefulEvent {
        /// `name` provides some context on the purpose of the event.  It does not have to be unique.  However, events of the same "name" will not be called even if they have the same message type.
        public let name: String

        internal let id = UUID()
    }

    typealias AnyStatefulEvent = AnyHashable
}

protocol CausalityAnyEvent: Hashable {
    var name: String { get }
    var id: UUID { get }
}

protocol CausalityAnyStatefulEvent: CausalityAnyEvent {

}

extension Causality.Bus {
    // MARK: Publish Event With Message

    /// Publish an event to the bus.
    ///
    /// All subscribers to this event will have their handler called along with the associated message.
    /// - Parameters:
    ///   - event: Event to publish
    ///   - message: Message to send in event
    public func publish<Message: Causality.Message>(event: Causality.Event<Message>, message: Message) {

        self.publish(event: event, message: message, workQueue: .none)
    }


    // MARK: Publish Event With No Message

    /// Publish an event with no message
    /// - Parameter event: Event to publish
    public func publish(event: Causality.Event<Causality.NoMessage>) {
        let message = Causality.NoMessage.message
        self.publish(event: event, message: message, workQueue: .none)
    }

    // MARK: Subscribe Event w/ Subscription

    /// Add a subscriber to a specific event type
    /// - Parameters:
    ///   - event: The event type to subscribe to.
    ///   - handler: A handler that is called for each event of this type that occurs.  This handler will be called on the queue specified by the publisher (if given).  Otherwise there is no guarantee on what queue/thread the handler will be called on.
    @discardableResult
    public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, handler: @escaping (Causality.Subscription, Message)->Void) -> Causality.Subscription {

        return self.subscribe(event, workQueue: .none, handler: handler)
    }

    /// Add a subscriber to a specific event type
    /// - Parameters:
    ///   - event: The event type to subscribe to.
    ///   - queue: DispatchQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    @discardableResult
    public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, queue: DispatchQueue?=nil, handler: @escaping (Causality.Subscription, Message)->Void) -> Causality.Subscription {
        let workQueue = WorkQueue(queue)
        return self.subscribe(event, workQueue: workQueue, handler: handler)
    }

    /// Add a subscriber to a specific event type
    /// - Parameters:
    ///   - event: The event type to subscribe to.
    ///   - queue: OperationQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    @discardableResult
    public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, queue: OperationQueue, handler: @escaping (Causality.Subscription, Message)->Void) -> Causality.Subscription {

        return self.subscribe(event, workQueue: .operation(queue), handler: handler)
    }

    // MARK: Subscribe Event w/o Subscription

    /// Add a subscriber to a specific event type
    /// - Parameters:
    ///   - event: The event type to subscribe to.
    ///   - handler: A handler that is called for each event of this type that occurs.  This handler will be called on the queue specified by the publisher (if given).  Otherwise there is no guarantee on what queue/thread the handler will be called on.
    @discardableResult
    public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, handler: @escaping (Message)->Void) -> Causality.Subscription {

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
    public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, queue: DispatchQueue?=nil, handler: @escaping (Message)->Void) -> Causality.Subscription {
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
    public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, queue: OperationQueue, handler: @escaping (Message)->Void) -> Causality.Subscription {

        return self.subscribe(event, workQueue: .operation(queue)) { _, message in
            handler(message)
        }
    }


    // MARK: Unsubscribe Event

    /// Stop a particular subscription handler from listening to events anymore.
    /// - Parameters:
    ///   - subsription: The Subscription that was returned from `subscribe()`
    public func unsubscribe(_ subscription: Causality.Subscription) {
        self.unsubscribe([subscription])
    }

    /// Unsubscribe an array of subscriptions
    /// - Parameter subscriptions: Subscriptions to unsubscribe from
    public func unsubscribe(_ subscriptions: [Causality.Subscription]) {
        self.queue.async {
            var newSubscribers = self.subscribers
            for subscription in subscriptions {
                newSubscribers.removeValue(forKey: subscription.id)
            }
            self.subscribers = newSubscribers
        }
    }


    // MARK: - Private Event Methods

    /// Add a subscriber to a specific event type
    /// - Parameters:
    ///   - event: The event type to subscribe to.
    ///   - handler: A handler that is called for each event of this type that occurs
    private func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, workQueue: WorkQueue, handler: @escaping (Causality.Subscription, Message)->Void) -> Causality.Subscription {

        let subscriber = EventSubscriber(bus: self, event: event, handler: handler, workQueue: workQueue)
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
                guard let subscriber = someSubscriber as? EventSubscriber<Message> else {
                    continue
                }
                guard subscriber.state != .unsubscribePending else {
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
