//
//  Auth.swift
//  PostLike
//
//  Created by taichi on 2021/12/24.
//  Copyright © 2021 taichi. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

extension Auth {
    //確認メールを送る
    static func sendSignInLink(email:String,completion: @escaping (Bool) -> Void) {
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        //リンクURL
        var components = URLComponents()
        components.scheme = "https"
        #if DEBUG
        components.host = "postliketest.page.link"
        #else
        components.host = "postlike.page.link"
        #endif
        
        let queryItemEmailName = "email"
        let emailTypeQueryItem = URLQueryItem(name: queryItemEmailName, value: email)
        components.queryItems = [emailTypeQueryItem]
        guard let linkParameter = components.url else { return }
        actionCodeSettings.url = linkParameter
        
        Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings) { err in
            
            if let err = err {
                print("false\(err)")
                completion(false)
            }else{
                completion(true)
            }
        }
    }
    //ログイン処理
    static func login(email:String,password:String,completion: @escaping (Bool,Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { (auth, err) in
            if let err = err {
                completion(false,err)
            }else{
                Firestore.fetchUserInfo { userInfo in
                    guard let fcmToken = UserDefaults.standard.value(forKey: "fcmToken") as? String else { return }
                    if userInfo.fcmToken != fcmToken {
                        Firestore.createUser(uid: auth!.user.uid, dic: ["fcmToken":fcmToken]) { bool, err in
                            if let err = err {
                                print("false:",err)
                                completion(false,err)
                            }else{
                                completion(true,nil)
                            }
                        }
                    }else {
                        completion(true,nil)
                    }
                }
            }
        }
    }
    //ユーザーを作成
    static func createUser(email:String,password:String,gender:String,birthDay:String,fcmToken:String,completion: @escaping (Bool,Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { auth, err in
            if let err = err {
                print("false:",err)
                completion(false,err)
            }else{
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat  = "yyyy/MM/dd"
                dateFormatter.locale = Locale(identifier: "ja_JP")
                dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
                let date = dateFormatter.date(from: birthDay)
                let timestamp = Timestamp(date: date!)
                let dic = ["gender":gender,"birthDay":timestamp,"fcmToken":fcmToken] as [String:Any]
                Firestore.createUser(uid: auth!.user.uid, dic: dic) { bool, err in
                    if let err = err {
                        completion(false,err)
                    }else{
                        completion(true,nil)
                    }
                }
            }
        }
    }
    //パスワードをリセット
    static func resetPaaword(email:String,completion: @escaping (Bool) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { err in
            if let err = err {
                print("false:",err)
                completion(false)
            }else{
                completion(true)
            }
        }
    }
    
    
    
    
    
}

