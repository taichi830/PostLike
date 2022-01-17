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
import AuthenticationServices
import CryptoKit

final class InitialViewController: UIViewController {

    
    @IBOutlet private weak var backView: UIView!
    
    @IBOutlet weak var registerWithAppleButton: UIButton!
    
    @IBOutlet private weak var createAccountButton: UIButton!
    
    @IBOutlet private weak var loginButton: UIButton!
    
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
    
    fileprivate var currentNonce: String?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        registerWithAppleButton.layer.cornerRadius = 27
        registerWithAppleButton.layer.shadowColor = UIColor.black.cgColor
        registerWithAppleButton.layer.shadowRadius = 4
        registerWithAppleButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        registerWithAppleButton.layer.shadowOpacity = 0.2
        
        createAccountButton.layer.cornerRadius = 27
        createAccountButton.layer.shadowColor = UIColor.black.cgColor
        createAccountButton.layer.shadowRadius = 4
        createAccountButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        createAccountButton.layer.shadowOpacity = 0.2
        
        loginButton.layer.cornerRadius = 27
        loginButton.layer.shadowColor = UIColor.black.cgColor
        loginButton.layer.shadowRadius = 4
        loginButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        loginButton.layer.shadowOpacity = 0.2
        
        
        
        
        if Auth.auth().currentUser?.isEmailVerified == false{
            let confirmVC = self.storyboard?.instantiateViewController(withIdentifier: "confirm") as! ComfirmEmailViewController
            self.navigationController?.pushViewController(confirmVC, animated: true)
        }
        
        
        
    }
    
    
    @IBAction func didTapRegisterWithAppleButton(_ sender: Any) {
        startSignInWithAppleFlow()
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


extension InitialViewController: ASAuthorizationControllerDelegate,ASAuthorizationControllerPresentationContextProviding {
    
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
      var result = ""
      var remainingLength = length

      while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
          var random: UInt8 = 0
          let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
          if errorCode != errSecSuccess {
            fatalError(
              "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
          }
          return random
        }

        randoms.forEach { random in
          if remainingLength == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }

      return result
    }
    
    
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }

    
    
    @available(iOS 13, *)
    private func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let window = UIApplication.shared.delegate?.window else {
                fatalError()
            }
            return window!
        }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    fatalError("Invalid state: A login callback was received, but no login request was sent.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    return
                }
                let credential = OAuthProvider.credential(
                    withProviderID: "apple.com",
                    idToken: idTokenString,
                    rawNonce: nonce
                )
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    print("成功!!!")
                    let storyBoard = UIStoryboard(name: "BaseTabBar", bundle: nil)
                    let vc = storyBoard.instantiateViewController(identifier: "baseTab") as! UITabBarController
                    vc.selectedIndex = 0
                    self.present(vc, animated: false, completion: nil)
                }
            }
        }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            print(error.localizedDescription)
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
