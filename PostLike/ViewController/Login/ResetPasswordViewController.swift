//
//  ResetPasswordViewController.swift
//  PostLike
//
//  Created by taichi on 2021/10/01.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

final class ResetPasswordViewController: UIViewController {
    
    
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.layer.cornerRadius = 20
        emailTextField.delegate = self
        self.setSwipeBackGesture()
    }
    
    
    @IBAction private func back(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction private func sendResetMail(_ sender: Any) {
        let email = emailTextField.text ?? ""
        Auth.resetPaaword(email: email) { bool in
            switch bool {
            case false:
                let alertAction = UIAlertAction(title: "OK", style: .default)
                self.showAlert(title: "メールの送信に失敗しました", message: "もう一度完了ボタンを押してください", actions: [alertAction])
            case true:
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.navigationController?.popViewController(animated: true)
                }
                self.showAlert(title: "メールを送信しました", message: "メールを確認してパスワードを再設定してください", actions: [alertAction])
            }
        }
    }
    

}

extension ResetPasswordViewController: UITextFieldDelegate{
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
         self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
        
    }
    
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if emailTextField.text != "" {
            doneButton.backgroundColor = .systemRed
            doneButton.isEnabled = true
        }else {
            doneButton.backgroundColor = .systemGray4
            doneButton.isEnabled = false
        }
    }
    
}
