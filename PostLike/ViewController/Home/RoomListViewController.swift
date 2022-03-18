//
//  roomEditViewController.swift
//  postLike
//
//  Created by taichi on 2021/03/25.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

final class RoomListViewController: UIViewController {
   

    @IBOutlet private weak var roomListTableView: UITableView!
    var passedFollwedRoomArray = [Contents]()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomListTableView.delegate = self
        roomListTableView.dataSource = self
        self.setSwipeBackGesture()
        
        if passedFollwedRoomArray.isEmpty == true {
            let label = MessageLabel()
            label.setup(text: "参加しているルームはありません。", at: self.view)
        }
    }
   
    
    
    
    @IBAction private func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
   
}



extension RoomListViewController: UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        passedFollwedRoomArray.count
    }
       
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = roomListTableView.dequeueReusableCell(withIdentifier: "room", for: indexPath)
        
        let roomImage = cell.viewWithTag(1) as! UIImageView
        roomImage.setImage(imageUrl: passedFollwedRoomArray[indexPath.row].roomImage)
        roomImage.layer.cornerRadius = 10
        roomImage.layer.borderColor = UIColor.systemGray6.cgColor
        roomImage.layer.borderWidth = 1
        
        let roomName = cell.viewWithTag(2) as! UILabel
        roomName.text = passedFollwedRoomArray[indexPath.row].roomName
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 108
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let enteredVC = storyboard?.instantiateViewController(identifier: "enteredVC") as! EnteredRoomContentViewController
        enteredVC.passedDocumentID = passedFollwedRoomArray[indexPath.row].documentID
        navigationController?.pushViewController(enteredVC, animated: true)
    }
    
}
