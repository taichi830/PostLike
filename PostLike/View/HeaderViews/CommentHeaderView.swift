//
//  CommentHeaderViewController.swift
//  PostLike
//
//  Created by taichi on 2021/09/16.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore

final class CommentHeaderView: UIView {
    
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var createdAtLabel: UILabel!
    @IBOutlet weak var personImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }

    private func loadNib() {
        if let view = UINib(nibName: "CommentHeaderView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView{
            view.frame = self.bounds
            self.addSubview(view)
        }
    }
    
    func setupHeaderView(userName:String,userImageUrl:String,comment:String,date: Timestamp) {
        
        userNameLabel.text = userName
        
        userImageView.layer.cornerRadius = userImageView.frame.height/2
        if userImageUrl != "" {
            userImageView.sd_setImage(with: URL(string: userImageUrl), completed: nil)
            personImageView.image = UIImage()
        }else{
            personImageView.image = UIImage(systemName: "person.fill")
        }
        
        commentLabel.text = comment
        
        let createdAt = date.dateValue()
        createdAtLabel.text = UILabel().createdAtString(createdAt: createdAt)
//        let dt2 = Date()
//        let cal = Calendar(identifier: .gregorian)
//        let diff = cal.dateComponents([.day,.hour,.minute,.second], from: dt, to: dt2)
//        let day = diff.day
//        let hour = diff.hour
//        let minute = diff.minute
//        let second = diff.second
//        if day == 0 && hour == 0 && minute == 0    {
//            createdAtLabel!.text = "\(second?.description ?? "")秒前"
//        }else if day == 0 && hour == 0 && minute != 0{
//            createdAtLabel!.text = "\(minute?.description ?? "")分前"
//        }else if day == 0 && hour != 0 {
//            createdAtLabel!.text = "\(hour?.description ?? "")時間前"
//        }else if day != 0 {
//            createdAtLabel!.text = "\(day?.description ?? "")日前"
//        }
        
    }

}
