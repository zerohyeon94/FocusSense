//
//  OrientationLock.swift
//  Orot
//
//  탭 화면은 세로로 고정하고, 세션(탁상시계)에서만 가로 회전을 허용합니다.
//  세션 중에는 기울기 센서로 방향을 직접 읽어, iPhone의 세로 화면 고정이 켜져 있어도 가로로 돌립니다.
//

import UIKit
import CoreMotion

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

    private static let motion = CMMotionManager()
    private static var current: UIInterfaceOrientation = .portrait

    static func allowLandscape(_ allowed: Bool) {
        mask = allowed ? .allButUpsideDown : .portrait
        current = .portrait
        updateSupportedOrientations()
        if allowed {
            startFollowingTilt()
        } else {
            motion.stopAccelerometerUpdates()
            requestOrientation(.portrait)
        }
    }

    private static func updateSupportedOrientations() {
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            var controller = scene.windows.first?.rootViewController
            while let viewController = controller {
                viewController.setNeedsUpdateOfSupportedInterfaceOrientations()
                controller = viewController.presentedViewController
            }
        }
    }

    private static func requestOrientation(_ orientation: UIInterfaceOrientation) {
        let target: UIInterfaceOrientationMask
        switch orientation {
        case .landscapeLeft: target = .landscapeLeft
        case .landscapeRight: target = .landscapeRight
        default: target = .portrait
        }
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: target))
        }
    }

    // MARK: - Tilt
    /// 중력 방향으로 세운 방향을 판단합니다. 눕혀 두었거나 애매한 각도에서는 그대로 둡니다.
    private static func startFollowingTilt() {
        guard motion.isAccelerometerAvailable, !motion.isAccelerometerActive else { return }
        motion.accelerometerUpdateInterval = 0.3
        motion.startAccelerometerUpdates(to: .main) { data, _ in
            guard let g = data?.acceleration else { return }
            let next: UIInterfaceOrientation?
            if g.x < -0.75 { next = .landscapeRight }
            else if g.x > 0.75 { next = .landscapeLeft }
            else if g.y < -0.75 { next = .portrait }
            else { next = nil }
            MainActor.assumeIsolated {
                guard let next, next != current else { return }
                current = next
                requestOrientation(next)
            }
        }
    }
}
