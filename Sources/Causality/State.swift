//
//  Causality.swift
//  
//
//  Created by Danny Sung on 09/27/2020.
//

import Foundation

protocol CausalityAnyState: Hashable {
    var name: String { get }
    var id: Causality.StateId { get }
}

public extension Causality {
    typealias AnyStateValue = Any
    typealias StateId = UUID

    /// Custom type for `State` info
    typealias StateValue = AnyStateValue & Equatable

    typealias StateSubscription = CausalityStateSubscription

    struct State<State: Causality.StateValue>: CausalityAnyState {
        /// `name` provides some context on the purpose of the event.  It does not have to be unique.  However, events of the same "name" will not be called even if they have the same message type.
        public let name: String

        internal let id: StateId = UUID()
    }

    internal typealias AnyState = AnyHashable

}

// MARK: - Bus Extension
extension Causality.Bus {

    /// Determine if a state has an existing value
    /// - Parameter state: State to check
    /// - Returns: True if state has an existing value; False otherwise.
    public func hasState<Value: Causality.StateValue>(_ state: Causality.State<Value>) -> Bool {
        var doesExist = false
        self.queue.sync {
            doesExist = (self.state[state] != nil)
        }
        return doesExist
    }

    /// Get the last known value for a state
    /// - Parameter state: State to check
    /// - Returns: Value of state
    public func getState<Value: Causality.StateValue>(_ state: Causality.State<Value>) -> Value? {
        var value: Value?

        self.queue.sync {
            value = self.state[state] as? Value
        }
        return value
    }

    // MARK: Publish Event With State

    /// Publish an event to the bus.
    ///
    /// All subscribers to this event will have their handler called along with the associated message.
    /// - Parameters:
    ///   - state: The state to set the value for
    ///   - value: The value to set for the given state
    public func set<Value: Causality.StateValue>(state: Causality.State<Value>, value: Value) {

        self.set(state: state, value: value, workQueue: .none)
    }

    // MARK: Subscribe Event w/ Subscription

    /// Add a subscriber to a specific state type
    /// - Parameters:
    ///   - state: The state to subscribe to.
    ///   - queue: DispatchQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    @discardableResult
    public func subscribe<Value: Causality.StateValue>(_ state: Causality.State<Value>, queue: DispatchQueue?=nil, handler: @escaping (Causality.StateSubscription, Value)->Void) -> Causality.StateSubscription {
        let workQueue = WorkQueue(queue)
        return self.subscribe(state, workQueue: workQueue, handler: handler)
    }

    /// Add a subscriber to a specific state type
    /// - Parameters:
    ///   - state: The state to subscribe to.
    ///   - queue: OperationQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    @discardableResult
    public func subscribe<Value: Causality.StateValue>(_ state: Causality.State<Value>, queue: OperationQueue, handler: @escaping (Causality.StateSubscription, Value)->Void) -> Causality.StateSubscription {

        return self.subscribe(state, workQueue: .operation(queue), handler: handler)
    }

    // MARK: Subscribe State w/o Subscription

    /// Add a subscriber to a specific state type
    /// - Parameters:
    ///   - state: The state to subscribe to.
    ///   - queue: DispatchQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    public func subscribe<Value: Causality.StateValue>(_ state: Causality.State<Value>, queue: DispatchQueue?=nil, handler: @escaping (Value)->Void) -> Causality.StateSubscription {
        let workQueue = WorkQueue(queue)
        return self.subscribe(state, workQueue: workQueue) { _, state in
            handler(state)
        }
    }

    /// Add a subscriber to a specific state type
    /// - Parameters:
    ///   - state: The event type to subscribe to.
    ///   - queue: OperationQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    public func subscribe<Value: Causality.StateValue>(_ state: Causality.State<Value>, queue: OperationQueue, handler: @escaping (Value)->Void) -> Causality.StateSubscription {

        return self.subscribe(state, workQueue: .operation(queue)) { _, state in
            handler(state)
        }
    }

    // MARK: Unsubscribe State

    /// Stop a particular subscription handler from listening to state changes anymore.
    /// - Parameters:
    ///   - subscription: The Subscription that was returned from `subscribe()`
    public func unsubscribe(_ subscription: Causality.StateSubscription) {
        self.unsubscribe([subscription])
    }

    /// Unsubscribe an array of subscriptions
    /// - Parameter subscriptions: Subscriptions to unsubscribe from
    public func unsubscribe(_ subscriptions: [Causality.StateSubscription]) {
        self.queue.async {
            var newSubscribers = self.eventSubscribers
            for subscription in subscriptions {
                newSubscribers.removeValue(forKey: subscription.id)
            }
            self.eventSubscribers = newSubscribers
        }
    }

    // MARK: - Private Methods

    /// Subscribe to changes of a state
    /// - Parameters:
    ///   - state: The state to subscribe to
    ///   - workQueue: The queue on which to execute the handler
    ///   - handler: A handler that is called when the state changes.  If there was a previous value, the handler be called immediately with the old value.
    private func subscribe<Value: Causality.StateValue>(_ state: Causality.State<Value>, workQueue: WorkQueue, handler: @escaping (Causality.StateSubscription, Value)->Void) -> Causality.StateSubscription {

        let subscriber = StateSubscriber(bus: self, state: state, handler: handler, workQueue: workQueue)
        self.queue.async {
            self.stateSubscribers[subscriber.id] = subscriber

            if let state = self.state[state] as? Value {
                let runQueue = subscriber.workQueue.withDefault(workQueue)
                runQueue.execute {
                    subscriber.handler(subscriber, state)
                }
            }
        }

        return subscriber
    }

    /// Publish a state to the bus.
    ///
    /// All subscribers to this state will have their handler called with the state value when either of these conditions occur:
    ///
    /// - If no state value has been published before
    /// - The state value has changed since the last published state
    /// 
    /// - Parameters:
    ///   - state: State info to check & send
    ///   - value: Value to set for the given state
    ///   - workQueue: Work used to call handler (if none provided by subscriber)
    private func set<Value: Causality.StateValue>(state: Causality.State<Value>, value: Value, workQueue: WorkQueue) {

        self.queue.sync {
            // If an existing state exists and is the same state, do nothing
            if let lastStateValue = self.state[state] as? Value {
                if lastStateValue == value {
                    return
                }
            }

            let subscribers = self.stateSubscribers
            for (_, someSubscriber) in subscribers {
                guard let subscriber = someSubscriber as? StateSubscriber<Value> else {
                    continue
                }
                guard subscriber.subscriptionState != .unsubscribePending else {
                    continue
                }
                let runQueue = subscriber.workQueue.withDefault(workQueue)
                runQueue.execute {
                    subscriber.handler(subscriber, value)
                }
            }

            // Update the last state
            self.state[state] = value
        }
    }

}
