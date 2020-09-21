//
//  WorkQueue.swift
//  
//
//  Created by Danny Sung on 09/20/2020.
//

import Foundation

internal enum WorkQueue {
    case none
    case dispatch(DispatchQueue)
    case operation(OperationQueue)
}

extension WorkQueue {
    func execute(_ work: @escaping ()->Void) {
        switch self {
        case .none:
            work()
        case .dispatch(let q):
            q.async {
                work()
            }
        case .operation(let q):
            q.addOperation {
                work()
            }
        }
    }
}

extension WorkQueue: Equatable {
    static func ==(lhs: WorkQueue, rhs: WorkQueue) -> Bool {
        switch (lhs,rhs) {
        case (.none, .none):
            return true
        case (.dispatch(let q1), .dispatch(let q2)):
            // this is the only comparison available for Linux for DispatchQueue's
            return q1 === q2
        case (.operation(let q1), .operation(let q2)):
            return q1 == q2
        default:
            return false
        }
    }
}
