//
//  roomEditViewController.swift
//  postLike
//
//  Created by taichi on 2021/03/25.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

final class RoomListViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
   

    
    var passedFollwedRoomArray = [Contents]()
    
    @IBOutlet weak var roomListTableView: UITableView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomListTableView.delegate = self
        roomListTableView.dataSource = self
        
        if passedFollwedRoomArray.isEmpty == true {
            let label = UILabel()
            label.frame = CGRect(x: 0, y: 300, width: self.view.frame.width, height: 30)
            label.text = "参加しているルームはありません"
            label.textAlignment = .center
            label.textColor = .lightGray
            label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            roomListTableView.addSubview(label)
        }

      
    }
    
   
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        passedFollwedRoomArray.count
    }
       
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = roomListTableView.dequeueReusableCell(withIdentifier: "room", for: indexPath)
        
        let roomImage = cell.viewWithTag(1) as! UIImageView
        let roomName = cell.viewWithTag(2) as! UILabel
        let personImage = cell.viewWithTag(3) as! UIImageView
        
        if passedFollwedRoomArray[indexPath.row].roomImage != "" {
            roomImage.sd_setImage(with: URL(string: passedFollwedRoomArray[indexPath.row].roomImage), completed: nil)
            personImage.image = UIImage()
        }else{
            personImage.image = UIImage(systemName: "person.3.fill")
        }
        
        roomImage.layer.cornerRadius = roomImage.frame.height/2
        roomImage.layer.borderColor = UIColor.systemGray6.cgColor
        roomImage.layer.borderWidth = 1
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
