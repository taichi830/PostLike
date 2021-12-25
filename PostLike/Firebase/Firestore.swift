//
//  Firestore.swift
//  PostLike
//
//  Created by taichi on 2021/12/18.
//  Copyright © 2021 taichi. All rights reserved.
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth

extension Firestore {
//MARK: Get
    //ルームの情報を取得
    static func fetchRoomInfo(roomID:String,completion: ((Room?) -> ())?) {
        Firestore.firestore().collection("rooms").document(roomID).getDocument{ (snapshot, err) in
            if let err = err {
                print("false\(err)")
                return
            }
            let dic = snapshot?.data()
            let roomInfo = Room(dic: dic ?? ["documentID":""])
            completion?(roomInfo)
        }
    }
    //自分がそのルームに参加しているかをチェック
    static func isJoinedCheck(roomID:String,completion: ((Contents?) -> ())?) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).getDocument { snapshot, err in
            if let err = err {
                print("情報の取得に失敗しました。\(err)")
                return
            }
            let dic = snapshot?.data()
            let joinedRoom = Contents(dic: dic ?? ["documentID":""])
            completion?(joinedRoom)
        }
    }
    //参加中のルームを取得
    static func fetchJoinedRooms(completion: @escaping ([Contents]) -> Void) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("rooms").whereField("isJoined", isEqualTo: true).order(by: "createdAt", descending: true).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("情報の取得に失敗しました。\(err)")
                return
            }
            let contents = querySnapshot?.documents.map({ snapshot -> Contents in
                let dic = snapshot.data()
                let content = Contents(dic: dic)
                return content
            })
            completion(contents ?? [Contents]())
        }
    }
    //報告した投稿を取得
    static func fetchReportedContents(documentIDs:[String],completion: @escaping ([Contents]) -> Void) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("reports").whereField("documentID", in: documentIDs).limit(to: 10).getDocuments { querySnapshot, err in
            if let err = err {
                print("false:",err)
                return
            }else{
                guard let querySnapshot = querySnapshot else {return}
                let contents = querySnapshot.documents.map { snapshot -> Contents in
                    let dic = snapshot.data()
                    let content = Contents(dic: dic)
                    return content
                }
                let filteredArray = contents.filter { content in
                    content.type == ReportType.post.rawValue
                }
                completion(filteredArray)
            }
        }
    }
    //報告したユーザーを取得
    static func fetchReportedUsers(uids:[String],completion: @escaping([Contents]) -> Void) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("reports").whereField("uid", in: uids).limit(to: 10).getDocuments { querySnapshot, err in
            if let err = err {
                print("false:",err)
                return
            }else{
                guard let querySnapshot = querySnapshot else {return}
                let contents = querySnapshot.documents.map { snapshot -> Contents in
                    let dic = snapshot.data()
                    let content = Contents(dic: dic)
                    return content
                }
                let filteredArray = contents.filter { content in
                    content.type == ReportType.user.rawValue
                }
                completion(filteredArray)
            }
        }
    }
    //いいねした投稿を取得
    static func fetchLikeContents(documentIDs:[String],completion: @escaping([Contents]) -> Void) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("likes").whereField("documentID", in: documentIDs).limit(to: 10).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("情報の取得に失敗しました。\(err)")
                return
            }
            guard let querySnapshot = querySnapshot else {return}
            let contents = querySnapshot.documents.map { snapshot -> Contents in
                let dic = snapshot.data()
                let content = Contents(dic: dic)
                return content
            }
            completion(contents)
        }
    }
    //履歴を取得
    static func fetchHistroy(completion: @escaping([Contents]) -> Void) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("history").order(by: "createdAt", descending: true).limit(to: 10).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("false\(err)")
                return
            }
            let contents = querySnapshot?.documents.map { document -> Contents in
                let dic = document.data()
                let content = Contents(dic: dic)
                return content
            }
            completion(contents ?? [Contents]())
        }
    }
    //ユーザーの基本情報を取得
    static func fetchUserInfo(completion: @escaping(User) -> Void){
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).getDocument { snapShot, err in
            if let err = err {
                print("false:",err)
                return
            }
            guard let snapShot = snapShot, let dic = snapShot.data() else {return}
            let userInfo = User(dic: dic)
            completion(userInfo)
        }
    }
    //ルームを人気順で取得
    static func fetchPopularRoom(completion: @escaping([Room]) -> Void){
        Firestore.firestore().collection("rooms").order(by: "memberCount", descending: true).limit(to: 10).getDocuments { querySnapshot, err in
            if err != nil {
                return
            }else{
                let contents = querySnapshot?.documents.map { document -> Room in
                    let dic = document.data()
                    let content = Room(dic: dic)
                    return content
                }
                completion(contents ?? [Room]())
            }
        }
    }
    //ルームを最新順で取得
    static func fetchLatestRoom(completion: @escaping([Room]) -> Void){
        Firestore.firestore().collection("rooms").order(by: "createdAt", descending: true).limit(to: 10).getDocuments { querySnapshot, err in
            if err != nil {
                return
            }else{
                let contents = querySnapshot?.documents.map { document -> Room in
                    let dic = document.data()
                    let content = Room(dic: dic)
                    return content
                }
                completion(contents ?? [Room]())
            }
        }
    }
    //feedsコレクションを取得
    static func fetchTimeLinePosts(completion: @escaping (QuerySnapshot,[Contents],_ uids:[String],_ documentIDs:[String]) -> Void) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("feeds").order(by: "createdAt", descending: true).limit(to: 10).getDocuments { querySnapshot, err in
            if let err = err{
                print(err)
                return
            }
            guard let querySnapshot = querySnapshot else {return}
            let contents = querySnapshot.documents.map { snapshot -> Contents in
                let dic = snapshot.data()
                let content = Contents(dic: dic)
                return content
            }
            let uids = contents.map { contents -> String in
                return contents.uid
            }
            let documentIDs = contents.map { contents -> String in
                return contents.documentID
            }
            completion(querySnapshot,contents,uids,documentIDs)
        }
    }
    //モデレーターの投稿を取得
    static func fetchModeratorPosts(documentIDs:[String],completion: @escaping([Contents]) -> Void) {
        Firestore.firestore().collectionGroup("posts").whereField("documentID", in: documentIDs).order(by: "createdAt", descending: true).getDocuments { querySnapshot, err in
            if let err = err {
                print("情報の取得に失敗しました。\(err)")
                return
            }
            guard let querySnapshot = querySnapshot else {return}
            let contents = querySnapshot.documents.map { snapshot -> Contents in
                let dic = snapshot.data()
                let content = Contents(dic: dic)
                return content
            }
            completion(contents)
            
        }
    }
    //feedsコレクションを追加で取得
    static func fetchMoreTimelinePosts(lastDocument:DocumentSnapshot,completion: @escaping(QuerySnapshot,[Contents],_ uids:[String],_ documentIDs:[String]) -> Void){
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("feeds").order(by: "createdAt", descending: true).start(afterDocument: lastDocument).limit(to: 10).getDocuments { (querySnapshot, err) in
            if let err = err{
                print(err)
                return
            }
            guard let querySnapshot = querySnapshot else {return}
            let contents = querySnapshot.documents.map { snapshot -> Contents in
                let dic = snapshot.data()
                let content = Contents(dic: dic)
                return content
            }
            let uids = contents.map { contents -> String in
                return contents.uid
            }
            let documentIDs = contents.map { contents -> String in
                return contents.documentID
            }
            completion(querySnapshot,contents,uids,documentIDs)
        }
    }
    //モデレーターの投稿を追加で取得
    static func fetchMoreModeratorPosts(documentIDs:[String],completion: @escaping([Contents]) -> Void) {
        Firestore.firestore().collectionGroup("posts").whereField("documentID", in: documentIDs).getDocuments { querySnapshot, err in
            if let err = err {
                print("情報の取得に失敗しました。\(err)")
                return
            }
            guard let querySnapshot = querySnapshot else {return}
            let contents = querySnapshot.documents.map { snapshot -> Contents in
                let dic = snapshot.data()
                let content = Contents(dic: dic)
                return content
            }
            completion(contents)
        }
    }
    //ルームの投稿を取得
    static func fetchRoomContents(roomID:String,viewController:UIViewController,completion: @escaping(QuerySnapshot,[Contents],_ uids:[String],_ documentIDs:[String]) -> Void) {
        Firestore.firestore().collectionGroup("posts").whereField("roomID", isEqualTo: roomID).order(by: "createdAt", descending: true).limit(to: 10).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("取得に失敗しました。\(err)")
                let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                viewController.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [okAction])
                return
            }
            guard let querySnapshot = querySnapshot else{return}
            let contents = querySnapshot.documents.map { snapshot -> Contents in
                let dic = snapshot.data()
                let content = Contents(dic: dic)
                return content
            }
            let uids = contents.map { contents -> String in
                return contents.uid
            }
            let documentIDs = contents.map { contents -> String in
                return contents.documentID
            }
            completion(querySnapshot,contents,uids,documentIDs)
        }
    }
    //ルームの投稿を追加で取得
    static func fetchMoreRoomContents(roomID:String,lastDocument:DocumentSnapshot,completion: @escaping(QuerySnapshot,[Contents],[String],[String]) -> Void) {
        Firestore.firestore().collectionGroup("posts").whereField("roomID", isEqualTo: roomID).order(by: "createdAt", descending: true).start(afterDocument: lastDocument).limit(to: 10).getDocuments { (querySnapshot, err) in
            if let err = err{
                print(err)
                return
            }
            guard let querySnapshot = querySnapshot else{return}
            let contents = querySnapshot.documents.map { snapshot -> Contents in
                let dic = snapshot.data()
                let content = Contents(dic: dic)
                return content
            }
            let uids = contents.map { contents -> String in
                return contents.uid
            }
            let documentIDs = contents.map { contents -> String in
                return contents.documentID
            }
            completion(querySnapshot, contents, uids, documentIDs)
        }
    }
    //写真投稿を取得
    static func fetchImageContents(roomID:String,completion: @escaping(QuerySnapshot,[Contents]) -> Void) {
        Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").order(by: "createdAt", descending:true).limit(to: 15).getDocuments {  (querySnapshot, err) in
            if let err = err {
                print("取得に失敗しました。\(err)")
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            let contents = querySnapshot.documents.map { document -> Contents in
                let dic = document.data()
                let content = Contents(dic: dic)
                return content
            }
            completion(querySnapshot,contents)
            
        }
    }
    //写真投稿を追加で取得
    static func fetchMoreImageContents(roomID:String,lastDocument:DocumentSnapshot,completion: @escaping(QuerySnapshot,[Contents]) -> Void) {
        Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").order(by: "createdAt", descending: true).start(afterDocument: lastDocument).limit(to: 15).getDocuments { querySnapshot, err in
            if let err = err {
                print("取得に失敗しました。\(err)")
                return
            }
            guard let querySnapshot = querySnapshot else { return }
            let contents = querySnapshot.documents.map { document -> Contents in
                let dic = document.data()
                let content = Contents(dic: dic)
                return content
            }
            completion(querySnapshot,contents)
        }
    }
    //ルームのメンバー数を取得
    static func fetchRoomMemberCount(roomID:String,completion: @escaping(Room) -> Void) {
        Firestore.firestore().collection("rooms").document(roomID).collection("memberCount").document("count").getDocument { snapShot, err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                guard let dic = snapShot?.data() else { return }
                let memberCount = Room(dic: dic)
                completion(memberCount)
            }
        }
    }
    //ルーム情報を更新
    static func updateRoomInfo(dic:[String:Any],roomID:String,batch:WriteBatch) {
        let uid = Auth.auth().currentUser!.uid
        let ref = Firestore.firestore().collection("rooms").document(roomID)
        let userRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID)
        batch.updateData(dic, forDocument: ref)
        batch.updateData(dic, forDocument: userRef)
    }
    //自分のプロフィールを取得
    static func fetchUserInfo(roomID:String,completion: @escaping(Contents) -> Void) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).getDocument { (snapshot, err) in
            if let err = err {
                print("情報の取得に失敗しました。\(err)")
                return
            }
            let dic = snapshot?.data()
            let userInfo = Contents(dic: dic ?? ["isJoined":false])
            completion(userInfo)
        }
    }
    //自分の投稿数を取得
    static func fetchPostCount(roomID:String,completion: @escaping(Contents) -> Void) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("profilePostCount").document("count").getDocument { snapShot, err in
            if let err = err {
                print("false\(err)")
                return
            }
            guard let snapShot = snapShot,let dic = snapShot.data() else {return}
            let postCount = Contents(dic: dic)
            completion(postCount)
        }
    }
    //自分のいいね数を取得
    static func fetchLikeCount(roomID:String,completion: @escaping(Contents) -> Void) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("profileLikeCount").document("count").getDocument { snapshot, err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                guard let snap = snapshot,let dic = snap.data() else {return}
                let likedCount = Contents(dic: dic)
                completion(likedCount)
            }
        }
    }
    //自分の投稿を取得
    static func fetchUserContents(roomID:String,completion: @escaping([Contents], QuerySnapshot) -> Void) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("posts").order(by: "createdAt", descending: true).limit(to: 5).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("取得に失敗しました。\(err)")
                return
            }
            guard let querySnapshot = querySnapshot else {return}
            let contents = querySnapshot.documents.map { snapshot -> Contents in
                let dic = snapshot.data()
                let content = Contents(dic: dic)
                return content
            }
            completion(contents,querySnapshot)
        }
    }
    //自分の投稿を追加で取得
    static func fetchMoreUserContents(roomID:String,lastDocument:DocumentSnapshot,completion: @escaping([Contents], QuerySnapshot) -> Void) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("posts").order(by: "createdAt", descending: true).start(afterDocument: lastDocument).limit(to: 5).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("取得に失敗しました。\(err)")
                return
            }
            guard let querySnapshot = querySnapshot else {return}
            let contents = querySnapshot.documents.map { snapshot -> Contents in
                let dic = snapshot.data()
                let content = Contents(dic: dic)
                return content
            }
            completion(contents, querySnapshot)
        }
    }
    //プロフィール情報を更新
    static func updateProfileInfo(dic:[String:Any],roomID:String,completion: @escaping(Bool) -> Void) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).setData(dic, merge: true){
            err in
            if let err = err {
                print("err:",err)
                completion(false)
            }else{
                completion(true)
            }
        }
    }
    //コメントを取得
    static func fetchComments(documentID:String,completion: @escaping([Contents]) -> Void) {
        Firestore.firestore().collectionGroup("comments").whereField("postID", isEqualTo: documentID).order(by: "createdAt", descending: true).getDocuments { (querySnapShot, err) in
            if let err = err {
                print("取得に失敗しました\(err)")
                return
            }
            let comments = querySnapShot?.documents.map{ snapshot -> Contents in
                let dic = snapshot.data()
                let comments = Contents(dic: dic)
                return comments
            }
            completion(comments ?? [Contents]())
        }
    }
    //お知らせを取得
    static func fetchNotifications(completion: @escaping([Contents]) -> Void) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("notifications").order(by: "createdAt", descending: true).limit(to: 10).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("情報の取得に失敗しました。\(err)")
                return
            }
            let notifications = querySnapshot?.documents.map({ document -> Contents in
                let dic = document.data()
                let notifications = Contents(dic: dic)
                return notifications
            })
            completion(notifications ?? [Contents]())
        }
    }

    
    
    
    
    
    

