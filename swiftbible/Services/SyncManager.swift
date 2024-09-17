//
//  SyncManager.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/17/24.
//

import SwiftUI


enum PendingOperation {
    case create(Note)
    case update(Note)
    case delete(Note)
}

class SyncManager {
    static let shared = SyncManager()
    private var operationQueue: [PendingOperation] = []
    
    private init() {}
    
    func addOperation(_ operation: PendingOperation) {
        operationQueue.append(operation)
    }
    
    func processQueue() async {
        while !operationQueue.isEmpty {
            let operation = operationQueue.removeFirst()
            do {
                switch operation {
                case .create(let task):
                    break
                case .update(let task):
                    break
                case .delete(let task):
                    break
                }
            } catch {
                // Handle error, possibly re-queue
                print("Failed to process operation: \(error)")
                operationQueue.insert(operation, at: 0)
                break // Exit loop to retry later
            }
        }
    }
}

