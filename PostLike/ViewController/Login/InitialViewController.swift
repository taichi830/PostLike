//
//  InitialViewController.swift
//  PostLike
//
//  Created by taichi on 2021/08/26.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import GoogleSignIn

final class InitialViewController: UIViewController, UIGestureRecognizerDelegate {
    
    
    @IBOutlet private weak var backView: UIView!
    
    @IBOutlet weak var signUpWithAppleButton: CustomSignUpButton! {
        didSet {
            signUpWithAppleButton.configure(title: "Appleで登録", image: UIImage(named: "apple"))
        }
    }
    
    @IBOutlet weak var signUpWithGoogleButton: CustomSignUpButton! {
        didSet {
            signUpWithGoogleButton.configure(title: "Googleで登録", image: UIImage(named: "google"))
        }
    }
    
    @IBOutlet private weak var signUpWithEmailButton: CustomSignUpButton! {
        didSet {
            signUpWithEmailButton.configure(title: "メールアドレスで登録", image: UIImage(named: "mail"))
        }
    }
    
    @IBOutlet private weak var loginButton: CustomSignUpButton! {
        didSet {
            loginButton.configure(title: "ログイン", image: UIImage())
        }
    }
    
    @IBOutlet private weak var agreeTextView: UITextView!{
        didSet{
            agreeTextView.isScrollEnabled = false
            agreeTextView.isEditable = false
            agreeTextView.isSelectable = true
            agreeTextView.delegate = self
            let text = "アカウントを作成することで、利用規約とプライバシーポリシーに同意したことになります。"
            let paragraph = NSMutableParagraphStyle()
            let attributedString = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.paragraphStyle: paragraph])
            attributedString.addAttribute(.link, value: "TermOfUseLink", range: NSString(string: text).range(of: "利用規約"))
            attributedString.addAttribute(.link, value: "PrivacyPolicy", range: NSString(string: text).range(of: "プライバシーポリシー"))
            
            let stringAttributes: [NSAttributedString.Key : Any] = [
                .foregroundColor : UIColor.red,
                .font : UIFont.systemFont(ofSize: 14, weight: .regular),
                .underlineStyle:NSUnderlineStyle.single.rawValue
            ]
            attributedString.addAttributes(stringAttributes, range: NSString(string: text).range(of: "利用規約"))
            attributedString.addAttributes(stringAttributes, range: NSString(string: text).range(of: "プライバシーポリシー"))
            agreeTextView.attributedText = attributedString
        }
    }
    
    private let signUpWithAppleVC = SignUpWithAppleViewController()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        if Auth.auth().currentUser?.isEmailVerified == false{
            let confirmVC = self.storyboard?.instantiateViewController(withIdentifier: "confirm") as! ComfirmEmailViewController
            self.navigationController?.pushViewController(confirmVC, animated: true)
        }
    }
    
    
    
    @IBAction func didTapRegisterWithGoogleButton(_ sender: Any) {
        signUpWithGoogle()
    }
    
    
    @IBAction func didTapRegisterWithAppleButton(_ sender: Any) {
        signUpWithAppleVC.vc = self
        signUpWithAppleVC.startSignInWithAppleFlow()
    }
    
    
    
    @IBAction private func createAccount(_ sender: Any) {
        let registerVC = storyboard?.instantiateViewController(withIdentifier: "register") as! RegisterViewController
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
    @IBAction private func login(_ sender: Any) {
        let loginVC = storyboard?.instantiateViewController(withIdentifier: "login") as! LoginViewController
        navigationController?.pushViewController(loginVC, animated: true)
    }
    
    
}





//SignUpWithGoogle
extension InitialViewController {
    private func signUpWithGoogle() {
        guard let fcmToken = UserDefaults.standard.value(forKey: "fcmToken") as? String else {return}
        self.startIndicator()
        Auth.signInWithGoogle(vc: self, fcmToken: fcmToken) { [weak self] err in
            if let err = err {
                print("err:",err)
                self?.dismissIndicator()
                return
            }
            print("成功!!!")
            self?.dismissIndicator()
            let storyBoard = UIStoryboard(name: "BaseTabBar", bundle: nil)
            let vc = storyBoard.instantiateViewController(identifier: "baseTab") as! UITabBarController
            vc.selectedIndex = 0
            self?.present(vc, animated: false, completion: nil)
        }
    }
}



extension InitialViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let urlString = URL.absoluteString
        if urlString == "TermOfUseLink" {
            let viewController = self.storyboard!.instantiateViewController(withIdentifier: "termOfUse")
            self.navigationController?.pushViewController(viewController, animated: true)
            return false
        }else if urlString == "PrivacyPolicy" {
            let viewController = self.storyboard!.instantiateViewController(withIdentifier: "privacyPolicy")
            self.navigationController?.pushViewController(viewController, animated: true)
            return false
        }
        return true
    }
}