//MARK: Create
    //ユーザーを作成
    static func createUser(uid:String,dic:[String:Any],completion: @escaping(Bool,Error?) -> Void) {
        Firestore.firestore().collection("users").document(uid).setData(dic) { err in
            if let err = err {
                print("false:",err)
                completion(false,err)
            }else{
                completion(true,nil)
            }
        }
    }
    //ルームを作成
    static func createRoom(documentID:String,dic:[String:Any],batch:WriteBatch) {
        let ref = Firestore.firestore().collection("rooms").document(documentID)
        batch.setData(dic, forDocument: ref)
    }
    //プロフィールを作成
    static func createProfile(uid:String,documentID:String,dic:[String:Any],batch:WriteBatch) {
        let ref =  Firestore.firestore().collection("users").document(uid).collection("rooms").document(documentID)
        batch.setData(dic, forDocument: ref)
    }
    //メンバーカウントを作成
    static func createMemberCount(documentID:String,batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(documentID).collection("memberCount").document("count")
        batch.setData(["roomID":documentID,"memberCount": 1], forDocument: ref)
    }
    //投稿カウントを作成
    static func createPostCount(documentID:String,batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(documentID).collection("roomPostCount").document("count")
        batch.setData(["roomID":documentID,"postCount": 0], forDocument: ref)
    }
    //メンバーリストを作成
    static func createMemberList(documentID:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let ref = Firestore.firestore().collection("rooms").document(documentID).collection("members").document(uid)
        batch.setData(["uid":uid], forDocument: ref)
    }
    //投稿を保存
    static func createPost(roomID:String,documentID:String,media:Array<Any>,dic:[String:Any],batch:WriteBatch) {
        let uid = Auth.auth().currentUser!.uid
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("posts").document(documentID)
        batch.setData(dic, forDocument: ref)
    }
    //モデレーターの投稿を保存
    static func createModeratorPost(roomID:String,documentID:String,dic:[String:Any],batch:WriteBatch) {
        let ref = Firestore.firestore().collection("rooms").document(roomID).collection("moderatorPosts").document(documentID)
        batch.setData(dic, forDocument: ref)
    }
    //写真投稿を保存
    static func createcreateMediaPost(roomID:String,documentID:String,dic:[String:Any],batch:WriteBatch) {
        let ref = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
        batch.setData(dic, forDocument: ref)
    }
    //いいねした投稿を保存
    static func createLikedPost(myuid:String,documentID:String,dic:[String:Any],batch:WriteBatch) {
        let ref = Firestore.firestore().collection("users").document(myuid).collection("likes").document(documentID)
        batch.setData(dic, forDocument: ref, merge: true)
    }
    //いいねカウントを増やす
    static func increaseLikeCount(uid:String,myuid:String,roomID:String,documentID:String,mediaUrl:String,batch:WriteBatch) {
        let profileRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("posts").document(documentID)
        batch.setData(["likeCount": FieldValue.increment(1.0)], forDocument: profileRef, merge: true)
        
        let likedCountRef = Firestore.firestore().collection("users").document(myuid).collection("rooms").document(roomID).collection("profileLikeCount").document("count")
        batch.setData(["likeCount": FieldValue.increment(1.0)], forDocument: likedCountRef, merge: true)
        
        if mediaUrl != "" {
            let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
            batch.updateData(["likeCount":FieldValue.increment(1.0)], forDocument: mediaPostRef)
        }
    }
    //profilePostCountコレクションのカウントを増やす
    static func increaseProfilePostCount(uid:String,roomID:String,batch:WriteBatch) {
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("profilePostCount").document("count")
        batch.setData(["postCount": FieldValue.increment(1.0)], forDocument: ref, merge: true)
    }
    //roomPostCountコレクションのカウントを増やす
    static func increaseRoomPostCount(uid:String,roomID:String,batch:WriteBatch) {
        let ref = Firestore.firestore().collection("rooms").document(roomID).collection("roomPostCount").document("count")
        batch.setData(["postCount": FieldValue.increment(1.0)], forDocument: ref, merge: true)
    }
    //コメントを保存
    static func createComment(uid:String,roomID:String,documentID:String,dic:[String:Any],batch:WriteBatch) {
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("comments").document(documentID)
        batch.setData(dic, forDocument: ref)
    }
    //コメントカウントを増やす
    static func increaseCommentCount(uid:String,roomID:String,documentID:String,batch:WriteBatch) {
        let profileRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("posts").document(documentID)
        batch.setData(["commentCount": FieldValue.increment(1.0)], forDocument: profileRef, merge: true)
    }
    //写真投稿のコメントカウントを増やす
    static func increaseMediaPostCommentCount(roomID:String,documentID:String,batch:WriteBatch) {
        let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
        batch.updateData(["commentCount": FieldValue.increment(1.0)], forDocument: mediaPostRef)
    }
    //通知を作成
    static func createNotification(uid:String,myuid:String,documentID:String,dic:[String:Any],batch:WriteBatch) {
        let ref = Firestore.firestore().collection("users").document(uid).collection("notifications").document(documentID)
        if uid != myuid {
            batch.setData(dic, forDocument: ref, merge: true)
        }
        
    }
    //履歴を作成
    static func createHistory(documentID:String,dic:[String:Any]) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("history").document(documentID).setData(dic){
            (err) in
            if let err = err {
                print("firestoreへの保存に失敗しました。\(err)")
                return
            }
            print("fireStoreへの保存に成功しました。")
        }
    }
    
    
    
    
    
    
    
    
