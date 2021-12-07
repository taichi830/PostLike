//
//  ReportViewController.swift
//  postLike
//
//  Created by taichi on 2021/05/25.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth


enum ReportType:String {
    case post
    case user
    case room
}

class ReportViewController: UIViewController  {
    
    
    
    private let reportItems = ["スパムである","センシティブである","差別的である","不快である","その他"]
    private var row = Int()
    var passedDocumentID = String()
    var passedRoomID = String()
    var passedUid = String()
    var reportType = String()
    weak var titleTableViewDelegate: RemoveContentsDelegate?
    
    
    @IBOutlet weak var reportItemTableView: UITableView!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var topLabel: UILabel!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        reportItemTableView.delegate = self
        reportItemTableView.dataSource = self
        
        reportButton.isEnabled = false
        reportButton.layer.cornerRadius = 23
        
        if reportType == ReportType.post.rawValue {
            topLabel.text = "投稿を報告・ミュート"
        }else if reportType == ReportType.user.rawValue {
            topLabel.text = "ユーザーを報告・ブロック"
        }
        
    }
    
    
    
    
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    
    
    
    @IBAction func sendReport(_ sender: Any) {
        let field = ["spam","sensitive","discriminatory","discomfort","other"]
        let uid = Auth.auth().currentUser!.uid
        
        switch reportType {
        case ReportType.post.rawValue:
            let reportData = ["documentID":passedDocumentID,"roomID":passedRoomID,"uid":passedUid,"\(field[row])":FieldValue.increment(1.0)] as [String : Any]
            let reportRef = Firestore.firestore().collection("reportedPosts").document(passedDocumentID)
            let docData = ["type":reportType,"documentID":passedDocumentID,"roomID":passedRoomID,"uid":passedUid]
            let ref = Firestore.firestore().collection("users").document(uid).collection("reports").document(passedDocumentID)
            
            sendReports(reportData: reportData, docData: docData, reportRef: reportRef, ref: ref, completion: {
                self.presentingViewController?.presentingViewController?.dismiss(animated: true) {
                    self.titleTableViewDelegate!.removeMutedContent(documentID: self.passedDocumentID)
                }
            })
            
        case ReportType.user.rawValue:
            let documentID = "\(passedRoomID)-\(passedUid)"
            let docData = ["type":reportType,"documentID":documentID,"roomID":passedRoomID,"uid":passedUid]
            let ref = Firestore.firestore().collection("users").document(uid).collection("reports").document(documentID)
            let reportData = ["documentID":documentID,"roomID":passedRoomID,"uid":passedUid,"\(field[row])":FieldValue.increment(1.0)] as [String : Any]
            let reportRef = Firestore.firestore().collection("reportedUsers").document(documentID)
            
            sendReports(reportData: reportData, docData: docData, reportRef: reportRef, ref: ref) {
                self.presentingViewController?.presentingViewController?.dismiss(animated: true) {
                    self.titleTableViewDelegate!.removeBlockedUserContents(uid: self.passedUid, roomID: self.passedRoomID)
                }
            }
                
        case ReportType.room.rawValue:
            let docData = ["documentID":passedRoomID,"\(field[row])":FieldValue.increment(1.0)] as [String : Any]
            Firestore.firestore().collection("reportedRooms").document(passedRoomID).setData(docData, merge: true){
                (err) in
                if let err = err {
                    print("firestoreへの保存に失敗しました。\(err)")
                    return
                }
                print("fireStoreへの保存に成功しました。")
                self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
            }
            
        default:
            return
        }
        
    }
    
    
    
    
    
    private func sendReports(reportData:[String:Any],docData:[String:Any],reportRef:DocumentReference,ref:DocumentReference, completion: @escaping () -> Void){
        let batch = Firestore.firestore().batch()
        batch.setData(reportData, forDocument: reportRef, merge: true)
        batch.setData(docData, forDocument: ref,merge: true)
        batch.commit { err in
            if err != nil {
                return
            }else{
                completion()
            }
        }
    
    }
    
    
    
    

   
}

extension ReportViewController:UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reportItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = reportItemTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let backView = cell.viewWithTag(1)!
        let circleView = cell.viewWithTag(2) as! UIImageView
        let reportItem = cell.viewWithTag(3) as! UILabel
        backView.layer.cornerRadius = 20
        backView.layer.borderWidth = 1
        backView.layer.borderColor = UIColor.systemGray5.cgColor
        circleView.layer.cornerRadius = 10
        reportItem.text = reportItems[indexPath.row]
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 62
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let uid = Auth.auth().currentUser!.uid
        if passedUid == uid {
            reportButton.isEnabled = false
            reportButton.backgroundColor = .lightGray
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true, completion: nil)
            }
            self.showAlert(title: "自分の投稿は報告できません", message: "", actions: [okAction])
        }else{
            let cell = reportItemTableView.cellForRow(at: indexPath)
            cell?.viewWithTag(2)?.backgroundColor = .systemRed
            reportButton.isEnabled = true
            reportButton.backgroundColor = .systemRed
            self.row = indexPath.row
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = reportItemTableView.cellForRow(at: indexPath)
        cell?.viewWithTag(2)?.backgroundColor = .clear
    }
    
   
    
}
