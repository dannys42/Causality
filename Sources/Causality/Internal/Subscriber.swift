//
//  Subscriber.swift
//  
//
//  Created by Danny Sung on 09/20/2020.
//

import Foundation

protocol SubscriberId {
    var id: UUID { get }
}
internal struct Subscriber<Message: Causality.Message>: SubscriberId {
    let id = UUID()
    let event: Causality.Event<Message>
    let handler: (Message)->Void
}
