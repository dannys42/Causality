//
//  Causality.swift
//  
//
//  Created by Danny Sung on 09/27/2020.
//

import Foundation

/// Type-erased State
public protocol CausalityAnyState: CausalityAddress & AnyObject {
    /// A unique id used to compare states
    var causalityStateId: AnyHashable { get }
}

public extension Causality {
    /// Type-erased StateValue
    typealias AnyStateValue = Any

    /// Underlying type for StateIds (do not rely on this always being a UUID)
    internal typealias StateId = UUID

    /// Custom type for `State` info
    typealias StateValue = AnyStateValue & Equatable

    internal typealias AnyHashableState = AnyHashable


    /// Base class that `State<Causality.StateValue>` and `DynamicState<Causality.StateValue>` conform to.
    class AnyState<Value: Causality.StateValue>: CausalityAnyState {
        /// A unique ID for each state.
        public var causalityStateId: AnyHashable

        init() {
            self.causalityStateId = AnyHashable(UUID())

            if let dynamicSelf = self as? Causality.DynamicState<Value> {
                self.causalityStateId = dynamicSelf.hashOfCodableValues
            }
        }
    }

    /// Declare states with typed values as labels to be used for `set()` and `subscribe()` calls.
    ///
    /// Example:
    /// ```
    /// static let SomeState = Causality.State<Int>(label: "Some State")
    /// ```
    /// This declares `SomeState` as an state that will pass an `Int` to subscribers whenever the value changes.
    class State<Value: Causality.StateValue>: Causality.AnyState<Value> & Hashable {
        /// A name assigned to the state.  This is not a key parameter and does not need to be unique.
        public let label: String

        private let id: StateId

        /// Initialize a state
        /// - Parameter label: provides some context on the purpose of the state.
        /// 
        /// Note: This does not uniquely identify the state.
        public init(label: String) {
            self.label = label
            self.id = UUID()
            super.init()

            self.causalityStateId = AnyHashable(self.id)
        }

        public static func == (lhs: Causality.State<Value>, rhs: Causality.State<Value>) -> Bool {
            return lhs.id == rhs.id
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.id)
        }
    }

    /// `DynamicState` can be used if you need to uniquely identify states by paramter.
    /// To properly declare your `DynamicState`, ensure you define your `CodingKeys` and override `encode()` to conform to Encodable.  Only keys that you want to be included in the unique identification should be specified in `encode()`.
    class DynamicState<State: Causality.StateValue>: Causality.AnyState<State> & Encodable {
    }


}

// MARK: - Bus Extension
extension Causality.Bus {

    /// Determine if a state has an existing value
    /// - Parameter state: State to check
    /// - Returns: True if state has an existing value; False otherwise.
    public func hasState<State: Causality.AnyState<Value>, Value: Causality.StateValue>(_ state: State) -> Bool {
        var doesExist = false
        self.queue.sync {
            doesExist = (self.state[state.causalityStateId] != nil)
        }
        return doesExist
    }

