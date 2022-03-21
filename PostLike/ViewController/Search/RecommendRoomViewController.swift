//
//  RecommendRoomViewController.swift
//  PostLike
//
//  Created by taichi on 2021/11/05.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore

final class RecommendRoomViewController: UIViewController{
    
    private enum Section:Int {
        case popular = 0
        case latest
    }
    
    
    
    @IBOutlet private weak var recommendRoomTableView: UITableView! {
        didSet {
            recommendRoomTableView.delegate = self
            recommendRoomTableView.dataSource = self
            recommendRoomTableView.register(UINib(nibName: "SearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: "SearchResultTableViewCell")
        }
    }
    
    private let sectionItem = ["人気順","新着順"]
    private var popularRoomsArray = [Room]()
    private var latestRoomsArray = [Room]()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchPopularRoom()
        fetchLatestRoom()
    }
    
    
    private func fetchPopularRoom(){
        Firestore.fetchPopularRoom { contents in
            self.popularRoomsArray.append(contentsOf: contents)
            self.recommendRoomTableView.reloadData()
        }
    }
    
    
    
    
    private func fetchLatestRoom(){
        Firestore.fetchLatestRoom { contents in
            self.latestRoomsArray.append(contentsOf: contents)
            self.recommendRoomTableView.reloadData()
        }
    }
    
    
 
    
}


extension RecommendRoomViewController:UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        
        case .popular:
            return popularRoomsArray.count
            
        case .latest:
            return latestRoomsArray.count
            
        default:
            return 0
            
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultTableViewCell", for: indexPath) as! SearchResultTableViewCell
        cell.selectionStyle = .none
        
        switch Section(rawValue: indexPath.section) {
        
        case .popular:
            cell.setupCell(roomName: popularRoomsArray[indexPath.row].roomName, roomImage: popularRoomsArray[indexPath.row].roomImage, roomIntro: popularRoomsArray[indexPath.row].roomIntro)
            
        case .latest:
            cell.setupCell(roomName: latestRoomsArray[indexPath.row].roomName, roomImage: latestRoomsArray[indexPath.row].roomImage, roomIntro: latestRoomsArray[indexPath.row].roomIntro)
            
        default:
            break
        }
    
        return cell
    }
    
    

    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
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
        switch Section(rawValue: indexPath.section) {
        
        case .popular:
            detailVC.passedDocumentID = popularRoomsArray[indexPath.row].documentID
            self.navigationController?.pushViewController(detailVC, animated: true)
            
        case .latest:
            detailVC.passedDocumentID = latestRoomsArray[indexPath.row].documentID
            self.navigationController?.pushViewController(detailVC, animated: true)
            
        default:
            break
        }
        
    }
    
    
    
}


