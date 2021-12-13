//
//  LoginViewController.swift
//  postLike
//
//  Created by taichi on 2020/09/27.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import RxSwift
import RxCocoa

final class LoginViewController: UIViewController {
    
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var doneButton: UIButton!
    @IBOutlet private weak var alertView: UILabel!
    @IBOutlet private weak var alertLabelHeight: NSLayoutConstraint!
    @IBOutlet private weak var eyeButton: UIButton!
    
    private let loginViewModel = LoginViewModel()
    private let disposeBag = DisposeBag()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        emailTextField.becomeFirstResponder()
        eyeButton.tintColor = .lightGray
        alertView.layer.cornerRadius = 5
        doneButton.layer.cornerRadius = 20
        
        setupBinds()
    }
    
    
    @IBAction private func pushEyeButton(_ sender: Any) {
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
    
    
    
    @IBAction private func backButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    @IBAction private func resetPassword(_ sender: Any) {
        let resetPasswordVC = storyboard?.instantiateViewController(withIdentifier: "resetPassword") as! ResetPasswordViewController
        navigationController?.pushViewController(resetPasswordVC, animated: true)
        
    }
    
    
    
    private func setupBinds(){
        
        emailTextField.rx.text
            .asDriver()
            .drive { [weak self] text in
                self?.loginViewModel.emailTextInPut
                    .onNext(text ?? "")
            }
            .disposed(by: disposeBag)
        
        passwordTextField.rx.text
            .asDriver()
            .drive { [weak self] text in
                self?.loginViewModel.passWordTextInPut
                    .onNext(text ?? "")
            }
            .disposed(by: disposeBag)
        
        loginViewModel.validLoginDriver
            .drive { [weak self] validAll in
                self?.doneButton.isEnabled = validAll
                self?.doneButton.backgroundColor = validAll ? .red : .systemGray4
            }
            .disposed(by: disposeBag)
        
        
        
        
        
        doneButton.rx.tap
            .asDriver()
            .drive { [weak self] _ in
                self?.login()
            }
            .disposed(by: disposeBag)
        
    }
    
    
    
    
    
    private func login() {
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
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    
}
