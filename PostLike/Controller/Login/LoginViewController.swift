//
//  LoginViewController.swift
//  postLike
//
//  Created by taichi on 2020/09/27.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var alertView: UILabel!
    @IBOutlet weak var alertLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var eyeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        emailTextField.becomeFirstResponder()
        passwordTextField.delegate = self
        eyeButton.tintColor = .lightGray
        alertView.layer.cornerRadius = 5
        completeButton.layer.cornerRadius = 20
    }
    
    
    @IBAction func pushEyeButton(_ sender: Any) {
        
        if eyeButton.tintColor == .lightGray {
            passwordTextField.isSecureTextEntry = false
            eyeButton.setImage(UIImage(systemName: "eye"), for: .normal)
            eyeButton.tintColor = .link
        }else if eyeButton.tintColor == .link{
            passwordTextField.isSecureTextEntry = true
            eyeButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
            eyeButton.tintColor = .lightGray
        }
    }
    
    
    
    @IBAction func backButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    @IBAction func resetPassword(_ sender: Any) {
        let resetPasswordVC = storyboard?.instantiateViewController(withIdentifier: "resetPassword") as! ResetPasswordViewController
        navigationController?.pushViewController(resetPasswordVC, animated: true)
        
    }
    
    
    
    
    
    @IBAction func done(_ sender: Any) {
        startIndicator()
        self.view.endEditing(true)
        //ログイン
        Auth.auth().signIn(withEmail: emailTextField.text!, password:passwordTextField.text!) { (auth, err) in
            
            if let err = err {
                self.dismissIndicator()
                self.alertLabelHeight.constant = 42
                if let errMessage = AuthErrorCode(rawValue: err._code) {
                switch errMessage {
                case .invalidEmail:
                    print("メールアドレスの形式が違います")
                    self.alertView.text = "メールアドレスの形式が違います"
                    
                case .userNotFound:
                    print("アカウントが見つかりませんでした")
                    self.alertView.text = "アカウントが見つかりませんでした"
                case .weakPassword:
                    print("パスワードが弱いです")
                    self.alertView.text = "パスワードが弱いです"
                case .wrongPassword:
                    print("パスワードが違います")
                    self.alertView.text = "パスワードが違います"
                default:
                    print("エラーが発生しました")
                    self.alertView.text = "エラーが発生しました"
                }
                }
                self.alertView.isHidden = false
            }else{
                print("ログイン成功")
                let ref = Firestore.firestore().collection("users").document(auth!.user.uid)
                ref.getDocument { snapShot, err in
                    if err != nil {
                        return
                    }else{
                        guard let snap = snapShot,let dic = snap.data() else {
                            return
                        }
                        guard let fcmToken = UserDefaults.standard.value(forKey: "fcmToken") as? String else {
                            return
                        }
                        let user = User(dic: dic)
                        if user.fcmToken == fcmToken {
                            return
                        }else{
                            Firestore.firestore().collection("users").document(auth!.user.uid).setData(["fcmToken":fcmToken], merge: true)
                        }
                    }
                }
                let storyBoard = UIStoryboard(name: "BaseTabBar", bundle: nil)
                let vc = storyBoard.instantiateViewController(identifier: "baseTab") as! UITabBarController
                vc.selectedIndex = 0
                self.present(vc, animated: false, completion: nil)
                
            }
        }
    }
    
    
    
    
   
    
    
    
}




extension LoginViewController: UITextFieldDelegate{
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
         self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
        
    }
    
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if emailTextField.text != "" && passwordTextField.text != ""{
            completeButton.backgroundColor = .systemRed
            completeButton.isEnabled = true
        }else {
            completeButton.backgroundColor = .systemGray4
            completeButton.isEnabled = false
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.alertView.isHidden = true
        self.alertLabelHeight.constant = 0
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.alertView.isHidden = true
        self.alertLabelHeight.constant = 0
        return true
    }
    
    
    
}
