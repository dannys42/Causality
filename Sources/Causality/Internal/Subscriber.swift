//
//  Subscriber.swift
//  
//
//  Created by Danny Sung on 09/28/2020.
//

public protocol SubscriberId {
    var id: Causality.SubscriptionId { get }
}

public protocol AnySubscriber: SubscriberId, AnyObject {
    var state: Causality.SubscriptionState { get }

    func unsubscribe()
}

