//
//  OrientationLock.swift
//  Orot
//
//  탭 화면은 세로로 고정하고, 세션(탁상시계)에서만 가로 회전을 허용합니다.
//

import UIKit

// MARK: - App Delegate
final class OrotAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        OrientationLock.mask
    }
}

// MARK: - Orientation Lock
@MainActor
enum OrientationLock {
    static var mask: UIInterfaceOrientationMask = .portrait

    static func allowLandscape(_ allowed: Bool) {
        mask = allowed ? .allButUpsideDown : .portrait
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            var controller = scene.windows.first?.rootViewController
            while let current = controller {
                current.setNeedsUpdateOfSupportedInterfaceOrientations()
                controller = current.presentedViewController
            }
            if !allowed {
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
    }
}
