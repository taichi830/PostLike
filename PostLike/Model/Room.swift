//
//  Room.swift
//  postLike
//
//  Created by taichi on 2020/11/22.
//  Copyright © 2020 taichi. All rights reserved.
//

import Foundation
import FirebaseFirestore

final class Room{
    
    let roomName:String
    let documentID:String
    let roomImage:String
    let numberOfMember:Int
    let roomID:String
    let roomIntro:String
    let moderator:String
    
    init(dic: [String:Any]) {
        
        self.roomName = dic["roomName"] as? String ?? ""
        self.documentID = dic["documentID"] as? String ?? ""
        self.roomImage = dic["roomImage"] as? String ?? ""
        self.numberOfMember = dic["memberCount"] as? Int ?? Int()
        self.roomID = dic["roomID"] as? String ?? ""
        self.roomIntro = dic["roomIntro"] as? String ?? ""
        self.moderator = dic["moderator"] as? String ?? ""
        
        
    }
}
