//
//  User.swift
//  postLike
//
//  Created by taichi on 2020/10/16.
//  Copyright © 2020 taichi. All rights reserved.
//

import Foundation
import FirebaseFirestore

final class User{
    
    let birthDay:Timestamp
    let fcmToken:String
    let gender:String
    
    init(dic: [String:Any]) {
        self.birthDay = dic["birthDay"] as? Timestamp ?? Timestamp()
        self.fcmToken = dic["fcmToken"] as? String ?? ""
        self.gender = dic["gender"] as? String ?? ""
    }
    
}
