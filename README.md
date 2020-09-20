<p align="center">
<img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
<img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
</p>

# SimpleEventBus
A very simple event bus for Swift.  Events may have associated data and are fully typed.

## Installation

### Swift Package Manager
Add the `SimpleEventBus` package to the dependencies within your application's `Package.swift` file.  Substitute "x.y.z" with the latest `SimpleEventBus` [release](https://github.com/dannys42/SimpleEventBus/releases).

```swift
.package(url: "https://github.com/dannys42/SimpleEventBus.git", from: "x.y.z")
```

Add `SimpleEventBus` to your target's dependencies:

```swift
.target(name: "example", dependencies: ["SimpleEventBus"]),
```

## Usage


### Just an event (no data)
The simplest event to manage has no associated data.

#### Declare Events

This declares an event called `aTriggerEvent` that has no associated data.

```swift
struct MyEvents {
    static let aTriggerEvent = SimpleEvent<NoSimpleEventMessage>(name: "A Trigger")
}
```

#### Subscribe to events

To subscribe to this event:

```swift
let subscription = SimpleEventBus.shared.subscribe(MyEvents.aTriggerEvent) { _ in
    print("Event happened")
}

```

#### Publish events

To publish/post an event of this type:

```swift
SimpleEventBus.shared.publish(MyEvents.aTriggerEvent)
```

### An event with associated data

Events can include data of any type (referred to as a "message").  The event label is fully type specified with the message.  So a subscriber will have a fully typed message available to its handler.

#### Define the Message

A message can be a standard Swift type like `Int`, `String`, etc.  Or it can be a `struct` or `class`.  In this example, we'll declare a struct:

```swift
struct InterestingMessage {
    let string: String
    let number: Int
}
```

#### Declare the event

```swift
struct MyEvents {
    static let interestingEvent = SimpleEvent<InterestingMessage>(name: "An interesting Event")
}
```

#### Subscribing to the event

```swift
let subscription = SimpleEventBus.shared.subscribe(MyEvents.interestingEvent) { message in
    print("A message from interestingEvent: \(message)")
}
```

#### Publish events

To publish/post an event of this type:

```swift
SimpleEventBus.shared.publish(MyEvents.interestingEvent, 
    message: InterestingMessage(string: "Hello", number: 42))
```

#### To unsubsrcibe from an event

```swift
SimpleEventBus.shared.unsubscribe(subscriptionId)
```
