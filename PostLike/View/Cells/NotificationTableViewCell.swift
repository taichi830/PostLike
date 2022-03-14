//
//  NotificationTableViewCell.swift
//  PostLike
//
//  Created by taichi on 2022/02/10.
//  Copyright © 2022 taichi. All rights reserved.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var notifiedAtLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userImageView.layer.cornerRadius = userImageView.frame.height/2
        
        roomNameLabel.baselineAdjustment = .alignBaselines
        roomNameLabel.lineBreakMode = .byTruncatingTail
        
        messageLabel.baselineAdjustment = .alignBaselines
        messageLabel.lineBreakMode = .byCharWrapping
        
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    
    func setupCell(notification: Contents) {
        if notification.userImage != "" {
            userImageView.sd_setImage(with: URL(string: notification.userImage), completed: nil)
        }
        
        roomNameLabel.text = notification.roomName
        
        if notification.type == "like" {
            messageLabel.text =  "\(notification.userName)さんがあなたの投稿にいいねをしました。"
        }else if notification.type == "comment" {
            messageLabel.text = "\(notification.userName)さんがあなたの投稿にコメントしました。"
        }
        
        let timestamp = notification.createdAt
        let dateValue = timestamp.dateValue()
        let dateFormat = DateFormatter()
        dateFormat.locale = Locale(identifier: "ja_JP")
        dateFormat.dateStyle = .long
        dateFormat.timeStyle = .none
        let date = dateFormat.string(from: dateValue)
        notifiedAtLabel.text = date
    }
    
}
