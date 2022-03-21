//
//  GetProfilePosts.swift
//  PostLike
//
//  Created by taichi on 2022/03/02.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import FirebaseFirestore

protocol GetProfilePosts {
    func fetchProfilePosts(uid: String, roomID: String) -> Observable<[Contents]>
    func fetchMoreProfilePosts(uid: String, roomID: String) -> Observable<[Contents]>
}

final class GetDefaultProfilePosts: GetProfilePosts {
    
    
    private var lastDocument: DocumentSnapshot?
    func fetchProfilePosts(uid: String, roomID: String) -> Observable<[Contents]> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            db.collection("users").document(uid).collection("rooms").document(roomID).collection("posts").order(by: "createdAt", descending: true).limit(to: 10).getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("取得に失敗しました。\(err)")
                    observer.onError(err)
                    return
                }
                print("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
                guard let querySnapshot = querySnapshot else {return}
                let lastDocument = querySnapshot.documents.last
                self.lastDocument = lastDocument
                let documents = querySnapshot.documents.map { snapshot -> Contents in
                    let dic = snapshot.data()
                    let content = Contents(dic: dic)
                    return content
                }
                observer.onNext(documents)
            }
            return Disposables.create()
        }
    }
    
    
    func fetchMoreProfilePosts(uid: String, roomID: String) -> Observable<[Contents]> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            if let lastDocument = self.lastDocument {
                db.collection("users").document(uid).collection("rooms").document(roomID).collection("posts").order(by: "createdAt", descending: true).start(afterDocument: lastDocument).limit(to: 10).getDocuments { (querySnapshot, err) in
                    if let err = err {
                        print("取得に失敗しました。\(err)")
                        observer.onError(err)
                        return
                    }
                    guard let querySnapshot = querySnapshot else { return }
                    let lastDocument = querySnapshot.documents.last
                    self.lastDocument = lastDocument
                    let documents = querySnapshot.documents.map { snapshot -> Contents in
                        let dic = snapshot.data()
                        let content = Contents(dic: dic)
                        return content
                    }
                    observer.onNext(documents)
                }
            }
            
            return Disposables.create()
        }
    }
    
    
    
    
    
}

