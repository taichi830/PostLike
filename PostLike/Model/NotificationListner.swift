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
    var items: Observable<[Contents]> { get }
}

final class NotificationDefaultListner: NSObject,NotificationListner {
    
    lazy var items = { createNotificationListner() }()
    private var listner: ListenerRegistration?
    
    private func createNotificationListner() -> Observable<[Contents]> {
        return Observable.create { observer in
            let uid = Auth.auth().currentUser!.uid 
            let db = Firestore.firestore()
            self.listner = db.collection("users").document(uid).collection("notifications").order(by: "createdAt", descending: true).limit(to: 10).addSnapshotListener({ querySnapshot, err in
                guard let querySnapshot = querySnapshot else { fatalError("querySnapshot is nil") }
                if let err = err {
                    observer.onError(err)
                    return
                }
                let documents = querySnapshot.documents.map { snapshot -> Contents in
                    let dic = snapshot.data()
                    let notification = Contents(dic: dic)
                    return notification
                }
                observer.onNext(documents)
                observer.onCompleted()
            })
            return Disposables.create {
                self.listner?.remove()
            }
        }
    }
    
    
}
