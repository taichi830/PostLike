//
//  FirstViewController.swift
//  postLike
//
//  Created by taichi on 2021/05/18.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

final class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
            self.userCheck()
    }
    
    
    private func userCheck(){
    
        if Auth.auth().currentUser == nil {
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let registerVC = storyboard.instantiateViewController(withIdentifier: "register") as! RegisterViewController
            navigationController?.pushViewController(registerVC, animated: false)
        }else{
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let homeVC = storyboard.instantiateViewController(withIdentifier: "home") as! HomeViewController
            navigationController?.pushViewController(homeVC, animated: false)
            
        }
    }
    
    

   
    

}
