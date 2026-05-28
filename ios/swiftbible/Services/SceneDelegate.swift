import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    let urlHandler = URLHandler()

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let context = URLContexts.first else { return }
        Task { @MainActor in
            urlHandler.handle(url: context.url)
        }
    }
}
