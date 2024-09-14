//
//  NavigationController.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/13/24.
//

import SwiftUI

extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}
