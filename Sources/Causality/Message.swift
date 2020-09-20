//
//  Message.swift
//  
//
//  Created by Danny Sung on 09/20/2020.
//

public extension Causality {
    typealias Message = Any

    /// A message that can be included for events that have no associated data
    struct NoMessage: Message {
        public init() {
        }
    
        public static let message = NoMessage()
    }
}
