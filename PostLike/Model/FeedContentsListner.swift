//
//  FeedContentsListner.swift
//  PostLike
//
//  Created by taichi on 2022/02/23.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa
import FirebaseFirestore

protocol FeedContentsListner {
    func fetchFeedContents(roomID: String) -> Observable<[Contents]>
}

final class FeedContentsDefaultListner: FeedContentsListner {
    private var listner: ListenerRegistration?
    func fetchFeedContents(roomID: String) -> Observable<[Contents]> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            self.listner = db.collectionGroup("posts").whereField("roomID", isEqualTo: roomID).order(by: "createdAt", descending: true).limit(to: 10).addSnapshotListener({ querySnapshot, err in
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
                observer.onNext(contents)
            })
            return Disposables.create {
                self.listner?.remove()
            }
        }
    }
    
    
    
}
