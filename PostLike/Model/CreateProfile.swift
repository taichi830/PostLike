//
//  CreateProfile.swift
//  PostLike
//
//  Created by taichi on 2022/03/02.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa
import FirebaseFirestore
import Firebase


protocol CreateProfileBatch {
    func createProfileWhenHaveCreated(roomInfo: Room) -> Observable<Bool>
    func createProfileWhenNoImage(roomInfo: Room, userName: String) -> Observable<Bool>
    func createProfile(roomInfo: Room, userName: String, userImage: UIImageView) -> Observable<Bool>
}

final class CreateProfile: CreateProfileBatch {
    //プロフィール画像がある場合の処理
    func createProfile(roomInfo: Room, userName: String, userImage: UIImageView) -> Observable<Bool> {
        return Observable.create { observer in
            let profileImage = userImage.image?.jpegData(compressionQuality: 0.1)
            let fileName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images").child(fileName)
            storageRef.putData(profileImage ?? Data(), metadata: nil) { (metadata, err) in
                if let err = err {
                    print("Firestorageへの保存に失敗しました。\(err)")
                    observer.onError(err)
                    return
                }
                storageRef.downloadURL { (url, err) in
                    if let err = err {
                        print("firestorageからのダウンロードに失敗しました。\(err)")
                        observer.onError(err)
                        return
                    }
                    guard let urlString = url?.absoluteString else{return}
                    let batch = Firestore.firestore().batch()
                    self.createProfile(roomInfo: roomInfo, userName: userName, userImageUrl: urlString, batch: batch)
                    self.increaseMemberCount(roomInfo: roomInfo, batch: batch)
                    self.createMemberList(roomInfo: roomInfo, batch: batch)
                    batch.commit { err in
                        if let err = err {
                            print("batchに失敗しました。:",err)
                            observer.onError(err)
                            return
                        }
                        observer.onNext(true)
                        observer.onCompleted()
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    
    
    
    //プロフィール画像がない場合の処理
    func createProfileWhenNoImage(roomInfo: Room, userName: String) -> Observable<Bool> {
        return Observable.create { observer in
            let batch = Firestore.firestore().batch()
            self.createProfile(roomInfo: roomInfo, userName: userName, userImageUrl: "", batch: batch)
            self.increaseMemberCount(roomInfo: roomInfo, batch: batch)
            self.createMemberList(roomInfo: roomInfo, batch: batch)
            batch.commit { err in
                if let err = err {
                    print("err:", err)
                    observer.onError(err)
                    return
                }
                observer.onNext(true)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    
    
    
    
    
    //参加したことあるルームに再び参加するときの処理
    func createProfileWhenHaveCreated(roomInfo: Room) -> Observable<Bool> {
        return Observable.create { observer in
            let batch = Firestore.firestore().batch()
            let uid = Auth.auth().currentUser!.uid
            let timestamp = Timestamp()
            let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomInfo.documentID)
            batch.updateData(["isJoined": true, "createdAt":timestamp, "roomName":roomInfo.roomName, "roomImage": roomInfo.roomImage], forDocument: ref)
            self.increaseMemberCount(roomInfo: roomInfo, batch: batch)
            self.createMemberList(roomInfo: roomInfo, batch: batch)
            batch.commit { err in
                if let err = err {
                    print("err:", err)
                    observer.onError(err)
                    return
                }
                observer.onNext(true)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    
    
    
    
    
    
    //メンバーズコレクションにuidを保存
    private func createMemberList(roomInfo: Room,batch: WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let docData = ["uid":uid]
        let ref =  Firestore.firestore().collection("rooms").document(roomInfo.documentID).collection("members").document(uid)
        batch.setData(docData, forDocument: ref)
    }
    
    
    //メンバーカウントをインクリメント
    private func increaseMemberCount(roomInfo: Room,batch: WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(roomInfo.documentID).collection("memberCount").document("count")
        batch.setData(["memberCount": FieldValue.increment(1.0)], forDocument: ref, merge: true)
    }
    
    
    //プロフィールを作成
    private func createProfile(roomInfo: Room, userName: String, userImageUrl: String, batch: WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let timestamp = Timestamp()
        let docData = ["createdAt": timestamp, "userName": userName, "userImage": userImageUrl, "documentID": roomInfo.documentID, "roomName": roomInfo.roomName, "roomImage": roomInfo.roomImage, "uid": uid, "moderator": roomInfo.moderator, "isJoined": true] as [String:Any]
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomInfo.documentID)
        batch.setData(docData, forDocument: ref)
    }
    
    
    
}
