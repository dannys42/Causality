//
//  Event.swift
//  
//
//  Created by Danny Sung on 09/20/2020.
//

import Foundation

public extension Causality {

    /// Underlying type for EventIds (do not rely on this always being a UUID)
    typealias EventId = UUID

    /// A type-erased form of an Event.  Callers usally do not need to worry about this.
    class AnyEvent<Message: Causality.Message>: CausalityAddress {
        /// A unique identifier used to match events
        public var causalityEventId: AnyHashable

        init() {
            self.causalityEventId = AnyHashable(UUID())

            if let dynamicSelf = self as? Causality.DynamicEvent<Message> {
                self.causalityEventId = dynamicSelf.hashOfCodableValues
            }
        }
    }

    /// Declare events to be used as endpoints for publish or subscribe calls.
    ///
    /// Example:
    /// ```
    /// static let SomeEvent = Causality.Event<Int>(label: "Some Event")
    /// ```
    /// This declares `SomeEvent` as an event that will require an `Int` on publish and will pass the same `Int` to the subscription handler.
    class Event<Message: Causality.Message>: Causality.AnyEvent<Message> & Hashable {

        var label: String

        private let id: EventId

        /// Initialize an event
        /// - Parameter label: provides some context on the purpose of the event.
        ///
        /// Note: This does not uniquely identify the event.
        init(label: String) {
            self.label = label
            self.id = UUID()
            super.init()

            self.causalityEventId = AnyHashable(self.id)
        }

        public static func == (lhs: Causality.Event<Message>, rhs: Causality.Event<Message>) -> Bool {
            return lhs.id == rhs.id
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.id)
        }
    }
    typealias CustomEvent<Message: Causality.Message> = Causality.AnyEvent<Message> & Hashable

    /// `DynamicEvent` can be used if you need to uniquely identify states by paramter.
    /// To properly declare your `DynamicEvent`, ensure you define your `CodingKeys` and override `encode()` to conform to Encodable.  All keys that you want to be included in the unique identification should be specified in `encode()`.
    class DynamicEvent<Message: Causality.Message>: Causality.AnyEvent<Message> & Encodable {
    }

}

extension Causality.Bus {
    // MARK: Publish Event With Message

    /// Publish an event to the bus.
    ///
    /// All subscribers to this event will have their handler called along with the associated message.
    /// - Parameters:
    ///   - event: Event to publish
    ///   - message: Message to send in event
    public func publish<Event: Causality.AnyEvent<Message>, Message: Causality.Message>(event: Event, message: Message) {

        self.publish(event: event, message: message, workQueue: .none)
    }


    // MARK: Publish Event With No Message

    /// Publish an event with no message
    /// - Parameter event: Event to publish
    public func publish<Event: Causality.AnyEvent<Causality.NoMessage>>(event: Event) {
        let message = Causality.NoMessage.message
        self.publish(event: event, message: message, workQueue: .none)
    }

    // MARK: Subscribe Event w/ Subscription

    /// Add a subscriber to a specific event type
    /// - Parameters:
    ///   - event: The event to subscribe to.
    ///   - queue: DispatchQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    @discardableResult
    public func subscribe<Event: Causality.AnyEvent<Message>, Message: Causality.Message>(_ event: Event, queue: DispatchQueue?=nil, handler: @escaping (Causality.EventSubscription<Event,Message>, Message)->Void) -> Causality.EventSubscription<Event,Message> {
        
        return self.subscribe(event, workQueue: .dispatch(queue), handler: handler)
    }

    /// Add a subscriber to a specific event type
    /// - Parameters:
    ///   - event: The event to subscribe to.
    ///   - queue: OperationQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    @discardableResult
    public func subscribe<Event: Causality.AnyEvent<Message>, Message: Causality.Message>(_ event: Event, queue: OperationQueue, handler: @escaping (Causality.EventSubscription<Event,Message>, Message)->Void) -> Causality.EventSubscription<Event,Message> {

        return self.subscribe(event, workQueue: .operation(queue), handler: handler)
    }

