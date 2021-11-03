//
//  ReportViewController.swift
//  postLike
//
//  Created by taichi on 2021/05/25.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import Firebase

class ReportViewController: UIViewController  {
    
    
    var reportItems = ["スパムである","センシティブである","差別的である","不快である","その他"]
    var row = Int()
    var passedDocumentID = String()
    var passedRoomID = String()
    var passedUid = String()
    var reporttype = String()
    var titleTableViewDelegate: TimeLineTableViewControllerDelegate?
    
    
    @IBOutlet weak var reportItemTableView: UITableView!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var topLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        reportItemTableView.delegate = self
        reportItemTableView.dataSource = self
        
        reportButton.isEnabled = false
        reportButton.layer.cornerRadius = 23
        
        if reporttype == "post"{
            topLabel.text = "投稿を報告・ミュート"
        }else if reporttype == "user" {
            topLabel.text = "ユーザーを報告・ブロック"
        }
        
    }
    
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func sendReport(_ sender: Any) {
        let batch = Firestore.firestore().batch()
        let uid = Auth.auth().currentUser!.uid
        let field = ["spam","sensitive","discriminatory","discomfort","other"]
        let docData = ["documentID":passedDocumentID,"roomID":passedRoomID,"uid":passedUid,"\(field[row])":FieldValue.increment(1.0)] as [String : Any]
        let docData2 = ["documentID":"\(passedRoomID)-\(passedUid)","roomID":passedRoomID,"uid":passedUid,"\(field[row])":FieldValue.increment(1.0)] as [String : Any]
        
        
        if reporttype == "post"{
            let reportPostRef = Firestore.firestore().collection("reportedPosts").document(passedDocumentID)
            let muteRef = Firestore.firestore().collection("users").document(uid).collection("reports").document(passedDocumentID)
            batch.setData(docData, forDocument: reportPostRef,merge: true)
            batch.setData(["type":reporttype,"documentID":passedDocumentID,"roomID":passedRoomID,"uid":passedUid], forDocument: muteRef,merge: true)
            batch.commit { err in
                if err != nil {
                    return
                }else{
                    self.presentingViewController?.presentingViewController?.dismiss(animated: true) {
                        self.titleTableViewDelegate!.removeMutedContent(documentID: self.passedDocumentID)
                    }
                }
            }
        }else if reporttype == "user"{
            let reportUserRef = Firestore.firestore().collection("reportedUsers").document("\(passedRoomID)-\(passedUid)")
            let muteRef = Firestore.firestore().collection("users").document(uid).collection("reports").document("\(passedRoomID)-\(passedUid)")
            batch.setData(docData2, forDocument: reportUserRef,merge: true)
            batch.setData(["type":reporttype,"documentID":"\(passedRoomID)-\(passedUid)","roomID":passedRoomID,"uid":passedUid], forDocument: muteRef,merge: true)
            batch.commit { err in
                if err != nil {
                    return
                }else{
                    self.presentingViewController?.presentingViewController?.dismiss(animated: true) {
                        self.titleTableViewDelegate!.removeBlockedUserContents(uid: self.passedUid, roomID: self.passedRoomID)
                    }
                }
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
