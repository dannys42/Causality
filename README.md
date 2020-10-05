<p align="center">
<a href="https://github.com/dannys42/Causality/actions?query=workflow%3ASwift"><img src="https://github.com/dannys42/Causality/workflows/Swift/badge.svg" alt="build status"></a>
<img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
<img src="https://img.shields.io/badge/os-iOS-green.svg?style=flat" alt="iOS">
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
<a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2"></a>

</p>

# Causality
`Causality` is simple in-memory event bus for Swift.  Events may have associated data and are fully typed.  All publish/subscribe methods are thread-safe.

In addition, `Causality` has provisions for monitoring State information.  State differs from Events in that:

 - State handlers will be called immediately with the last known good value (if one is available)
 - State handlers will not be called if the state value is identical to the previous value

## Installation

### Swift Package Manager
Add the `Causality` package to the dependencies within your application's `Package.swift` file.  Substitute "x.y.z" with the latest `Causality` [release](https://github.com/dannys42/Causality/releases).

```swift
.package(url: "https://github.com/dannys42/Causality.git", from: "x.y.z")
```

Add `Causality` to your target's dependencies:

```swift
.target(name: "example", dependencies: ["Causality"]),
```

## Usage

## Events

### Just an event (no data)
The simplest event to manage has no associated data.

#### Declare Events

This declares an event called `aTriggerEvent` that has no associated data.

```swift
struct MyEvents {
    static let aTriggerEvent = Causality.Event<NoSimpleEventMessage>(name: "A Trigger")
}
```

#### Subscribe to events

To subscribe to this event:

```swift
let subscription = Causality.bus.subscribe(MyEvents.aTriggerEvent) { _ in
    print("Event happened")
}

```

#### Publish events

To publish/post an event of this type:

```swift
Causality.bus.publish(MyEvents.aTriggerEvent)
```

### An event with associated data

Events can include data of any type (referred to as a "message").  The event label is fully type specified with the message.  So a subscriber will have a fully typed message available to its handler.

#### Define the Message

A message can be a standard Swift type like `Int`, `String`, etc.  Or it can be a `struct` or `class`.  In this example, we'll declare a struct:

```swift
struct InterestingMessage: Causality.Message {
    let string: String
    let number: Int
}
```

#### Declare the event

Declaring an event with a message:

```swift
let someEvent = Causality.Event<SomeMessage>(name: "Some Event")
```

Or categorize your events:

```swift
struct MyEvents {
    static let interestingEvent1 = Causality.Event<InterestingMessage>(name: "An interesting Event 1")
    static let interestingEvent2 = Causality.Event<InterestingMessage>(name: "An interesting Event 2")
}
```

#### Subscribing and Unsubscribing to the events

Save your subscriptions to unsubscribe later:

```swift
let subscription = Causality.bus.subscribe(MyEvents.interestingEvent) { message in
    print("A message from interestingEvent: \(message)")
}

Casaulity.bus.unsubscribe(subscription)
```

Or unsubscribe from within a subscription handler:

```swift
Causality.bus.subscribe(MyEvents.interestingEvent) { subscription, message in
    print("A message from interestingEvent: \(message)")
    
    subscription.unsubscribe()
}
```


#### Publish events

To publish/post an event of this type:

```swift
Causality.bus.publish(MyEvents.interestingEvent1, 
    message: InterestingMessage(string: "Hello", number: 42))
```

Create aliases for your bus:

```swift
let eventBus = Causality.bus

eventBus.publish(MyEvents.interestingEvent1, 
    message: InterestingMessage(string: "Hello", number: 42))
```

Or create local buses to isolate your events:

```swift
let newEventBus = Causality.Bus(name: "My local bus")

newEventBus.publish(MyEvents.interestingEvent1, 
    message: InterestingMessage(string: "Hello", number: 42))
```



## State

#### Define the State Value

Similar to Events, States have defined values.  However `StateValue`s must be Equatable. 


```swift
struct PlayerInfo: Causality.StateValue {
    let numberOfLives: Int
    let health: Int
    let armor: Int
}
```

#### Declare the state

Declaring a state with the associated value:

