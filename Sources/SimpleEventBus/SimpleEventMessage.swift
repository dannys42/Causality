//
//  SimpleEventMessage.swift
//  
//
//  Created by Danny Sung on 09/20/2020.
//

//public protocol SimpleEventMessage {
//}
public typealias SimpleEventMessage = Any

/// A message that can be included for events that have no associated data
public struct NoSimpleEventMessage: SimpleEventMessage {
    public init() {
    }
    
    public static let message = NoSimpleEventMessage()
}