    // MARK: Subscribe Event w/o Subscription

    /// Add a subscriber to an event
    /// - Parameters:
    ///   - event: The event to subscribe to.
    ///   - queue: DispatchQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    /// - Returns: Subscription handle that is needed to unsubscribe to this event
    @discardableResult
    public func subscribe<Event: Causality.AnyEvent<Message>, Message: Causality.Message>(_ event: Event, queue: DispatchQueue?=nil, handler: @escaping (Message)->Void) -> Causality.EventSubscription<Event,Message> {
        let workQueue = WorkQueue(queue)
        return self.subscribe(event, workQueue: workQueue) { _, message in
            handler(message)
        }
    }

    /// Add a subscriber to an event
    /// - Parameters:
    ///   - event: The event to subscribe to.
    ///   - queue: OperationQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    /// - Returns: Subscription handle that is needed to unsubscribe to this event
    @discardableResult
    public func subscribe<Event: Causality.AnyEvent<Message>, Message: Causality.Message>(_ event: Event, queue: OperationQueue, handler: @escaping (Message)->Void) -> Causality.EventSubscription<Event,Message> {

        return self.subscribe(event, workQueue: .operation(queue)) { _, message in
            handler(message)
        }
    }


    // MARK: Unsubscribe Event

    /// Stop a particular subscription handler from listening to events anymore.
    /// - Parameters:
    ///   - subsription: The Subscription that was returned from `subscribe()`
    public func unsubscribe<Event: Causality.AnyEvent<Message>, Message: Causality.Message>(_ subscription: Causality.EventSubscription<Event, Message>) {
        self.unsubscribe([subscription])
    }

    /// Unsubscribe an array of subscriptions
    /// - Parameter subscriptions: Subscriptions to unsubscribe from
    public func unsubscribe<Event: Causality.AnyEvent<Message>, Message: Causality.Message>(_ subscriptions: [Causality.EventSubscription<Event, Message>]) {
        self.queue.async {
            var newSubscribers = self.eventSubscribers
            for subscription in subscriptions {
                newSubscribers.removeValue(forKey: subscription.id)
            }
            self.eventSubscribers = newSubscribers
        }
    }

    // MARK: - Private Event Methods

    /// Add a subscriber to a specific event type
    /// - Parameters:
    ///   - event: The event type to subscribe to.
    ///   - workQueue: The queue to execute the handler on
    ///   - handler: A handler that is called for each event of this type that occurs
    /// - Returns: Subscription handle used to unsubscribe (If not .none, this will take precedence over any work queue specified by the publisher)
    private func subscribe<Event: Causality.AnyEvent<Message>, Message: Causality.Message>(_ event: Event, workQueue: WorkQueue, handler: @escaping (Causality.EventSubscription<Event,Message>, Message)->Void) -> Causality.EventSubscription<Event,Message> {

        let subscriber = Causality.EventSubscription(bus: self, event: event, handler: handler, workQueue: workQueue)
        self.queue.async {
            self.eventSubscribers[subscriber.id] = subscriber
        }

        return subscriber
    }

    /// Publish an event to the bus.
    ///
    /// All subscribers to this event will have their handler called along with the associated message.
    /// - Parameters:
    ///   - event: Event to publish
    ///   - message: Message to send in event
    ///   - workQueue: Work queue to execute the subscription on
    private func publish<Event: Causality.AnyEvent<Message>, Message: Causality.Message>(event: Event, message: Message, workQueue: WorkQueue) {

        self.queue.sync {
            let subscribers = self.eventSubscribers
            for (_, someSubscriber) in subscribers {
                guard let subscriber = someSubscriber as? Causality.EventSubscription<Event,Message> else {
                    continue
                }
                guard subscriber.event.causalityEventId == event.causalityEventId else {
                    continue
                }
                guard subscriber.status != .unsubscribePending else {
                    continue
                }
                let runQueue = subscriber.workQueue.withDefault(workQueue)
                runQueue.execute {
                    subscriber.handler(subscriber, message)
                }
            }
        }
    }
}
