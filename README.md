<p align="center">
<a href="https://github.com/dannys42/Causality/actions?query=workflow%3ASwift"><img src="https://github.com/dannys42/Causality/workflows/Swift/badge.svg" alt="build status"></a>
<img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
<img src="https://img.shields.io/badge/os-iOS-green.svg?style=flat" alt="iOS">
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
<a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2"></a>
<br/>
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdannys42%2FCausality%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/dannys42/Causality)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdannys42%2FCausality%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/dannys42/Causality)
</p>

# Causality
`Causality` is a simple thread-safe, in-memory bus for Swift that supports fully-typed Events and States.

In addition, `Causality` has provisions for monitoring `State` information.  `State` is similar to `Event`, but differ in that:

 - `State` handlers will be called immediately with the last known good value (if one is available)
 - `State` handlers will not be called if the state value is identical to the previous value
 - Whereas an `Event` has an associated `Message`, a `State` has an associated `Value`. 
 - A state's `Value` must conform to the Equatable protocol.


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

### Cocoapods

Add `Causality` to your Podfile:

```ruby
pod `Causality`
```

## Usage

## Events

### Just an event (no data)
The simplest event to manage has no associated data.

#### Declare Events

This declares an event called `aTriggerEvent` that has no associated data.

```swift
struct MyEvents {
    static let aTriggerEvent = Causality.Event<Causality.NoMessage>(label: "A Trigger")
}
```

#### Subscribe to events

To subscribe to this event:

```swift
let subscription = Causality.bus.subscribe(MyEvents.aTriggerEvent) { _ in
    print("Event was triggered")
}

```

#### Publish events

To publish/post an event of this type:

```swift
Causality.bus.publish(MyEvents.aTriggerEvent)
```

### An event with associated data

Events can include data of any type (referred to as a `Message`).  The event label is fully type specified with the message.  So a subscriber will have a fully typed message available to its handler.

#### Define the Message

A message can be a standard Swift type like `Int`, `String`, etc.  Or it can be a `struct` or `class` that conform to `Causality.Message`.  Take care as to whether you want value or reference semantics for messages.  Generally, value semantics (i.e. a `struct`) will be safer.  In this example, we'll declare a struct:

```swift
struct InterestingMessage: Causality.Message {
    let string: String
    let number: Int
}
```

#### Declare the event

Events may be declared with an associated `Message`.  If declared, the `Message` is a required typed parameter for publishing an event.  And similarly it will be supplied as a typed parameter to subscribers of the event.

Declaring an event with a message:

```swift
let MyInterestingEvent = Causality.Event<SomeMessage>(label: "Some Event")
let MyStringEvent = Causality.Event<String>(label: "An event with a String message")
let MyNumberEvent = Causality.Event<Int>(label: "An event with an Int message")
```

Or categorize your events:

```swift
struct MyEvents {
    static let MyInterestingEvent = Causality.Event<InterestingMessage>(label: "An interesting Event 1")
    static let MyStringEvent = Causality.Event<String>(label: "An event with a String message")
    static let MyNumberEvent = Causality.Event<Int>(label: "An event with an Int message")
}
```

#### Subscribing and Unsubscribing to the events

Save your subscriptions to unsubscribe later:

```swift
let subscription = Causality.bus.subscribe(MyEvents.MyInterestingEvent) { interestingMessage in
    print("A message from MyInterestingEvent: \(interestingMessage)")
}

Casaulity.bus.unsubscribe(subscription)
```

Or unsubscribe from within a subscription handler.  Here's an example of a one-shot event handler:

```swift
Causality.bus.subscribe(MyEvents.MyStringEvent) { subscription, string in
    print("A string from MyStringEvent: \(string)")
    
    subscription.unsubscribe()
}
```


#### Publish events

To publish/post an event:

```swift
Causality.bus.publish(MyEvents.MyInterestingEvent, 
    message: InterestingMessage(string: "Hello", number: 42))
```

#### Event Buses

### Bus Alias

Create aliases for your bus:

```swift
let eventBus = Causality.bus

eventBus.publish(MyEvents.MyInterestingEvent, 
    message: InterestingMessage(string: "Hello", number: 42))
```

### Local Buses

Or create local buses to isolate your events:

```swift
let newEventBus = Causality.Bus(label: "My local bus")

newEventBus.publish(MyEvents.interestingEvent, 
    message: InterestingMessage(string: "Hello", number: 42))
```



## State

#### Define the State Value

Similar to an `Event`, a `State` has an associated `Value`.  Values can be raw types such as `Int`, `String`, etc.  Or they may be `struct` or a `class`.  (Similar to a an event `Message`, you'll usually want to use a `struct`.)  However a `Value` must conform to `Equatable`. 


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
let playerState = Causality.State<PlayerInfo>(label: "Player State")
```

Or categorize your states:

```swift
struct GameStates {
    static let playerState1 = Causality.State<PlayerInfo>(label: "Player 1 State")
    static let playerState2 = Causality.State<PlayerInfo>(label: "Player 2 State")
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

Or unsubscribe from within a subscription handler.  This example will monitor only a single state change:

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

```swift
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

Causality.bus.set(state: GameState.playerState(1), 
                  value: PlayerInfo(
                            numberOfLines: 3,
                            health: 75,
                            armor: 100))

```

Similarly, you could use base types of `Int`, `String`, etc. for the `Value`.

```swift
let UserNameState = Causality.State<String>(label: "user name state")
Causality.bus.subscribe(UserNameState) { username in
    print("Username is now: \(username)")
}
Causality.bus.set(UserNameState, "Mary Jane Doe")
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
