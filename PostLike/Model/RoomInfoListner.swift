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
    func fetchMemberCount(roomID: String) -> Observable<Room>
}

final class RoomInfoDefaultListner: RoomInfoListner {
    private var memberCountListner: ListenerRegistration?
    func fetchMemberCount(roomID: String) -> Observable<Room> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            self.memberCountListner = db.collection("rooms").document(roomID).collection("memberCount").document("count").addSnapshotListener{ snapshot, err in
                if let err = err {
                    observer.onError(err)
                    return
                }
                guard let snapshot = snapshot, let dic = snapshot.data() else { return }
                let room = Room(dic: dic)
                observer.onNext(room)
            }
            return Disposables.create {
                self.memberCountListner?.remove()
            }
        }
    }
    
    private var roomInfoListner: ListenerRegistration?
    func fetchRoomInfo(roomID: String) -> Observable<Room> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            self.roomInfoListner = db.collection("rooms").document(roomID).addSnapshotListener({ snapshot, err in
                if let err = err {
                    observer.onError(err)
                    return
                }
                if snapshot == nil {
                    let room = Room(dic: [:])
                    room.isDeleted = true
                    observer.onNext(room)
                }else {
                    let dic = snapshot?.data() ?? [:]
                    let room = Room(dic: dic)
                    room.isDeleted = false
                    observer.onNext(room)
                }
                
                
                
            })
            return Disposables.create {
                self.roomInfoListner?.remove()
            }
        }
    }
    
    
    
}
