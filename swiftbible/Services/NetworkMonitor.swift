//
//  NetworkMonitor.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/17/24.
//

import SwiftUI
import Network

@Observable
class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    var isConnected: Bool = false
    
    private init() {
        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            if self.isConnected {
                Task {
                    await SyncManager.shared.processQueue()
                }
            }
        }
        monitor.start(queue: queue)
    }
}
