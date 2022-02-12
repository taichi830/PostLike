//
//  SetPassWordViewController.swift
//  PostLike
//
//  Created by taichi on 2021/09/03.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

final class SetPassWordViewController: UIViewController {
    
    @IBOutlet private weak var passWordTextField: UITextField!
    @IBOutlet private weak var doneButton: UIButton!
    @IBOutlet private weak var alertLabel: UILabel!
    @IBOutlet private weak var alertLabelHeight: NSLayoutConstraint!
    @IBOutlet private weak var eyeButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        passWordTextField.delegate = self
        passWordTextField.becomeFirstResponder()
        doneButton.layer.cornerRadius = 20
        eyeButton.tintColor = .lightGray
        self.setSwipeBackGesture()
        
    }
    
    @IBAction private func pushEyeButton(_ sender: Any) {
        if eyeButton.tintColor == .lightGray {
            passWordTextField.isSecureTextEntry = false
            eyeButton.setImage(UIImage(systemName: "eye"), for: .normal)
            eyeButton.tintColor = .link
        }else if eyeButton.tintColor == .link{
            passWordTextField.isSecureTextEntry = true
            eyeButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
            eyeButton.tintColor = .lightGray
        }
    }
    
    
    @IBAction private func pushCompleteButton(_ sender: Any) {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {return}
        guard let password = passWordTextField.text else { return }
        guard let gender = UserDefaults.standard.value(forKey: "gender") as? String else {return}
        guard let birthDay = UserDefaults.standard.value(forKey: "birthDay") as? String else {return}
        guard let fcmToken = UserDefaults.standard.value(forKey: "fcmToken") as? String else {return}
        startIndicator()
        Auth.createUser(email: email, password: password, gender: gender, birthDay: birthDay, fcmToken: fcmToken) { bool, err in
            if let err = err {
                self.dismissIndicator()
                self.alertLabelHeight.constant = 42
                if let errMessage = AuthErrorCode(rawValue: err._code) {
                    switch errMessage {
                    case .emailAlreadyInUse:
                        print("すでにメールアドレスが使われています")
                        self.alertLabel.text = "すでにメールアドレスが使われています"
                        
                    case .weakPassword:
                        print("パスワードが弱いです")
                        self.alertLabel.text = "パスワードが弱いです"
                    
                    default:
                        print("エラーが発生しました")
                        self.alertLabel.text = "エラーが発生しました"
                    }
                }
                self.alertLabel.isHidden = false
            }else {
                print("ログイン成功")
                let storyBoard = UIStoryboard(name: "BaseTabBar", bundle: nil)
                let vc = storyBoard.instantiateViewController(identifier: "baseTab") as! UITabBarController
                vc.selectedIndex = 0
                self.present(vc, animated: false, completion: nil)
            }
        }
    }
    
    
    
    
    @IBAction private func toLoginVC(_ sender: Any) {
        let loginVC = storyboard?.instantiateViewController(withIdentifier: "login") as! LoginViewController
        self.navigationController?.pushViewController(loginVC, animated: true)
    }
    
    
    
}

extension SetPassWordViewController: UITextFieldDelegate{
    
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if  passWordTextField.text != ""{
            doneButton.backgroundColor = .systemRed
            doneButton.isEnabled = true
        }else {
            doneButton.backgroundColor = .systemGray4
            doneButton.isEnabled = false
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.alertLabel.isHidden = true
        self.alertLabelHeight.constant = 0
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.alertLabel.isHidden = true
        self.alertLabelHeight.constant = 0
        return true
    }
    
    
    
    
}

