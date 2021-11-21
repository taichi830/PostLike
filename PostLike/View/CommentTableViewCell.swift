//
//  CommentTableViewCell.swift
//  postLike
//
//  Created by taichi on 2021/02/22.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

class CommentTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var personView: UIImageView!
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
//        userImage.layer.cornerRadius = 20
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
}