    /// Get the last known value for a state
    /// - Parameter state: State to check
    /// - Returns: Value of state
    public func getState<State: Causality.AnyState<Value>, Value: Causality.StateValue>(_ state: State) -> Value? {
        var value: Value?

        self.queue.sync {
            value = self.state[state.causalityStateId] as? Value
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
    public func set<State: Causality.AnyState<Value>, Value: Causality.StateValue>(state: State, value: Value) {

        self.set(state: state, value: value, workQueue: .none)
    }

    // MARK: Subscribe Event w/ Subscription

    /// Add a subscriber to a specific state type
    /// - Parameters:
    ///   - state: The state to subscribe to.
    ///   - queue: DispatchQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    @discardableResult
    public func subscribe<State: Causality.AnyState<Value>, Value: Causality.StateValue>(_ state: State, queue: DispatchQueue?=nil, handler: @escaping (Causality.StateSubscription<State,Value>, Value)->Void) -> Causality.StateSubscription<State, Value> {
        let workQueue = WorkQueue(queue)
        return self.subscribe(state, workQueue: workQueue, handler: handler)
    }

    /// Add a subscriber to a specific state type
    /// - Parameters:
    ///   - state: The state to subscribe to.
    ///   - queue: OperationQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    @discardableResult
    public func subscribe<State: Causality.AnyState<Value>, Value: Causality.StateValue>(_ state: State, queue: OperationQueue, handler: @escaping (Causality.StateSubscription<State, Value>, Value)->Void) -> Causality.StateSubscription<State, Value> {

        return self.subscribe(state, workQueue: .operation(queue), handler: handler)
    }

    // MARK: Subscribe State w/o Subscription

    /// Add a subscriber to a specific state type
    /// - Parameters:
    ///   - state: The state to subscribe to.
    ///   - queue: DispatchQueue to receive messages on.  This will take precedence over any queue specified by the publisher.
    ///   - handler: A handler that is called for each event of this type that occurs (on the specified queue)
    public func subscribe<State: Causality.AnyState<Value>, Value: Causality.StateValue>(_ state: State, queue: DispatchQueue?=nil, handler: @escaping (Value)->Void) -> Causality.StateSubscription<State, Value> {
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
    public func subscribe<State: Causality.AnyState<Value>, Value: Causality.StateValue>(_ state: State, queue: OperationQueue, handler: @escaping (Value)->Void) -> Causality.StateSubscription<State, Value> {

        return self.subscribe(state, workQueue: .operation(queue)) { _, state in
            handler(state)
        }
    }

    // MARK: Unsubscribe State

    /// Stop a particular subscription handler from listening to state changes anymore.
    /// - Parameters:
    ///   - subscription: The Subscription that was returned from `subscribe()`
    public func unsubscribe<State: Causality.AnyState<Value>, Value: Causality.StateValue>(_ subscription: Causality.StateSubscription<State, Value>) {
        self.unsubscribe([subscription])
    }

    /// Unsubscribe an array of subscriptions
    /// - Parameter subscriptions: Subscriptions to unsubscribe from
    public func unsubscribe<State: Causality.AnyState<Value>, Value: Causality.StateValue>(_ subscriptions: [Causality.StateSubscription<State, Value>]) {
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
    private func subscribe<State: Causality.AnyState<Value>, Value: Causality.StateValue>(_ state: State, workQueue: WorkQueue, handler: @escaping (Causality.StateSubscription<State, Value>, Value)->Void) -> Causality.StateSubscription<State, Value> {

        let subscriber = Causality.StateSubscription(bus: self, state: state, handler: handler, workQueue: workQueue)
        self.queue.async {
            self.stateSubscribers[subscriber.id] = subscriber

            if let lastState = self.state[state.causalityStateId] as? Value {
                let runQueue = subscriber.workQueue.withDefault(workQueue)
                runQueue.execute {
                    subscriber.handler(subscriber, lastState)
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
    private func set<State: Causality.AnyState<Value>, Value: Causality.StateValue>(state: State, value: Value, workQueue: WorkQueue) {

        self.queue.sync {
            // If an existing state exists and is the same state, do nothing
            if let lastStateValue = self.state[state.causalityStateId] as? Value {
                if lastStateValue == value {
                    return
                }
            }

            let subscribers = self.stateSubscribers
            for (_, someSubscriber) in subscribers {
                guard let subscriber = someSubscriber as? Causality.StateSubscription<State,Value> else {
                    continue
                }
                guard subscriber.status != .unsubscribePending else {
                    continue
                }
                guard subscriber.state.causalityStateId == state.causalityStateId else {
                    continue
                }
                let runQueue = subscriber.workQueue.withDefault(workQueue)
                runQueue.execute {
                    subscriber.handler(subscriber, value)
                }
            }

            // Update the last state
            self.state[state.causalityStateId] = value
        }
    }

    private func lastStateValue<State: Causality.AnyState<Value>, Value: Causality.StateValue>(state: State) -> Value? {
        return self.state[state.causalityStateId] as? Value
    }
}
