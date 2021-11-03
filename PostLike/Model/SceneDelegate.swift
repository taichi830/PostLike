//
//  SceneDelegate.swift
//  postLike
//
//  Created by taichi on 2020/09/27.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDynamicLinks


class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let _ = (scene as? UIWindowScene) else { return }
        
        
        if Auth.auth().currentUser?.uid == nil  {
            let window = UIWindow(windowScene: scene as! UIWindowScene)
            self.window = window
            window.makeKeyAndVisible()
            
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let initialVC = storyboard.instantiateViewController(identifier: "initialVC")
            let navigation = UINavigationController(rootViewController: initialVC)
            navigation.navigationBar.isHidden = true
            window.rootViewController = navigation
        }else  {
            let window = UIWindow(windowScene: scene as! UIWindowScene)
            self.window = window
            window.makeKeyAndVisible()
            
            let storyboard = UIStoryboard(name: "BaseTabBar", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "baseTab") as! UITabBarController
            vc.selectedIndex = 0
            window.rootViewController = vc
        }
    }
    
    
    func handleIncomingDynamiclink(_ dynamiclink: DynamicLink,window: UIWindow){
        guard let url = dynamiclink.url else {
            return
        }
        guard (dynamiclink.matchType == .unique || dynamiclink.matchType == .default) else {
            return
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),let queryItems = components.queryItems else {
            return
        }
        if components.path == "/rooms" {
            if let queryItem = queryItems.first(where: { $0.name == "roomID"}){
                guard let roomID = queryItem.value else { return }
                let storyboard = UIStoryboard(name: "Search", bundle: nil)
                let roomDetailVC = storyboard.instantiateViewController(withIdentifier: "detailVC") as! RoomDetailViewController
                roomDetailVC.passedDocumentID = roomID
                let tabBarController = self.window?.rootViewController as? UITabBarController
                let nav = tabBarController?.selectedViewController as? UINavigationController
                nav?.pushViewController(roomDetailVC, animated: true)
            }
        }else{
            self.window = window
            window.makeKeyAndVisible()
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let initialVC = storyboard.instantiateViewController(identifier: "setPassWordVC")
            let navigation = UINavigationController(rootViewController: initialVC)
            navigation.navigationBar.isHidden = true
            window.rootViewController = navigation
        
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        
        guard let url = userActivity.webpageURL else {
            return
        }
        DynamicLinks.dynamicLinks().handleUniversalLink(url) { dynamicLink, err in
            if err != nil {
                return
            }else{
                guard let scene = (scene as? UIWindowScene) else { return }
                let window = UIWindow(windowScene: scene)
                self.handleIncomingDynamiclink(dynamicLink!, window: window)
            }
        }
        
//        guard let url = userActivity.webpageURL else { return }
//        let link = url.absoluteString
        

    }
    
    
    
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    
}

