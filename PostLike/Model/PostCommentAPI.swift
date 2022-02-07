//
//  PostCommentAPI.swift
//  PostLike
//
//  Created by taichi on 2022/02/07.
//  Copyright © 2022 taichi. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Firebase

protocol postComment {
    func postComment(userName:String,userImage:String,text:String,roomID:String,postID:String,documentID:String,roomName:String,passedUid:String,mediaArray:[String]) -> Single<Bool>
}

final class PostCommentAPI: postComment {
    
    func postComment(userName:String,userImage:String,text:String,roomID:String,postID:String,documentID:String,roomName:String,passedUid:String,mediaArray:[String]) -> Single<Bool> {
        return Single.create { [weak self] single in
            let batch = Firestore.firestore().batch()
            self?.createComment(userName: userName, userImage: userImage, text: text, roomID: roomID, postID: postID, documentID: documentID, batch: batch)
            self?.incrementCommentCount(passedUid: passedUid, roomID: roomID, documentID: documentID, mediaArray: mediaArray, batch: batch)
            self?.giveNotification(userName: userName, userImage: userImage, roomName: roomName, postID: postID, roomID: roomID, documentID: documentID, passedUid: passedUid, batch: batch)
            batch.commit { err in
                if let err = err {
                    single(.failure(err))
                }else{
                    single(.success(true))
                }
                
                
            }
               
            
            
            return Disposables.create()
        }
        
    }
    
    
    private func createComment(userName:String,userImage:String,text:String,roomID:String,postID:String,documentID:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let dic =  [
            "userName":userName,
            "userImage":userImage,
            "text":text,
            "createdAt":Timestamp(),
            "documentID":documentID,
            "roomID":roomID,
            "postID":postID,
            "uid":uid,
            "likeCount":0,
            "commentCount":0]
            as [String:Any]
        Firestore.createComment(uid: uid, roomID: roomID, documentID: documentID, dic: dic, batch: batch)
    }
    
    
    private func incrementCommentCount(passedUid:String,roomID:String,documentID:String,mediaArray:[String],batch:WriteBatch){
        Firestore.increaseCommentCount(uid: passedUid, roomID: roomID, documentID: documentID, batch: batch)
        if mediaArray[0] != "" {
            Firestore.increaseMediaPostCommentCount(roomID: roomID, documentID: documentID, batch: batch)
        }
    }
    
    
    
    private func giveNotification(userName:String,userImage:String,roomName:String,postID:String,roomID:String,documentID:String,passedUid:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let dic = [
            "userName":userName,
            "userImage":userImage,
            "uid":uid,
            "roomName":roomName,
            "createdAt":Timestamp(),
            "postID":postID,
            "roomID":roomID,
            "documentID":documentID,
            "type":"comment"] as [String:Any]
        Firestore.createNotification(uid: passedUid, myuid: uid, documentID: documentID, dic: dic, batch: batch)
    }
    
    
    
}
