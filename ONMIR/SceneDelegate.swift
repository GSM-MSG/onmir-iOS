//
//  SceneDelegate.swift
//  ONMIR
//
//  Created by 정윤서 on 4/20/25.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScence = (scene as? UIWindowScene) else { return }
    window = UIWindow(windowScene: windowScence)
    window?.rootViewController = UINavigationController(rootViewController: UIViewController())
    window?.makeKeyAndVisible()
  }

  func sceneDidDisconnect(_ scene: UIScene) {}

  func sceneDidBecomeActive(_ scene: UIScene) {}

  func sceneWillResignActive(_ scene: UIScene) {}

  func sceneWillEnterForeground(_ scene: UIScene) {}

  func sceneDidEnterBackground(_ scene: UIScene) {}
}
