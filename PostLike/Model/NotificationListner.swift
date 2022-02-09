//
//  NotificationListner.swift
//  PostLike
//
//  Created by taichi on 2022/02/09.
//  Copyright © 2022 taichi. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Firebase

protocol NotificationListner {
    func createNotificationListner() -> Observable<[Contents]>
}

final class NotificationDefaultListner: NotificationListner {
    private var listner: ListenerRegistration?
    func createNotificationListner() -> Observable<[Contents]> {
        return Observable.create { [weak self] observer in
            let uid = Auth.auth().currentUser?.uid ?? ""
            let db = Firestore.firestore()
            self?.listner = db.collection("users").document(uid).collection("notifications").order(by: "createdAt", descending: true).limit(to: 10).addSnapshotListener({ querySnapshot, err in
                if let err = err {
                    observer.onError(err)
                    return
                }
                guard let querySnapshot = querySnapshot else { fatalError("querySnapshot is nil") }
                let documents = querySnapshot.documents.map { snapshot -> Contents in
                    let dic = snapshot.data()
                    let notification = Contents.init(dic: dic)
                    return notification
                }
                observer.onNext(documents)
                observer.onCompleted()
            })
            
            return Disposables.create {
                self?.listner?.remove()
            }
        }
    }
    
    
}
