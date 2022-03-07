//
//  CreateLikes.swift
//  PostLike
//
//  Created by taichi on 2022/02/25.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa
import Firebase
import FirebaseFirestore

protocol CreateLikes {
    func createLikes(content: Contents, userInfo: Contents) -> Observable<Contents>
    func deleteLikes(content: Contents, userInfo: Contents) -> Observable<Contents>
}

final class CreateDefaultLikes: CreateLikes {
    func deleteLikes(content: Contents, userInfo: Contents) -> Observable<Contents> {
        return Observable.create { [weak self] observer in
            let myuid = Auth.auth().currentUser?.uid ?? ""
            let batch = Firestore.firestore().batch()
            self?.deleteNotification(content: content, myuid: myuid, batch: batch)
            self?.deleteLikeContents(content: content, batch: batch)
            self?.deleteLikeCount(content: content, myuid: myuid, batch: batch)
            batch.commit { err in
                if let err = err {
                    print("err:", err)
                    observer.onError(err)
                    return
                }
                observer.onNext(content)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    
    
    func createLikes(content: Contents, userInfo: Contents) -> Observable<Contents> {
        return Observable.create { [weak self] observer in
            let myuid = Auth.auth().currentUser?.uid ?? ""
            let batch = Firestore.firestore().batch()
            self?.createLikeContents(content: content, myuid: myuid, batch: batch)
            self?.updateLikeCount(content: content, myuid: myuid, batch: batch)
            self?.giveNotification(content: content, myuid: myuid, userInfo: userInfo, batch: batch)
            batch.commit { err in
                if let err = err {
                    print("err:", err)
                    observer.onError(err)
                    return
                }
                observer.onNext(content)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    
    private func createLikeContents(content: Contents, myuid: String, batch: WriteBatch){
        let documentID = content.documentID
        let dic = [
            "media": content.mediaArray,
            "text": content.text,
            "userImage": content.userImage,
            "userName": content.userName,
            "documentID": content.documentID,
            "roomID": content.roomID,
            "createdAt": Timestamp(),
            "uid": content.uid,
            "postedAt": content.createdAt,
            "myUid": myuid
        ] as [String:Any]
        
        Firestore.createLikedPost(myuid: myuid, documentID: documentID, dic: dic, batch: batch)
    }
    
    
    
    private func updateLikeCount(content: Contents, myuid: String, batch: WriteBatch){
        let uid = content.uid
        let documentID = content.documentID
        let roomID = content.roomID
        let mediaArray = content.mediaArray[0]
        Firestore.increaseLikeCount(uid: uid, myuid: myuid, roomID: roomID, documentID: documentID, mediaUrl: mediaArray, batch: batch)
    }
    
    
    
    private func giveNotification(content: Contents, myuid: String, userInfo: Contents, batch:WriteBatch){
        let uid = content.uid
        let postID = content.documentID
        let documentID = "\(myuid)-\(postID)"
        let dic = [
            "userName": userInfo.userName,
            "userImage": userInfo.userImage,
            "uid": myuid,
            "roomName": userInfo.roomName,
            "createdAt": Timestamp(),
            "postID": postID,
            "roomID": content.roomID,
            "documentID": documentID,
            "type": "like"
        ] as [String:Any]
        Firestore.createNotification(uid: uid, myuid: myuid, documentID: documentID, dic: dic, batch: batch)
    }
    
    private func deleteLikeContents(content: Contents, batch: WriteBatch){
            let uid = Auth.auth().currentUser!.uid
            let documentID = content.documentID
            Firestore.deleteLikedPost(uid: uid, documentID: documentID, batch: batch)
        }
        
        
        
    private func deleteLikeCount(content: Contents, myuid: String, batch: WriteBatch){
            let uid = content.uid
            let documentID = content.documentID
            let roomID = content.roomID
            let mediaArray = content.mediaArray[0]
            Firestore.decreaseLikeCount(uid: uid, myuid: myuid, roomID: roomID, documentID: documentID, mediaUrl: mediaArray, batch: batch)
        }
    
    
    
        private func deleteNotification(content: Contents, myuid: String, batch: WriteBatch){
            let uid = content.uid
            let postID = content.documentID
            let documentID = "\(myuid)-\(postID)"
            Firestore.deleteNotification(uid: uid, myuid: myuid, documentID: documentID, batch: batch)
        }
    

    
    
    
    
}

