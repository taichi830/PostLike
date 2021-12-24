//
//  NotificationViewController.swift
//  postLike
//
//  Created by taichi on 2021/03/09.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

final class NotificationViewController: UIViewController {
    

    
    @IBOutlet private weak var notificationTableView: UITableView!
    @IBOutlet private weak var latestLabel: UILabel!
    @IBOutlet private weak var headerView: UIView!
    
    
    private var notificationArray = [Contents]()
    private var label = MessageLabel()
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationTableView.delegate = self
        notificationTableView.dataSource = self
        notificationTableView.tableHeaderView = headerView
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchNotificationInfo()
        UserDefaults.standard.setValue(0, forKey: "badgeCount")
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    
    private func fetchNotificationInfo(){
        self.notificationArray.removeAll()
        Firestore.fetchNotifications { notifications in
            if notifications.isEmpty == true {
                self.latestLabel.isHidden = true
                self.label.setupLabel(view: self.view, y: self.view.center.y - 100)
                self.label.text = "お知らせはありません"
                self.notificationTableView.addSubview(self.label)
            }else {
                self.notificationArray.append(contentsOf: notifications)
                self.latestLabel.isHidden = false
                self.label.text = ""
                self.notificationTableView.reloadData()
            }
        }
    }
    
    
    
}

extension NotificationViewController:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return notificationArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let cell = notificationTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let roomImage = cell.viewWithTag(1) as! UIImageView
        let roomName = cell.viewWithTag(2) as! UILabel
        let notification = cell.viewWithTag(3) as! UILabel
        let dateLabel = cell.viewWithTag(4) as! UILabel
        let personsImage = cell.viewWithTag(5) as! UIImageView
        
        if notificationArray[indexPath.row].userImage != "" {
            roomImage.sd_setImage(with: URL(string: notificationArray[indexPath.row].userImage), completed: nil)
            personsImage.image = UIImage()
        }else{
            personsImage.image = UIImage(systemName: "person.fill")
        }
        
        roomImage.layer.cornerRadius = 25
        
        roomName.text = notificationArray[indexPath.row].roomName
        
        if notificationArray[indexPath.row].type == "like" {
            notification.text = "\(notificationArray[indexPath.row].userName)さんがあなたの投稿にいいねをしました。"
        }else if notificationArray[indexPath.row].type == "comment" {
            notification.text = "\(notificationArray[indexPath.row].userName)さんがあなたの投稿にコメントしました。"
        }
        
        let timestamp = notificationArray[indexPath.row].createdAt
        let dateValue = timestamp.dateValue()
        let dateFormat = DateFormatter()
        dateFormat.locale = Locale(identifier: "ja_JP")
        dateFormat.dateStyle = .long
        dateFormat.timeStyle = .none
        let date = dateFormat.string(from: dateValue)
        dateLabel.text = date
        
        
        
        
        return cell
    }
    
    
    
    
    
    
    
}
