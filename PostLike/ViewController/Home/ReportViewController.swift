//
//  ReportViewController.swift
//  postLike
//
//  Created by taichi on 2021/05/25.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseFirestore
import FirebaseAuth


enum ReportType: String {
    case post
    case user
    case room
}


struct ReportItems {
    let title: String
    let field: String
}


struct ReportViewModel {
    var items = PublishSubject<[ReportItems]>()
    
    func fetchItems() {
        let reportItems = [
            ReportItems(title: "スパムである", field: "spam"),
            ReportItems(title: "センシティブである", field: "sensitive"),
            ReportItems(title: "差別的である", field: "discriminatory"),
            ReportItems(title: "不快である", field: "discomfort"),
            ReportItems(title: "その他", field: "other")
        ]
        
        items.onNext(reportItems)
        items.onCompleted()
        
    }
}



final class ReportViewController: UIViewController  {
    
    
    private var row = Int()
    var passedContent = Contents(dic: [:])
    var passedRoomInfo = Room(dic: [:])
    var reportType = ReportType(rawValue: "")
    private let viewModel = ReportViewModel()
    private let disposeBag = DisposeBag()
    
    
    @IBOutlet private weak var reportItemTableView: UITableView!
    @IBOutlet private weak var reportButton: UIButton!
    @IBOutlet private weak var topLabel: UILabel!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        reportButton.isEnabled = false
        reportButton.layer.cornerRadius = 23
        
        if reportType == .post {
            topLabel.text = "投稿を報告・ミュート"
        }else if reportType == .user {
            topLabel.text = "ユーザーを報告・ブロック"
        }else if reportType == .room {
            topLabel.text = "ルームを報告"
        }
        
        
        setupTableView()
        
        
        
    }
    
    
    
    
    
    @IBAction private func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    
    
    
    private func sendReports(reportData:[String:Any],docData:[String:Any],reportRef:DocumentReference,ref:DocumentReference, completion: @escaping () -> Void){
        let batch = Firestore.firestore().batch()
        batch.setData(reportData, forDocument: reportRef, merge: true)
        batch.setData(docData, forDocument: ref,merge: true)
        batch.commit { err in
            if let err = err {
                print("err:", err)
                return
            }else{
                completion()
            }
        }
    
    }
    
    
    
    
    
    //ユーザーまたは投稿を報告
    private func report(type: String, documentID: String, roomID: String, uid: String, myuid: String, field: String, collection: String) {
        let reportData = [
            "documentID": documentID,
            "roomID": roomID,
            "uid": uid,
            field: FieldValue.increment(1.0)
        ] as [String : Any]

        let docData = [
            "type": type,
            "documentID": documentID,
            "roomID": roomID,
            "uid": uid
        ] as [String : Any]

        let reportRef = Firestore.firestore().collection(collection).document(passedContent.documentID)

        let ref = Firestore.firestore().collection("users").document(myuid).collection("reports").document(documentID)

        sendReports(reportData: reportData, docData: docData, reportRef: reportRef, ref: ref, completion: {
            self.presentingViewController?.presentingViewController?.dismiss(animated: true)
        })
    }
    
    
    
    
    
    
    //ルームを報告
    private func reportRoom(roomID: String, field: String) {
        let docData = [
            "documentID": roomID,
            field: FieldValue.increment(1.0)
        ] as [String : Any]
        Firestore.firestore().collection("reportedRooms").document(roomID).setData(docData, merge: true){
            (err) in
            if let err = err {
                print("firestoreへの保存に失敗しました。\(err)")
                return
            }
            self.presentingViewController?.presentingViewController?.dismiss(animated: true)
        }
    }
    
    
    
    
    private func didTapSendButton(field: String) {
        let documentID = passedContent.documentID
        let roomID = passedContent.roomID
        let uid = passedContent.uid
        let myuid = Auth.auth().currentUser!.uid
        if uid == myuid {
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true, completion: nil)
            }
            self.showAlert(title: "自分の投稿は報告できません", message: "", actions: [okAction])
        }else {
            reportButton.rx.tap
                .subscribe { [weak self] _ in
                    switch self?.reportType {
                    case .post:
                        self?.report(type: "post", documentID: documentID, roomID: roomID, uid: uid, myuid: myuid, field: field, collection: "reportedPosts")

                    case .user:
                        let documentID = "\(roomID)-\(uid)"
                        self?.report(type: "user", documentID: documentID, roomID: roomID, uid: uid, myuid: myuid, field: field, collection: "reportedUsers")

                    case .room:
                        let roomID = self?.passedRoomInfo.documentID ?? ""
                        self?.reportRoom(roomID: roomID, field: field)
                        
                    case .none:
                        return
                    }
                }
                .disposed(by: self.disposeBag)
        }
        
    }
    
    
    
    
    
    private func setupTableView() {
        
        reportItemTableView.register(UINib(nibName: "ReportTableViewCell", bundle: nil), forCellReuseIdentifier: "ReportTableViewCell")
        
        viewModel.items.bind(to: reportItemTableView.rx.items(cellIdentifier: "ReportTableViewCell", cellType: ReportTableViewCell.self)) { (row,item,cell) in
            cell.setupBinds(item: item)
        }
        .disposed(by: disposeBag)
        
        reportItemTableView.rx.modelSelected(ReportItems.self).bind { [weak self] item in
            self?.reportButton.isEnabled = true
            self?.reportButton.backgroundColor = .systemRed
            self?.didTapSendButton(field: item.field)
        }
        .disposed(by: disposeBag)
        
        reportItemTableView.rx.itemSelected.subscribe { [weak self] indexPath in
            guard let indexPath = indexPath.element else { return }
            let cell = self?.reportItemTableView.cellForRow(at: indexPath) as! ReportTableViewCell
            cell.didSelect()
        }
        .disposed(by: disposeBag)
        
        reportItemTableView.rx.itemDeselected.subscribe { [weak self] indexPath in
            guard let indexPath = indexPath.element else { return }
            let cell = self?.reportItemTableView.cellForRow(at: indexPath) as! ReportTableViewCell
            cell.didDeselect()
        }
        .disposed(by: disposeBag)
        
        
        viewModel.fetchItems()
    }
    
    
    
    

   
}