```swift
let playerState = Causality.State<PlayerInfo>(name: "Player State")
```

Or categorize your events:

```swift
struct GameStates {
    static let playerState1 = Causality.State<PlayerInfo>(name: "Player 1 State")
    static let playerState2 = Causality.State<PlayerInfo>(name: "Player 2 State")
}
```

#### Subscribing and Unsubscribing to State changes

Save your subscriptions to unsubscribe later:

```swift
let subscription = Causality.bus.subscribe(GameStates.playerState1) { state in
    print("Player 1 state changed to: \(state)")
}

Casaulity.bus.unsubscribe(subscription)
```

Or unsubscribe from within a subscription handler:

```swift
Causality.bus.subscribe(GameStates.playerState1) { subscription, message in
    print("Player 1 state changed to: \(state)")
    
    subscription.unsubscribe()
}
```

If the state was previously set, the subscription handler will be called immediately with the last known value.  The subscription handler will only be called if subsequent `.set()` calls have differing values.


#### Setting State

```swift
Causality.bus.set(GameStates.playerState1, 
    value: PlayerInfo(numberOfLives: 3, health: 75, armor: 10))
```


## Dynamic States

In the game example above, we have one Causality.State variable for every state.  But what if we have "n" number of players?  In that case, we can use Dynamic States.  Dynamic States allows you to parameterize your State.  Dynamic States are Codable and require you to define `CodingKeys` and to overload the `encode()` function to specify "key" parameters.  These parameters are used to uniquely identify the state.  For example:

```
class PlayerState<Value: PlayerInfo>: Causality.DynamicState<Value> {
    let playerId: Int

    init(playerId: Int) {
        self.playerId = playerId
    }
    enum CodingKeys: CodingKey {
        case playerId
    }
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.playerId, forKey: .playerId)
    }
}
```

Now to subscribe:

```swift

Causality.bus.subscribe(PlayerState<PlayerInfo>(playerId: 1)) { subscription, playerInfo in
    print("Current player info is: \(playerInfo))
}

```

Or to add more organization:

```swift
struct GameState {
    static func playerState(_ playerId: Int) -> PlayerState<PlayerInfo> {
        return PlayerState<PlayerInfo>(playerId: playerId)
    }
}

Causality.bus.subscribe(GameState.playerState(1)) { subscription, playerInfo in
    print("Current player info is: \(playerInfo)")
}
```

And to set/update a state:

```swift

event.set(state: GameState.playerState(1), 
    value: PlayerInfo(
        numberOfLines: 3,
        health: 75,
        armor: 100))

```

## Dynamic Events

Events can be parameterized by defining them in a similar way:

```swift
class MyEvent<Message: Causality.Message>: Causality.DynamicEvent<Message> {

    let eventId: Int

    init(eventId: Int) {
        self.eventId = eventId
    }
    enum CodingKeys: CodingKey {
        case eventId
    }
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.eventId, forKey: .eventId)
    }
}
```

Then create the event:

```swift
struct MyEvents {
    static func event(_ eventId: Int) -> MyEvent<InterestingMessage> {
        return MyEvent<InterestingMessage>(eventId: eventId)
    }
}
```


Subscribe to the event:

```swift
let subscription = Causality.bus.subscribe(MyEvents.event(1)) { subscription, message in
    print("A message from event \(subscription.event.eventId): \(message)")
}
```

And publish events:

```swift

Causality.bus.publish(MyEvents.event(1), 
    message: InterestingMessage(string: "Hello", number: 42))

```



## API Documentation
For more information visit our [API reference](https://dannys42.github.io/Causality/).

## Related Projects
 - [OpenCombine](https://github.com/OpenCombine/OpenCombine)
 - [EventBus](https://github.com/regexident/EventBus)
 - [TopicEventBus](https://github.com/mcmatan/topicEventBus)
 - [SwiftEventBus](https://github.com/cesarferreira/SwiftEventBus)
 - [EmitterKit](https://github.com/aleclarson/emitter-kit)
 
## License
This library is licensed under Apache 2.0. The full license text is available in [LICENSE](LICENSE).
