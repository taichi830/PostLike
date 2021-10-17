//
//  ReportRoomViewController.swift
//  postLike
//
//  Created by taichi on 2021/05/26.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ReportRoomViewController: UIViewController {

    var reportItems = ["スパムである","センシティブである","差別的である","不快である","その他"]
    var row = Int()
    var passedRoomID = String()
    
    
    @IBOutlet weak var reportItemTableView: UITableView!
    @IBOutlet weak var reportButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        reportItemTableView.delegate = self
        reportItemTableView.dataSource = self
        reportButton.isEnabled = false
        reportButton.layer.cornerRadius = 23
    }
    
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func sendReport(_ sender: Any) {
        let field = ["spam","sensitive","discriminatory","discomfort","other"]
        let docData = ["roomID":passedRoomID,"\(field[row])":FieldValue.increment(1.0)] as [String : Any]
        Firestore.firestore().collection("reportedRooms").document(passedRoomID).setData(docData, merge: true){
            (err) in
            if let err = err {
                print("firestoreへの保存に失敗しました。\(err)")
                return
            }
            print("fireStoreへの保存に成功しました。")
            self.dismiss(animated: true, completion: nil)
            
        }
        
        
    }
    

   
}

extension ReportRoomViewController:UITableViewDelegate, UITableViewDataSource{
    
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
        let cell = reportItemTableView.cellForRow(at: indexPath)
        cell?.viewWithTag(2)?.backgroundColor = .systemRed
        reportButton.isEnabled = true
        reportButton.backgroundColor = .systemRed
        reportButton.isEnabled = true
        self.row = indexPath.row
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = reportItemTableView.cellForRow(at: indexPath)
        cell?.viewWithTag(2)?.backgroundColor = .clear
    }

}
