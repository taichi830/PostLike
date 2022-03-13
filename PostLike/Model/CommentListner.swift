//
//  CommentListner.swift
//  PostLike
//
//  Created by taichi on 2022/02/07.
//  Copyright © 2022 taichi. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Firebase
import FirebaseFirestore

protocol CommentListner {
    func fetchMyLatestComment(roomID: String) -> Observable<[Contents]>
    func fetchComments(documentID:String) -> Observable<[Contents]>
    func fetchMoreComments(documentID:String) -> Observable<[Contents]>
}

final class CommentDefaultListner: NSObject,CommentListner {
    private var listner: ListenerRegistration?
    func fetchMyLatestComment(roomID: String) -> Observable<[Contents]> {
        Observable.create { observer in
            let uid = Auth.auth().currentUser?.uid ?? ""
            let db = Firestore.firestore()
            self.listner = db.collection("users").document(uid).collection("rooms").document(roomID).collection("comments")
                .order(by: "createdAt", descending: true).limit(to: 1).addSnapshotListener { querySnapshot, err in
                    guard let querySnapshot = querySnapshot else { return }
                    if let err = err {
                        observer.onError(err)
                        return
                    }
                    let documents = querySnapshot.documents.map { snapshot -> Contents in
                        let dic = snapshot.data()
                        let content = Contents(dic: dic)
                        return content
                    }
                    observer.onNext(documents)
                }
            return Disposables.create {
                self.listner?.remove()
            }
        }
    }
    
    
    private var lastDocument: DocumentSnapshot?
    private let limit: Int = 10
    
    func fetchComments(documentID:String) -> Observable<[Contents]> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            db.collectionGroup("comments").whereField("postID", isEqualTo: documentID).order(by: "createdAt", descending: true).limit(to: self.limit).getDocuments { querySnapshot, err in
                guard let querySnapshot = querySnapshot else { return }
                let lastDocument = querySnapshot.documents.last
                self.lastDocument = lastDocument
                if let err = err {
                    observer.onError(err)
                    return
                }
                let documents = querySnapshot.documents.map { snapshot -> Contents in
                    let dic = snapshot.data()
                    let content = Contents(dic: dic)
                    return content
                }
                observer.onNext(documents)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    
    func fetchMoreComments(documentID: String) -> Observable<[Contents]> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            if let lastDocument = self.lastDocument {
                db.collectionGroup("comments").whereField("postID", isEqualTo: documentID).order(by: "createdAt", descending: true).start(afterDocument: lastDocument).limit(to: self.limit).getDocuments { querySnapshot, err in
                    guard let querySnapshot = querySnapshot else { return }
                    let lastDocument = querySnapshot.documents.last
                    self.lastDocument = lastDocument
                    if let err = err {
                        observer.onError(err)
                        return
                    }
                    let documents = querySnapshot.documents.map { snapshot -> Contents in
                        let dic = snapshot.data()
                        let content = Contents(dic: dic)
                        return content
                    }
                    observer.onNext(documents)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    
}
