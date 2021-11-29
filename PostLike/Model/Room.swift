//
//  Room.swift
//  postLike
//
//  Created by taichi on 2020/11/22.
//  Copyright © 2020 taichi. All rights reserved.
//

import Foundation
import FirebaseFirestore

class Room{
    
    let roomName:String
    let mediaArray:Array<String>
    let userImage:String
    let userName:String
    let text:String
    let documentID:String
    let createdAt:Timestamp
    let uid:String
    let comment:String
    var likeCount:Int
    let commentCount:Int
    let roomImage:String
    let numberOfMember:Int
    let roomID:String
    let roomIntro:String
    let moderator:String
    
    init(dic: [String:Any]) {
        
        self.roomName = dic["roomName"] as? String ?? ""
        self.mediaArray = dic["media"] as? Array ?? [""]
        self.userImage = dic["userImage"] as? String ?? ""
        self.userName = dic["userName"] as? String ?? ""
        self.text = dic["text"] as? String ?? ""
        self.documentID = dic["documentID"] as? String ?? ""
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
        self.uid = dic["uid"] as? String ?? ""
        self.comment = dic["comment"] as? String ?? ""
        self.likeCount = dic["likeCount"] as? Int ?? Int()
        self.commentCount = dic["commentCount"] as? Int ?? Int()
        self.roomImage = dic["roomImage"] as? String ?? ""
        self.numberOfMember = dic["memberCount"] as? Int ?? Int()
        self.roomID = dic["roomID"] as? String ?? ""
        self.roomIntro = dic["roomIntro"] as? String ?? ""
        self.moderator = dic["moderator"] as? String ?? ""
        
        
    }
}
