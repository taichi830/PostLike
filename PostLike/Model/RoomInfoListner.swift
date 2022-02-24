//
//  RoomInfoListner.swift
//  PostLike
//
//  Created by taichi on 2022/02/24.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa
import FirebaseFirestore

protocol RoomInfoListner {
    func fetchRoomInfo(roomID: String) -> Observable<Room>
}

final class RoomInfoDefaultListner: RoomInfoListner {
    private var listner: ListenerRegistration?
    func fetchRoomInfo(roomID: String) -> Observable<Room> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            self.listner = db.collection("rooms").document(roomID).addSnapshotListener({ snapshot, err in
                if let err = err {
                    observer.onError(err)
                    return
                }
                guard let dic = snapshot?.data() else { return }
                let room = Room(dic: dic)
                observer.onNext(room)
            })
            return Disposables.create {
                self.listner?.remove()
            }
        }
    }
    
    
}
