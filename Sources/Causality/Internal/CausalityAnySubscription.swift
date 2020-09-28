//
//  CausalityAnySubscription.swift
//  
//
//  Created by Danny Sung on 09/28/2020.
//

/// All Subscriptions conform to this protocol
public protocol CausalityAnySubscription: AnyObject {
    var id: Causality.SubscriptionId { get }
    var subscriptionState: Causality.SubscriptionState { get }

    func unsubscribe()
}

