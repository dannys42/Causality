//
//  Subscriber.swift
//  
//
//  Created by Danny Sung on 09/20/2020.
//

import Foundation

public protocol SubscriberId {
    var id: Causality.SubscriptionId { get }
}

public protocol AnySubscriber: SubscriberId, AnyObject {
    var state: Causality.SubscriptionState { get }
    func unsubscribe()
}


internal class Subscriber<Message: Causality.Message>: AnySubscriber {
    typealias SubscriptionHandler = (AnySubscriber, Message)->Void

    let id: Causality.SubscriptionId
    let bus: Causality.Bus
    let event: Causality.Event<Message>
    let handler: SubscriptionHandler
    let workQueue: WorkQueue
    var state: Causality.SubscriptionState

    init(bus: Causality.Bus, event: Causality.Event<Message>, handler: @escaping SubscriptionHandler, workQueue: WorkQueue) {
        self.id = UUID()
        self.bus = bus
        self.event = event
        self.handler = handler
        self.workQueue = workQueue
        self.state = .continue
    }

    public func unsubscribe() {
        self.bus.unsubscribe(self)
    }
}
