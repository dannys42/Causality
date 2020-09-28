//
//  Causality.swift
//  
//
//  Created by Danny Sung on 09/27/2020.
//

import Foundation

public extension Causality {
    typealias AnyState = Codable

    /// Custom type for `State` info
    typealias State = AnyState & Equatable

    typealias StateSubscription = AnyStateSubscriber

}


// MARK: - Bus Extension
extension Causality.Bus {

    public func hasState<State: Causality.State>(event: Causality.StatefulEvent<State>) -> Bool {
        return self.state[event] != nil
    }

    public func getState<State: Causality.State>(event: Causality.StatefulEvent<State>) -> State? {
        return self.state[event] as? State
    }

    // MARK: Publish Event With State

    /// Publish an event to the bus.
    ///
    /// All subscribers to this event will have their handler called along with the associated message.
    /// - Parameters:
    ///   - event: Event to publish
    ///   - message: Message to send in event
    public func publish<State: Causality.State>(event: Causality.StatefulEvent<State>, state: State) {

        self.publish(event: event, state: state, workQueue: .none)
    }

    // MARK: Subscribe Event w/ Subscription

    /// Add a subscriber to a specific state type
    /// - Parameters:
    ///   - event: The event type to subscribe to.
    ///   - queue: DispatchQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    @discardableResult
    public func subscribe<State: Causality.State>(_ event: Causality.StatefulEvent<State>, queue: DispatchQueue?=nil, handler: @escaping (Causality.StateSubscription, State)->Void) -> Causality.StateSubscription {
        let workQueue = WorkQueue(queue)
        return self.subscribe(event, workQueue: workQueue, handler: handler)
    }

    /// Add a subscriber to a specific state type
    /// - Parameters:
    ///   - event: The event type to subscribe to.
    ///   - queue: OperationQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    @discardableResult
    public func subscribe<State: Causality.State>(_ event: Causality.StatefulEvent<State>, queue: OperationQueue, handler: @escaping (Causality.StateSubscription, State)->Void) -> Causality.StateSubscription {

        return self.subscribe(event, workQueue: .operation(queue), handler: handler)
    }

    // MARK: Subscribe State w/o Subscription

    /// Add a subscriber to a specific state type
    /// - Parameters:
    ///   - event: The event type to subscribe to.
    ///   - queue: DispatchQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    public func subscribe<State: Causality.State>(_ event: Causality.StatefulEvent<State>, queue: DispatchQueue?=nil, handler: @escaping (State)->Void) -> Causality.StateSubscription {
        let workQueue = WorkQueue(queue)
        return self.subscribe(event, workQueue: workQueue) { _, state in
            handler(state)
        }
    }

    /// Add a subscriber to a specific state type
    /// - Parameters:
    ///   - event: The event type to subscribe to.
    ///   - queue: OperationQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    public func subscribe<State: Causality.State>(_ event: Causality.StatefulEvent<State>, queue: OperationQueue, handler: @escaping (State)->Void) -> Causality.StateSubscription {

        return self.subscribe(event, workQueue: .operation(queue)) { _, state in
            handler(state)
        }
    }

    // MARK: Unsubscribe State

    /// Stop a particular subscription handler from listening to state changes anymore.
    /// - Parameters:
    ///   - subsription: The Subscription that was returned from `subscribe()`
    public func unsubscribe(_ subscription: Causality.StateSubscription) {
        self.unsubscribe([subscription])
    }

    /// Unsubscribe an array of subscriptions
    /// - Parameter subscriptions: Subscriptions to unsubscribe from
    public func unsubscribe(_ subscriptions: [Causality.StateSubscription]) {
        self.queue.async {
            var newSubscribers = self.subscribers
            for subscription in subscriptions {
                newSubscribers.removeValue(forKey: subscription.id)
            }
            self.subscribers = newSubscribers
        }
    }

    // MARK: - Private Methods

    /// Subscribe to changes of a state
    /// - Parameters:
    ///   - event: The state to subscribe to
    ///   - workQueue: The queue on which to execute the handler
    ///   - handler: A handler that is called when the state changes.  If there was a previous value, the handler be called immediately with the old value.
    private func subscribe<State: Causality.State>(_ event: Causality.StatefulEvent<State>, workQueue: WorkQueue, handler: @escaping (Causality.StateSubscription, State)->Void) -> Causality.StateSubscription {

        let subscriber = StateSubscriber(bus: self, event: event, handler: handler, workQueue: workQueue)
        self.queue.async {
            self.stateSubscribers[subscriber.id] = subscriber

            if let state = self.state[event] as? State {
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
    ///   - event: Event to publish
    ///   - state: State info to check & send
    private func publish<State: Causality.State>(event: Causality.StatefulEvent<State>, state: State, workQueue: WorkQueue) {

        self.queue.sync {
            // If an existing state exists and is the same state, do nothing
            if let lastState = self.state[event] as? State {
                if lastState == state {
                    return
                }
            }

            let subscribers = self.stateSubscribers
            for (_, someSubscriber) in subscribers {
                guard let subscriber = someSubscriber as? StateSubscriber<State> else {
                    continue
                }
                guard subscriber.state != .unsubscribePending else {
                    continue
                }
                let runQueue = subscriber.workQueue.withDefault(workQueue)
                runQueue.execute {
                    subscriber.handler(subscriber, state)
                }
            }

            // Update the last state
            self.state[event] = state
        }
    }

}
