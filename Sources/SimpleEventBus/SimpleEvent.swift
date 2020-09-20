//
//  SimpleEvent.swift
//  
//
//  Created by Danny Sung on 09/20/2020.
//

/// Define an event along with an associated message type
public struct SimpleEvent<Message: SimpleEventMessage> {
    /// `name` provides some context ont he purpose of the event.  It does not have to be unique.  However, events of the same "name" will not be called even if they have the same message type.
    public let name: String
}
