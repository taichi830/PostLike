//
//  RecommendRoomViewController.swift
//  PostLike
//
//  Created by taichi on 2021/11/05.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import Firebase

class RecommendRoomViewController: UIViewController{
    
    
    
    
    @IBOutlet weak var recommendRoomTableView: UITableView!
    
    private var sectionItem = ["人気順","新着順"]
    private var popularRoomsArray = [Room]()
    private var latestRoomsArray = [Room]()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recommendRoomTableView.delegate = self
        recommendRoomTableView.dataSource = self
        recommendRoomTableView.separatorStyle = .singleLine
        recommendRoomTableView.separatorColor = .systemGray4
        fetchPopularRoom()
        fetchLatestRoom()
    }
    
    
    func fetchPopularRoom(){
        Firestore.firestore().collection("rooms").order(by: "memberCount", descending: true).limit(to: 10).getDocuments { querySnapShot, err in
            if err != nil {
                return
            }else{
                for document in querySnapShot!.documents{
                    let dic = document.data()
                    let rooms = Room.init(dic: dic)
                    self.popularRoomsArray.append(rooms)
                }
                self.recommendRoomTableView.reloadData()
            }
        }
    }
    
    
    
    
    func fetchLatestRoom(){
        Firestore.firestore().collection("rooms").order(by: "createdAt", descending: true).limit(to: 10).getDocuments { querySnapShot, err in
            if err != nil {
                return
            }else{
                for document in querySnapShot!.documents{
                    let dic = document.data()
                    let rooms = Room.init(dic: dic)
                    self.latestRoomsArray.append(rooms)
                }
                self.recommendRoomTableView.reloadData()
            }
        }
    }
    
    
 
    
}


extension RecommendRoomViewController:UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return popularRoomsArray.count
        case 1:
            return latestRoomsArray.count
        default:
            return 0
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recommendRoom", for: indexPath)
        cell.selectionStyle = .none
        
        let roomImageView = cell.viewWithTag(1) as! UIImageView
        roomImageView.layer.cornerRadius = roomImageView.frame.height/2
        
        let roomNameLabel = cell.viewWithTag(2) as! UILabel
        
        let roomIntroLabel = cell.viewWithTag(3) as! UILabel
        
        switch indexPath.section {
        case 0:
            roomImageView.sd_setImage(with: URL(string: popularRoomsArray[indexPath.row].roomImage), completed: nil)
            roomNameLabel.text = popularRoomsArray[indexPath.row].roomName
            if popularRoomsArray[indexPath.row].roomIntro == "" {
                roomIntroLabel.textColor = .lightGray
                roomIntroLabel.text = "紹介文はありません"
            }else{
                roomIntroLabel.textColor = .black
                roomIntroLabel.text = popularRoomsArray[indexPath.row].roomIntro
            }
            
        case 1:
            roomImageView.sd_setImage(with: URL(string: latestRoomsArray[indexPath.row].roomImage), completed: nil)
            roomNameLabel.text = latestRoomsArray[indexPath.row].roomName
            if latestRoomsArray[indexPath.row].roomIntro == "" {
                roomIntroLabel.textColor = .lightGray
                roomIntroLabel.text = "紹介文はありません"
            }else{
                roomIntroLabel.textColor = .black
                roomIntroLabel.text = latestRoomsArray[indexPath.row].roomIntro
            }
        default:
            break
        }
        
//        let button = cell.viewWithTag(4) as! UIButton
//        button.layer.cornerRadius = 16
//        button.clipsToBounds = true
//
    
        return cell
    }
    
    

    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 55
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionItem[section]
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label : UILabel = UILabel()
        label.textColor = .black
        label.text = "     \(sectionItem[section])"
        label.font = UIFont.boldSystemFont(ofSize: 17)
        return label
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = storyboard?.instantiateViewController(withIdentifier: "detailVC") as! RoomDetailViewController
        switch indexPath.section {
        case 0:
            detailVC.passedDocumentID = popularRoomsArray[indexPath.row].documentID
            self.navigationController?.pushViewController(detailVC, animated: true)
        case 1:
            detailVC.passedDocumentID = latestRoomsArray[indexPath.row].documentID
            self.navigationController?.pushViewController(detailVC, animated: true)
        default:
            break
        }
        
    }
    
    
    
}


