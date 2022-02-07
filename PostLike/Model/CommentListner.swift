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

protocol CommentListner {
    func createListner(documentID:String) -> Observable<[Contents]>
}

final class CommentDefaultListner: NSObject,CommentListner {
    private var listner: ListenerRegistration?
    
    internal func createListner(documentID:String) -> Observable<[Contents]> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            
            self.listner = db.collectionGroup("comments").whereField("postID", isEqualTo: documentID).order(by: "createdAt", descending: true).addSnapshotListener({ querySnapshot, err in
                guard let querySnapshot = querySnapshot else { fatalError("querySnapshot is nil") }
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
            })
            return Disposables.create {
                self.listner?.remove()
            }
        }
        
        
    }
    
    
}
