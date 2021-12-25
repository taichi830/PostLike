////  ComfirmingEmailViewController.swift
//  PostLike
//
//  Created by taichi on 2021/08/29.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

final class ComfirmEmailViewController: UIViewController {
    
    @IBOutlet private weak var adressLabel: UILabel!
    
    var passedGender = String()
    var passedBirthDay = String()
    var passedEmailAdress = String()
    var passedPassWord = String()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adressLabel.text = passedEmailAdress
    }
    
    
    
    @IBAction private func sendEmailAgain(_ sender: Any) {
        Auth.sendSignInLink(email: passedEmailAdress) { bool in
            switch bool {
            case false:
                let alertAction = UIAlertAction(title: "OK", style: .default)
                self.showAlert(title: "メールの送信に失敗しました", message: "もう一度送信してください", actions: [alertAction])
            case true:
                let alertAction = UIAlertAction(title: "OK", style: .default)
                self.showAlert(title: "メールを送信しました", message: "メールを確認してパスワードを設定してください", actions: [alertAction])
            }
        }
    }
    
    
    @IBAction private func changeEmailAdress(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
}
