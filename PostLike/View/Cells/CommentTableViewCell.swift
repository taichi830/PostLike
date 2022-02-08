//
//  CommentTableViewCell.swift
//  postLike
//
//  Created by taichi on 2021/02/22.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

final class CommentTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var personView: UIImageView!
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
        self.userImage.layer.cornerRadius = self.userImage.frame.height/2
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupCell(item:Contents,indicator:UIActivityIndicatorView) {
        
        indicator.stopAnimating()
        if item.userImage != "" {
            self.userImage.sd_setImage(with: URL(string: item.userImage), completed: nil)
            self.personView.image = UIImage()
        }else{
            self.userImage.image = UIImage()
            self.personView.image = UIImage(systemName: "person.fill")
        }
        self.commentLabel.text = item.text
        self.userName.text = item.userName
        self.timeLabel.text = UILabel().createdAtString(createdAt: item.createdAt.dateValue())
    }
    
    
}

