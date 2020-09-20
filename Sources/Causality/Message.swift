//
//  Message.swift
//  
//
//  Created by Danny Sung on 09/20/2020.
//

public extension Causality {
    /// Custom types used as messages should conform to `Message`
    typealias Message = Any

    /// A convenience message that can be included for events that have no associated data
    struct NoMessage: Message {
        public init() {
        }
    
        public static let message = NoMessage()
    }
}
