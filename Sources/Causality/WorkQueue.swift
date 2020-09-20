//
//  WorkQueue.swift
//  
//
//  Created by Danny Sung on 09/20/2020.
//

import Foundation

internal enum WorkQueue: Equatable {
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
