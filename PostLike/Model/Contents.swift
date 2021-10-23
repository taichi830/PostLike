//
//  Contents.swift
//  postLike
//
//  Created by taichi on 2020/10/03.
//  Copyright © 2020 taichi. All rights reserved.
//

import Foundation
import FirebaseFirestore

class Contents{
    
    
    let mediaArray:Array<String>
    let text:String
    let roomName:String
    let roomImage:String
    let userImage:String
    let userName:String
    let createdAt:Timestamp
    var likeCount:Int
    let commentCount:Int
    let documentID:String
    let moderator:String
    let roomIntro:String
    let numberOfMember:Int
    let postCount:Int
    let isJoined:Bool
    let category:String
    let roomID:String
    let uid:String
    

   
    
    init(dic: [String:Any]){
        
        self.text = dic["text"] as? String ?? ""
        self.mediaArray = dic["media"] as? Array ?? [""]
        self.roomName = dic["roomName"] as? String ?? ""
        self.roomImage = dic["roomImage"] as? String ?? ""
        self.userImage = dic["userImage"] as? String ?? ""
        self.userName = dic["userName"] as? String ?? ""
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
        self.likeCount = dic["likeCount"] as? Int ?? Int()
        self.documentID = dic["documentID"] as? String ?? ""
        self.moderator = dic["moderator"] as? String ?? ""
        self.roomIntro = dic["roomIntro"] as? String ?? ""
        self.numberOfMember = dic["memberCount"] as? Int ?? Int()
        self.commentCount = dic["commentCount"] as? Int ?? Int()
        self.postCount = dic["postCount"] as? Int ?? Int()
        self.isJoined = dic["isJoined"] as? Bool ?? false
        self.category = dic["category"] as? String ?? ""
        self.roomID = dic["roomID"] as? String ?? ""
        self.uid = dic["uid"] as? String ?? ""
    }
    
   
    
  

  
    
    
}
