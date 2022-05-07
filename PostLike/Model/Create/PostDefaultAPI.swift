//
//  StorageObservable.swift
//  PostLike
//
//  Created by taichi on 2022/01/25.
//  Copyright © 2022 taichi. All rights reserved.
//

import Foundation
import Firebase
import RxSwift

protocol PostAPI {
    func post(userName:String,userImage:String,text:String,passedUid:String,roomID:String,imageArray:[UIImage]) -> Observable<Bool>
}

final class PostDefaultAPI: PostAPI {
    
    func post(userName:String,userImage:String,text:String,passedUid:String,roomID:String,imageArray:[UIImage]) -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            
            let batch = Firestore.firestore().batch()

            if imageArray.isEmpty {
                self?.createPostWhenNoImages(userName: userName, userImage: userImage, text: text, passedUid: passedUid, roomID: roomID, media: [""], batch: batch)
                batch.commit { err in
                    if let err = err {
                        observer.onError(err)
                    }else{
                        observer.onNext(true)
                        observer.onCompleted()
                    }
                }
            }else {
                Storage.addPostImagesToStrage(imagesArray: imageArray) { bool, urls in
                    switch bool {
                    case false:
                        print("Storageへ保存が失敗しました")
                        return
                    case true:
                        self?.postBatch(userName: userName, userImage: userImage, text: text, passedUid: passedUid, roomID: roomID, media: urls, batch: batch)
                        batch.commit { err in
                            if let err = err {
                                observer.onError(err)
                            }else{
                                observer.onNext(true)
                                observer.onCompleted()
                            }
                        }
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    
    
    
    
    
    
    private func createPost(passedUserName:String,passedUserImageUrl:String,documentID:String,passedUid:String,roomID:String,media:Array<Any>,text:String,uid:String,batch:WriteBatch) {
        let dic = [
            "userName":passedUserName,
            "userImage":passedUserImageUrl,
            "media": media,
            "text":text,
            "createdAt":Timestamp(),
            "uid":uid,
            "documentID":documentID,
            "roomID":roomID,
            "likeCount":0,
            "commentCount":0
        ] as [String:Any]
        Firestore.createPost(roomID: roomID, documentID: documentID, media: media, dic: dic, batch: batch)
    }
    
    
    private func createModeratorPosts(uid:String,documentID:String,roomID:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let dic = [
            "createdAt":Timestamp(),
            "uid":uid,
            "roomID":roomID,
            "documentID":documentID
        ] as [String : Any]
        Firestore.createModeratorPost(roomID: roomID, documentID: documentID, dic: dic, batch: batch)
    }
    
    
    //クエリの制限で写真のみを作成順で取得できないため写真を別コレクションで保存
    private func createMediaPosts(roomID:String,userName:String,userImage:String,text:String,uid:String,documentID:String,media:Array<Any>,batch:WriteBatch){
        let dic = [
            "media":media,
            "createdAt":Timestamp(),
            "uid":uid,
            "roomID":roomID,
            "documentID":documentID,
            "userName":userName,
            "userImage":userImage,
            "likeCount":0,
            "commentCount":0,
            "text":text] as [String : Any]
        Firestore.createcreateMediaPost(roomID: roomID, documentID: documentID, dic: dic, batch: batch)
    }
    
    
    
    private func createPostWhenNoImages(userName:String,userImage:String,text:String,passedUid:String,roomID:String,media:Array<Any>,batch:WriteBatch){
        
        let documentID = NSUUID().uuidString
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if passedUid == uid {
            createModeratorPosts(uid: uid, documentID: documentID, roomID: roomID, batch: batch)
            createPost(passedUserName: userName, passedUserImageUrl: userImage, documentID: documentID, passedUid: passedUid, roomID: roomID, media: media, text: text, uid: uid, batch: batch)
            Firestore.increaseRoomPostCount(uid: uid, roomID: roomID, batch: batch)
            Firestore.increaseProfilePostCount(uid: uid, roomID: roomID, batch: batch)
        }else{
            createPost(passedUserName: userName, passedUserImageUrl: userImage, documentID: documentID, passedUid: passedUid, roomID: roomID, media: media, text: text, uid: uid, batch: batch)
            Firestore.increaseRoomPostCount(uid: uid, roomID: roomID, batch: batch)
            Firestore.increaseProfilePostCount(uid: uid, roomID: roomID, batch: batch)
        }
    }
    
    
    
    
    private func postBatch(userName:String,userImage:String,text:String,passedUid:String,roomID:String,media:Array<Any>,batch:WriteBatch) {
        let documentID = NSUUID().uuidString
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if passedUid == uid {
            createMediaPosts(roomID: roomID, userName: userName, userImage: userImage, text: text, uid: uid, documentID: documentID, media: media, batch: batch)
            createPost(passedUserName: userName, passedUserImageUrl: userImage, documentID: documentID, passedUid: passedUid, roomID: roomID, media: media, text: text, uid: uid, batch: batch)
            createModeratorPosts(uid: uid, documentID: documentID, roomID: roomID, batch: batch)
            Firestore.increaseRoomPostCount(uid: uid, roomID: roomID, batch: batch)
            Firestore.increaseProfilePostCount(uid: uid, roomID: roomID, batch: batch)
        }else{
            createMediaPosts(roomID: roomID, userName: userName, userImage: userImage, text: text, uid: uid, documentID: documentID, media: media, batch: batch)
            createPost(passedUserName: userName, passedUserImageUrl: userImage, documentID: documentID, passedUid: passedUid, roomID: roomID, media: media, text: text, uid: uid, batch: batch)
            Firestore.increaseRoomPostCount(uid: uid, roomID: roomID, batch: batch)
            Firestore.increaseProfilePostCount(uid: uid, roomID: roomID, batch: batch)
        }
    }
    
    
    
    
    
    
    
}
