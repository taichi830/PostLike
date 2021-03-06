//
//  LikeListner.swift
//  PostLike
//
//  Created by taichi on 2022/02/23.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa
import FirebaseFirestore
import FirebaseAuth

protocol GetLikes {
    func fetchLikes(contents: [Contents]) -> Observable<[Contents]>
}

final class GetDefaultLikes: GetLikes {
    func fetchLikes(contents: [Contents]) -> Observable<[Contents]> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            let uid = Auth.auth().currentUser!.uid
            let documentIDs = contents.map { Contents -> String in
                return Contents.documentID
            }
            db.collection("users").document(uid).collection("likes").whereField("documentID", in: documentIDs).limit(to: 10).getDocuments { querySnapshot, err in
                if let err = err {
                    observer.onError(err)
                    return
                }
                guard let querySnapshot = querySnapshot else { return }
                let likes = querySnapshot.documents.map { snapshot -> Contents in
                    let dic = snapshot.data()
                    let like = Contents(dic: dic)
                    return like
                }
                observer.onNext(likes)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    
}
