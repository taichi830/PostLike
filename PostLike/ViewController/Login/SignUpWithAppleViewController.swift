//
//  SignUpWithAppleViewController.swift
//  PostLike
//
//  Created by taichi on 2022/01/20.
//  Copyright © 2022 taichi. All rights reserved.
//

import UIKit
import Firebase
import AuthenticationServices
import CryptoKit

final class SignUpWithAppleViewController:NSObject,ASAuthorizationControllerDelegate,ASAuthorizationControllerPresentationContextProviding {
    
    fileprivate var currentNonce: String?
    var vc = UIViewController()
    
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
                guard let fcmToken = UserDefaults.standard.value(forKey: "fcmToken") as? String else {return}
                self.vc.startIndicator()
                Auth.signInWithApple(credential: credential, fcmToken: fcmToken) { bool, err in
                    if let err = err {
                        print("err:",err)
                        return
                    }
                    print("成功!!!")
                    self.vc.dismissIndicator()
                    let storyBoard = UIStoryboard(name: "BaseTabBar", bundle: nil)
                    let vc = storyBoard.instantiateViewController(identifier: "baseTab") as! UITabBarController
                    vc.selectedIndex = 0
                    self.vc.present(vc, animated: false, completion: nil)
                }
            }
        }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            print(error.localizedDescription)
        }
    
    
}
