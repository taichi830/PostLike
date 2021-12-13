////  ComfirmingEmailViewController.swift
//  PostLike
//
//  Created by taichi on 2021/08/29.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

final class ComfirmEmailViewController: UIViewController {
    
    @IBOutlet private weak var adressLabel: UILabel!
    
    var passedGender = String()
    var passedBirthDay = String()
    var passedEmailAdress = String()
    var passedPassWord = String()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adressLabel.text = passedEmailAdress
    }
    
    
    
    @IBAction private func sendEmailAgain(_ sender: Any) {
        let actionCodeSettings = ActionCodeSettings() //メールリンクの作成方法をFirebaseに伝えるオブジェクト
        actionCodeSettings.handleCodeInApp = true //ログインをアプリ内で完結させる必要があります
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!) //iOSデバイス内でログインリンクを開くアプリのBundle ID
        //リンクURL
        var components = URLComponents()
        components.scheme = "https"
        #if DEBUG
        components.host = "postliketest.page.link"
        #else
        components.host = "postlike.page.link"
        #endif //Firebaseコンソールで作成したダイナミックリンクURLドメイン
        let queryItemEmailName = "email" //URLにemail情報(パラメータ)を追加する
        let emailTypeQueryItem = URLQueryItem(name: queryItemEmailName, value: passedPassWord)
        components.queryItems = [emailTypeQueryItem]
        guard let linkParameter = components.url else { return }
        actionCodeSettings.url = linkParameter
        
        Auth.auth().sendSignInLink(toEmail: passedPassWord, actionCodeSettings: actionCodeSettings) { err in
            if err != nil {
                return
            }else{
                let confirmVC = self.storyboard?.instantiateViewController(withIdentifier: "confirm") as! ComfirmEmailViewController
                UserDefaults.standard.set(self.passedPassWord, forKey: "email")
                UserDefaults.standard.set(self.passedGender, forKey: "gender")
                UserDefaults.standard.set(self.passedBirthDay, forKey: "birthDay")
                self.navigationController?.pushViewController(confirmVC, animated: true)
            }
        }
    }
    
    
    @IBAction private func changeEmailAdress(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
}
