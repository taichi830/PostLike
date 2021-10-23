//
//  ShowIndicator.swift
//  PostLike
//
//  Created by taichi on 2021/09/12.
//  Copyright © 2021 taichi. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController{
    func startIndicator(){
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.center = self.view.center
        indicator.startAnimating()
        
        
        if self.tabBarController?.view == nil {
            indicator.color = .white
            let backView = UIView(frame: self.view.frame)
            backView.tag = 999999
            backView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
            backView.addSubview(indicator)
            self.view.addSubview(backView)
        }else{
            indicator.color = .lightGray
            let clearView = UIView(frame: self.view.frame)
            clearView.tag = 999999
            clearView.backgroundColor = .clear
            clearView.addSubview(indicator)
            self.view.addSubview(clearView)
        }
       
    }
    
    
    func dismissIndicator(){
        self.view.subviews.last(where: {$0.tag == 999999})?.removeFromSuperview()
    }
}