//MARK: Update
    //いいねカウントを減らす
    static func decreaseLikeCount(uid:String,myuid:String,roomID:String,documentID:String,mediaUrl:String,batch:WriteBatch) {
        let profileRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("posts").document(documentID)
        batch.updateData(["likeCount": FieldValue.increment(-1.0)], forDocument: profileRef)
        
        let likedCountRef = Firestore.firestore().collection("users").document(myuid).collection("rooms").document(roomID).collection("profileLikeCount").document("count")
        batch.updateData(["likeCount": FieldValue.increment(-1.0)], forDocument: likedCountRef)
        
        if mediaUrl != "" {
            let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
            batch.updateData(["likeCount":FieldValue.increment(-1.0)], forDocument: mediaPostRef)
        }
    }
    //ルームの投稿カウントを減らす
    static func decreaseRoomPostCount(roomID:String,batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(roomID).collection("roomPostCount").document("count")
        batch.updateData(["postCount": FieldValue.increment(-1.0)], forDocument: ref)
    }
    //プロフィールの投稿カウントを減らす
    static func decreasePostCount(roomID:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("profilePostCount").document("count")
        batch.updateData(["postCount": FieldValue.increment(-1.0)], forDocument: ref)
    }
    //ルーム退出処理
    static func exitRoom(documentID:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(documentID)
        batch.updateData(["isJoined":false], forDocument: ref)
    }
    //メンバーカウントを減らす
    static func decreaseMemberCount(documentID:String,batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(documentID).collection("memberCount").document("count")
        batch.updateData(["memberCount": FieldValue.increment(-1.0)], forDocument: ref)
    }
    
    
    
    
    
    
    
    
    
