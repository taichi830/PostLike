//
//  UserListner.swift
//  PostLike
//
//  Created by taichi on 2022/02/07.
//  Copyright © 2022 taichi. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Firebase

protocol UserListner {
    func createUserListner(roomID:String) -> Observable<Contents>
}

final class UserDefaultLisner: UserListner {
    private var listner: ListenerRegistration?
    func createUserListner(roomID: String) -> Observable<Contents> {
        return.create { observer in
            let uid = Auth.auth().currentUser!.uid
            let db = Firestore.firestore()
            self.listner = db.collection("users").document(uid).collection("rooms").document(roomID).addSnapshotListener({ snapshot, err in
                
                if let err = err {
                    observer.onError(err)
                    return
                }
                guard let snapshot = snapshot, let dic = snapshot.data() else { return }
                let content = Contents.init(dic: dic)
                observer.onNext(content)
            })
            return Disposables.create {
                self.listner?.remove()
            }
        }
        
    }
    
    
}
