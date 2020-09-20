//
//  Event.swift
//  
//
//  Created by Danny Sung on 09/20/2020.
//

public extension Causality {
    /// Declare events to be used as endpoints for publish or subscribe calls.
    ///
    /// Example:
    /// ```
    /// static let SomeEvent = Causality.Event<Int>(name: "Some Event")
    /// ```
    /// This declares `SomeEvent` as an event that will require an `Int` on publish and will pass the same `Int` to the subscription handler.
    struct Event<Message: Causality.Message> {
        /// `name` provides some context ont he purpose of the event.  It does not have to be unique.  However, events of the same "name" will not be called even if they have the same message type.
        public let name: String
    }
}
