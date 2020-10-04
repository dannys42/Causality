//
//  CausalityAnySubscription.swift
//  
//
//  Created by Danny Sung on 09/28/2020.
//

/// All Subscriptions conform to this protocol
public protocol CausalityAnySubscription: AnyObject {
    /// A unique for the subscription
    var id: Causality.SubscriptionId { get }

    /// The current state of the subscription
    var status: Causality.SubscriptionStatus { get }

    /// The handler for this subscription will no longer be called after an `unsubscribe()
    func unsubscribe()
}
