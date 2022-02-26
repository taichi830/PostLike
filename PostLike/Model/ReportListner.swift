//
//  ReportListner.swift
//  PostLike
//
//  Created by taichi on 2022/02/26.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa
import FirebaseFirestore
import Firebase


protocol ReportListner {
    func fetchReportedUsers(contents: [Contents]) -> Observable<[Contents]>
    func fetchReportedContents(contents: [Contents]) -> Observable<[Contents]>
}

final class ReportDefaultListner: ReportListner {
    private var reportedUsersListner: ListenerRegistration?
    func fetchReportedUsers(contents: [Contents]) -> Observable<[Contents]> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            let uid = Auth.auth().currentUser!.uid
            let uids = contents.map { content -> String in
                return content.uid
            }
            self.reportedUsersListner = db.collection("users").document(uid).collection("reports").whereField("uid", in: uids).limit(to: 10).addSnapshotListener { querySnapshot, err in
                if let err = err {
                    observer.onError(err)
                    return
                }
                guard let querySnapshot = querySnapshot else { return }
                let contents = querySnapshot.documents.map { snapshot -> Contents in
                    let dic = snapshot .data()
                    let content = Contents(dic: dic)
                    return content
                }
                observer.onNext(contents)
                
            }
            return Disposables.create {
                self.reportedUsersListner?.remove()
            }
        }
    }
    
    private var reportedContentsListner: ListenerRegistration?
    func fetchReportedContents(contents: [Contents]) -> Observable<[Contents]> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            let uid = Auth.auth().currentUser!.uid
            let documentIDs = contents.map { content -> String in
                return content.documentID
            }
            self.reportedContentsListner = db.collection("users").document(uid).collection("reports").whereField("documentID", in: documentIDs).limit(to: 10).addSnapshotListener { querySnapshot, err in
                if let err = err {
                    observer.onError(err)
                    return
                }
                guard let querySnapshot = querySnapshot else { return }
                let contents = querySnapshot.documents.map { snapshot -> Contents in
                    let dic = snapshot .data()
                    let content = Contents(dic: dic)
                    return content
                }
                observer.onNext(contents)
            }
            return Disposables.create {
                self.reportedContentsListner?.remove()
            }
        }
        
    }
    
    
}
