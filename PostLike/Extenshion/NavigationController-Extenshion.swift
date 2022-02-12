//
//  NavigationPush-Extenshion.swift
//  PostLike
//
//  Created by taichi on 2021/12/16.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func pushViewController(storyboardName:String,identifier:String){
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: identifier)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func setSwipeBackGesture() {
        let target = self.navigationController?.value(forKey: "_cachedInteractionController")
        let recognizer = UIPanGestureRecognizer(target: target, action: Selector(("handleNavigationTransition:")))
        self.view.addGestureRecognizer(recognizer)
    }
}


