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
import AuthenticationServices
import CryptoKit
import RxSwift
import RxCocoa

final class LoginViewController: UIViewController{
    
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var doneButton: UIButton!
    @IBOutlet private weak var alertView: UILabel!
    @IBOutlet private weak var alertLabelHeight: NSLayoutConstraint!
    @IBOutlet private weak var eyeButton: UIButton!
    @IBOutlet weak var loginWithAppleButton: UIButton!
    @IBOutlet weak var loginMenuBackView: UIView!
    @IBOutlet weak var doneButtonBackView: UIView!
    @IBOutlet weak var buttonConstraint: NSLayoutConstraint!
    
    
    
    private let loginViewModel = LoginViewModel()
    private let disposeBag = DisposeBag()
    fileprivate var currentNonce: String?
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        eyeButton.tintColor = .lightGray
        alertView.layer.cornerRadius = 5
        doneButton.layer.cornerRadius = 20
        
        loginWithAppleButton.layer.cornerRadius = 27
        
        setupBinds()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    @objc private func keybordWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String:Any] else {
            return
        }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        guard let rect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        
        UIView.animate(withDuration: duration) {
            self.loginMenuBackView.isHidden = true
            self.doneButtonBackView.isHidden = false
            self.buttonConstraint.constant = rect.height
            self.view.layoutIfNeeded()
        }
    }
    
    
    @objc private func keybordWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String:Any] else {
            return
        }
        
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        UIView.animate(withDuration: duration) {
            self.loginMenuBackView.isHidden = false
            self.doneButtonBackView.isHidden = true
            self.buttonConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
        
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
        
        
        
        
        loginWithAppleButton.rx.tap
            .asDriver()
            .drive { [weak self] _ in
                self?.startSignInWithAppleFlow()
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
        Auth.login(email: emailTextField.text ?? "", password: passwordTextField.text ?? "") { bool, err in
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


extension LoginViewController:ASAuthorizationControllerDelegate,ASAuthorizationControllerPresentationContextProviding {
    
    
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
    func startSignInWithAppleFlow() {
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
    
    //ASAuthorizationControllerPresentationContextProviding
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let window = UIApplication.shared.delegate?.window else {
                fatalError()
            }
            return window!
        }
    
    //ASAuthorizationControllerDelegate
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
