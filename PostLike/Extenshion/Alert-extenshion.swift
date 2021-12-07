//
//  AlertController.swift
//  postLike
//
//  Created by taichi on 2021/07/18.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showAlert(title:String,message:String,actions:[UIAlertAction]){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alert.addAction($0) }
        present(alert, animated: true)
    }
}
