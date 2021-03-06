//
//  FeedContentsListner.swift
//  PostLike
//
//  Created by taichi on 2022/02/23.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa
import FirebaseAuth
import FirebaseFirestore

protocol GetPosts {
    func fetchMyLatestPost(roomID: String) -> Observable<Contents>
    func fetchMoreModeratorFeeds() -> Observable<[Contents]>
    func fetchModeratorFeeds() -> Observable<[Contents]>
    func fetchModeratorPosts(contents: [Contents]) -> Observable<[Contents]>
    func fetchPosts(roomID: String) -> Observable<[Contents]>
    func fetchMorePosts(roomID: String) -> Observable<[Contents]>
}

final class GetDefaultPosts: GetPosts {
    
    private let limit:Int = 10
    
    
    func fetchMyLatestPost(roomID: String) -> Observable<Contents> {
        return Observable.create { observer in
            let uid = Auth.auth().currentUser?.uid ?? ""
            let db = Firestore.firestore()
            db.collection("users").document(uid).collection("rooms").document(roomID).collection("posts").order(by: "createdAt", descending: true).limit(to: 1).getDocuments { querySnapshot, err in
                if let err = err {
                    observer.onError(err)
                    return
                }
                guard let querySnapshot = querySnapshot else { return }
                let contents = querySnapshot.documents.map { snapshot -> Contents in
                    let dic = snapshot.data()
                    let contents = Contents(dic: dic)
                    return contents
                }
                observer.onNext(contents[0])
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    
    private var lastDocument: DocumentSnapshot?
    func fetchPosts(roomID: String) -> Observable<[Contents]> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            db.collectionGroup("posts").whereField("roomID", isEqualTo: roomID).order(by: "createdAt", descending: true).limit(to: self.limit).getDocuments{ querySnapshot, err in
                if let err = err {
                    observer.onError(err)
                    return
                }
                guard let querySnapshot = querySnapshot else { return }
                let lastDocument = querySnapshot.documents.last
                let contents = querySnapshot.documents.map { snapshot -> Contents in
                    let dic = snapshot.data()
                    let contents = Contents(dic: dic)
                    return contents
                }
                self.lastDocument = lastDocument
                observer.onNext(contents)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    
    func fetchMorePosts(roomID: String) -> Observable<[Contents]> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            if let lastDocument = self.lastDocument {
                db.collectionGroup("posts").whereField("roomID", isEqualTo: roomID).order(by: "createdAt", descending: true).start(afterDocument: lastDocument).limit(to: self.limit).getDocuments { (querySnapshot, err) in
                    if let err = err{
                        print("err:", err)
                        observer.onError(err)
                        return
                    }
                    guard let querySnapshot = querySnapshot else { return }
                    let lastDocument = querySnapshot.documents.last
                    let contents = querySnapshot.documents.map { snapshot -> Contents in
                        let dic = snapshot.data()
                        let content = Contents(dic: dic)
                        return content
                    }
                    self.lastDocument = lastDocument
                    observer.onNext(contents)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    
    


    
    
    private var lastModeratorDocument: DocumentSnapshot?
    func fetchModeratorFeeds() -> Observable<[Contents]> {
        return Observable.create { observer in
            let uid = Auth.auth().currentUser?.uid ?? ""
            let db = Firestore.firestore()
            db.collection("users").document(uid).collection("feeds").order(by: "createdAt", descending: true).limit(to: self.limit).getDocuments { querySnapshot, err in
                if let err = err {
                    print("err:", err)
                    observer.onError(err)
                    return
                }
                guard let querySnapshot = querySnapshot else { return }
                let lastDocument = querySnapshot.documents.last
                let documents = querySnapshot.documents.map { snapshot -> Contents in
                    let dic = snapshot.data()
                    let contents = Contents(dic: dic)
                    return contents
                }
                self.lastModeratorDocument = lastDocument
                observer.onNext(documents)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    
    
    
    func fetchMoreModeratorFeeds() -> Observable<[Contents]> {
        return Observable.create { observer in
            let uid = Auth.auth().currentUser?.uid ?? ""
            let db = Firestore.firestore()
            if let lastDocument = self.lastModeratorDocument {
                db.collection("users").document(uid).collection("feeds").order(by: "createdAt", descending: true).start(afterDocument: lastDocument).limit(to: self.limit).getDocuments { querySnapshot, err in
                    if let err = err {
                        print("err:", err)
                        observer.onError(err)
                        return
                    }
                    guard let querySnapshot = querySnapshot else { return }
                    let lastDocument = querySnapshot.documents.last
                    let documents = querySnapshot.documents.map { snapShot -> Contents in
                        let dic = snapShot.data()
                        let contents = Contents(dic: dic)
                        return contents
                    }
                    self.lastModeratorDocument = lastDocument
                    observer.onNext(documents)
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    
    
    
    
    func fetchModeratorPosts(contents: [Contents]) -> Observable<[Contents]> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            let documentIDs = contents.map {
                $0.documentID
            }
            db.collectionGroup("posts").whereField("documentID", in: documentIDs).order(by: "createdAt", descending: true).limit(to: self.limit).getDocuments { querySnapshot, err in
                if let err = err {
                    print("情報の取得に失敗しました。\(err)")
                    return
                }
                guard let querySnapshot = querySnapshot else {return}
                let contents = querySnapshot.documents.map { snapshot -> Contents in
                    let dic = snapshot.data()
                    let contents = Contents(dic: dic)
                    return contents
                }
                observer.onNext(contents)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    
}
    
    
    
    
    
    
    
    
