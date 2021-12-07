//
//  InitialViewController.swift
//  PostLike
//
//  Created by taichi on 2021/08/26.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class InitialViewController: UIViewController {

    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var agreeTextView: UITextView!{
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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        createAccountButton.layer.cornerRadius = 28
        createAccountButton.layer.shadowColor = UIColor.black.cgColor
        createAccountButton.layer.shadowRadius = 4
        createAccountButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        createAccountButton.layer.shadowOpacity = 0.3
        
        loginButton.layer.cornerRadius = 30
        loginButton.layer.shadowColor = UIColor.black.cgColor
        loginButton.layer.shadowRadius = 4
        loginButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        loginButton.layer.shadowOpacity = 0.2
        
        if Auth.auth().currentUser?.isEmailVerified == false{
            let confirmVC = self.storyboard?.instantiateViewController(withIdentifier: "confirm") as! ComfirmEmailViewController
            self.navigationController?.pushViewController(confirmVC, animated: true)
        }
        
        
        
    }
    
    

    @IBAction func createAccount(_ sender: Any) {
        let registerVC = storyboard?.instantiateViewController(withIdentifier: "register") as! RegisterViewController
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
    @IBAction func login(_ sender: Any) {
        let loginVC = storyboard?.instantiateViewController(withIdentifier: "login") as! LoginViewController
        navigationController?.pushViewController(loginVC, animated: true)
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
