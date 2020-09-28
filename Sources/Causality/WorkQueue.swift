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

    init() {
        self = .none
    }
    init(_ queue: DispatchQueue?) {
        if let queue = queue {
            self = .dispatch(queue)
        } else {
            self = .none
        }
    }
    init(_ queue: OperationQueue?) {
        if let queue = queue {
            self = .operation(queue)
        } else {
            self = .none
        }
    }

    /// Return the current WorkQueue, unless it is .none.  If it is .none, return the passed queue instead.
    /// - Parameter queue: The queue to pass if the self == .none
    /// - Returns: `self` or `queue`
    func withDefault(_ queue: WorkQueue) -> WorkQueue {
        if self == .none {
            return queue
        }
        return self
    }
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
