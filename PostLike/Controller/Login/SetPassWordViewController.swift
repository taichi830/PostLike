//
//  SetPassWordViewController.swift
//  PostLike
//
//  Created by taichi on 2021/09/03.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import Firebase

class SetPassWordViewController: UIViewController {
    
    @IBOutlet weak var passWordTextField: UITextField!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var alertLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var eyeButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        passWordTextField.delegate = self
        passWordTextField.becomeFirstResponder()
        completeButton.layer.cornerRadius = 20
        eyeButton.tintColor = .lightGray
        
    }
    
    @IBAction func pushEyeButton(_ sender: Any) {
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
    
    
    @IBAction func pushCompleteButton(_ sender: Any) {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        guard let gender = UserDefaults.standard.value(forKey: "gender") as? String else {return}
        guard let birthDay = UserDefaults.standard.value(forKey: "birthDay") as? String else{return}
        guard let fcmToken = UserDefaults.standard.value(forKey: "fcmToken") as? String else {
            return
        }
        startIndicator()
        
        Auth.auth().createUser(withEmail: email, password: passWordTextField.text!) { auth, err in
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
            }else{
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat  = "yyyy/MM/dd"
                dateFormatter.locale = Locale(identifier: "ja_JP")
                dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
                let date = dateFormatter.date(from: birthDay)
                let timestamp = Timestamp(date: date!)
                let data = ["gender":gender,"birthDay":timestamp,"fcmToken":fcmToken] as [String:Any]
                Firestore.firestore().collection("users").document(auth!.user.uid).setData(data) { err in
                    if err != nil {
                        let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                            self.dismissIndicator()
                        }
                        self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                        return
                    }else{
                        print("ログイン成功")
                        let storyBoard = UIStoryboard(name: "BaseTabBar", bundle: nil)
                        let vc = storyBoard.instantiateViewController(identifier: "baseTab") as! UITabBarController
                        vc.selectedIndex = 0
                        self.present(vc, animated: false, completion: nil)
                    }
                }
                
            }
        }
    }
    
    
    
    
    @IBAction func toLoginVC(_ sender: Any) {
        let loginVC = storyboard?.instantiateViewController(withIdentifier: "login") as! LoginViewController
        self.navigationController?.pushViewController(loginVC, animated: true)
    }
    
    
    
}

extension SetPassWordViewController: UITextFieldDelegate{
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        self.view.endEditing(true)
    }
    
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if  passWordTextField.text != ""{
            completeButton.backgroundColor = .systemRed
            completeButton.isEnabled = true
        }else {
            completeButton.backgroundColor = .systemGray4
            completeButton.isEnabled = false
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
    
//    @objc func keybordWillShow(_ notification: Notification) {
//        guard let userInfo = notification.userInfo as? [String:Any] else {
//            return
//        }
//        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
//            return
//        }
//        guard let rect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
//            return
//        }
//        UIView.animate(withDuration: duration) {
//            self.completeButton.frame.origin.y = rect.origin.y - 50
//        }
//    }
    
    
//    @objc func keybordWillHide(_ notification: Notification) {
//        self.buttonView.frame.origin.y = self.view.frame.size.height - (self.buttonView.frame.size.height+self.view.safeAreaInsets.bottom)
//    }
    
    
    
}

