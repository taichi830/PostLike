//
//  NavigationPush-Extenshion.swift
//  PostLike
//
//  Created by taichi on 2021/12/16.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

extension UIViewController {
    //アラートを共通化
    func showAlert(title:String,message:String,actions:[UIAlertAction]){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alert.addAction($0) }
        present(alert, animated: true)
    }
    //indicatorを共通化
    func startIndicator(){
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.center = self.view.center
        indicator.startAnimating()
        indicator.color = .lightGray
        let clearView = UIView(frame: self.view.frame)
        clearView.tag = 999999
        clearView.backgroundColor = .clear
        clearView.addSubview(indicator)
        self.view.addSubview(clearView)
    }
    //indicatorをdismiss
    func dismissIndicator(){
        self.view.subviews.last(where: {$0.tag == 999999})?.removeFromSuperview()
    }
    //pushViewControllerを共通化
    func pushViewController(storyboardName:String,identifier:String){
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: identifier)
        navigationController?.pushViewController(vc, animated: true)
    }
    //navigationControllerのPanGestureをview全体に設置
    func setSwipeBackGesture() {
        let target = self.navigationController?.value(forKey: "_cachedInteractionController")
        let recognizer = UIPanGestureRecognizer(target: target, action: Selector(("handleNavigationTransition:")))
        self.view.addGestureRecognizer(recognizer)
    }
}