//MARK: Delete
    //写真投稿を削除
    static func deleteMediaPosts(roomID:String,documentID:String,batch:WriteBatch){
        let ref =  Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
        batch.deleteDocument(ref)
    }
    //投稿を削除
    static func deletePosts(roomID:String,documentID:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("posts").document(documentID)
        batch.deleteDocument(ref)
    }
    //モデレーターの投稿を削除
    static func deleteModeratorPosts(uid:String,moderatorUid:String,roomID:String,documentID:String,batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(roomID).collection("moderatorPosts").document(documentID)
        if uid == moderatorUid {
            batch.deleteDocument(ref)
        }
    }
    //履歴を削除
    static func deleteHistory(documentID:String,completion: @escaping() -> Void) {
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("history").document(documentID).delete { err in
            if let err = err {
                print("false\(err)")
                return
            }
            print("success")
            completion()
        }
    }
    //いいねした投稿を削除
    static func deleteLikedPost(uid:String,documentID:String,batch:WriteBatch) {
        let ref = Firestore.firestore().collection("users").document(uid).collection("likes").document(documentID)
        batch.deleteDocument(ref)
    }
    //通知を削除
    static func deleteNotification(uid:String,myuid:String,documentID:String,batch:WriteBatch) {
        let ref = Firestore.firestore().collection("users").document(uid).collection("notifications").document(documentID)
        if uid != myuid {
            batch.deleteDocument(ref)
        }
    }
    //メンバーリストからuidを削除
    static func deleteUidFromRoomMateList(documentID:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let ref = Firestore.firestore().collection("rooms").document(documentID).collection("members").document(uid)
        batch.deleteDocument(ref)
    }
    //ルームを削除
    static func deleteRoom(documentID:String,batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(documentID)
        batch.deleteDocument(ref)
    }
    //プロフィールを削除
    static func deleteMyprofile(documentID:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(documentID)
        batch.deleteDocument(ref)
    }
    //memberCountコレクションを削除
    static func deleteMemberCount(documentID:String,batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(documentID).collection("memberCount").document("count")
        batch.deleteDocument(ref)
    }
    //roomPostCountコレクションを削除
    static func deleteRoomPostCount(documentID:String,batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(documentID).collection("roomPostCount").document("count")
        batch.deleteDocument(ref)
    }
    

    
    
    
    
    
    
    
}



