//
//  RoomListner.swift
//  PostLike
//
//  Created by taichi on 2022/03/02.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import FirebaseAuth
import FirebaseFirestore


protocol RoomListner {
    func fetchRooms() -> Observable<[Contents]>
}

final class RoomDefaultListner: RoomListner {
    private var listner: ListenerRegistration?
    func fetchRooms() -> Observable<[Contents]> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            let uid = Auth.auth().currentUser!.uid
            self.listner = db.collection("users").document(uid).collection("rooms").whereField("isJoined", isEqualTo: true).order(by: "createdAt", descending: true).addSnapshotListener { querySnapshot, err in
                if let err = err {
                    print("err:", err)
                    observer.onError(err)
                    return
                }
                let documents = querySnapshot?.documents.map { snapshot -> Contents in
                    let dic = snapshot.data()
                    let content = Contents(dic: dic)
                    return content
                }
                observer.onNext(documents ?? [])
                observer.onCompleted()
            }
            return Disposables.create {
                
            }
        }
    }
    
    
}
