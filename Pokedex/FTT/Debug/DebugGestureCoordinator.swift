//
//  DebugGestureCoordinator.swift
//  Pokedex
//
//  Created by GitHub Copilot on 14/02/26.
//

#if DEBUG
import UIKit

/// Global coordinator that attaches an "L"-shaped pan gesture to the window
/// and presents the `FeatureFlagsDebugViewController` from the topmost controller.
final class DebugGestureCoordinator: NSObject {

    private enum Stage {
        case idle
        case vertical
        case horizontal
    }

    private weak var window: UIWindow?
    private var stage: Stage = .idle
    private var startPoint: CGPoint = .zero

    init(window: UIWindow) {
        self.window = window
        super.init()
        configureGesture(on: window)
    }

    private func configureGesture(on window: UIWindow) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.cancelsTouchesInView = false
        window.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let view = recognizer.view else { return }
        let location = recognizer.location(in: view)

        switch recognizer.state {
            case .began:
                startPoint = location
                stage = .vertical

            case .changed:
                let dx = location.x - startPoint.x
                let dy = location.y - startPoint.y

                switch stage {
                    case .vertical:
                        if dy > 80, abs(dy) > abs(dx) {
                            stage = .horizontal
                            startPoint = location
                        }
                    case .horizontal:
                        if dx > 80, abs(dx) > abs(dy) {
                            stage = .idle
                            presentDebugMenu()
                            recognizer.isEnabled = false
                            recognizer.isEnabled = true
                        }
                    case .idle:
                        break
                }

            default:
                stage = .idle
        }
    }

    private func presentDebugMenu() {
        guard let root = window?.rootViewController else { return }
        let top = DebugGestureCoordinator.topViewController(from: root)

        // Avoid stacking multiple debug menus.
        if top is UINavigationController,
           (top as? UINavigationController)?.viewControllers.first is FeatureFlagsDebugViewController {
            return
        }

        let debugVC = FeatureFlagsDebugViewController()
        let nav = UINavigationController(rootViewController: debugVC)
        nav.modalPresentationStyle = .formSheet
        top.present(nav, animated: true)
    }

    private static func topViewController(from root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = root as? UINavigationController { return nav.visibleViewController.map { topViewController(from: $0) } ?? nav }
        if let tab = root as? UITabBarController { return tab.selectedViewController.map { topViewController(from: $0) } ?? tab }
        return root
    }
}

#endif
