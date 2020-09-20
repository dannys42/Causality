//
//  Bus.swift
//
//
//  Created by Danny Sung on 09/20/2020.
//

import Foundation

public extension Causality {
    static let bus = Bus(name: "global")

    class Bus {
        public private(set) var name: String

        public init(name: String) {
            self.name = name
        }

        public typealias Subscription = UUID
        internal var subscribers: [Any] = []

        /// Publish an event to the bus.
        ///
        /// All subscribers to this event will have their handler called along with the associated message.
        /// - Parameters:
        ///   - event: Event to publish
        ///   - message: Message to send in event
        public func publish<Message: Causality.Message>(event: Causality.Event<Message>, message: Message) {

            self.eachSubscriber(event: event) { (subscriber) in
                subscriber.handler(message)
            }
        }

        /// Publish an event with no message
        /// - Parameter event: Event to publish
        public func publish(event: Causality.Event<Causality.NoMessage>) {
            self.eachSubscriber(event: event) { (subscriber) in
                subscriber.handler(Causality.NoMessage.message)
            }
        }



        /// Add a subscriber to a specific event type
        /// - Parameters:
        ///   - event: The event type to subscribe to.
        ///   - handler: A handler that is called for each event of this type that occurs
        @discardableResult
        public func subscribe<Message: Causality.Message>(_ event: Causality.Event<Message>, handler: @escaping (Message)->Void) -> Subscription {

            let subscriber = Subscriber(event: event, handler: handler)
            subscribers.append(subscriber)

            return subscriber.id
        }

        /// Stop a particular subscription handler from listening to events anymore.
        /// - Parameters:
        ///   - subsription: The Subscription that was returned from `subscribe()`
        public func unsubscribe(_ subscription: Subscription) {
            var newSubscribers: [Any] = []

            for subscriber in subscribers {
                guard let subscriber = subscriber as? SubscriberId,
                      subscriber.id == subscription
                else {
                    continue
                }
                newSubscribers.append(subscriber)
            }
            self.subscribers = newSubscribers
        }
        /// Unsubscribe an array of subscriptions
        /// - Parameter subscriptions: Subscriptions to unsubscribe from
        public func unsubscribe(_ subscriptions: [Subscription]) {
            for subscription in subscriptions {
                self.unsubscribe(subscription)
            }
        }

        // MARK: - Private Methods

        /// Call every subscriber that matches the event
        /// - Parameters:
        ///   - event: An event description
        ///   - each: handler called for every subscriber that matches the event
        private func eachSubscriber<Message: Causality.Message>(event: Causality.Event<Message>, _ each: (Subscriber<Message>)->Void) {

            for subscriber in subscribers {
                guard let subscriber = subscriber as? Subscriber<Message>
                else {
                    continue
                }
                each(subscriber)
            }

        }
    }
}
