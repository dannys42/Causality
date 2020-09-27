<p align="center">
<a href="https://github.com/dannys42/Causality/actions?query=workflow%3ASwift"><img src="https://github.com/dannys42/Causality/workflows/Swift/badge.svg" alt="build status"></a>
<img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
<img src="https://img.shields.io/badge/os-iOS-green.svg?style=flat" alt="iOS">
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
<a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2"></a>

</p>

# Causality
A very simple event bus for Swift.  Events may have associated data and are fully typed.  All publish/subscribe methods are thread-safe.

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
