//
//  PostTableViewCell2.swift
//  postLike
//
//  Created by taichi on 2021/01/16.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {
    
    
    
    @IBOutlet weak var postProfileImage: UIImageView!
    @IBOutlet weak var personImage: UIImageView!
    @IBOutlet weak var postProfileName: UILabel!
    @IBOutlet weak var postCommentLabel: UILabel!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var singlePostImage: UIImageView!
    @IBOutlet weak var MyPostImage: UIImageView!
    @IBOutlet weak var myPostImage2: UIImageView!
    @IBOutlet weak var underView: UIView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    @IBOutlet weak var createdAt: UILabel!
    @IBOutlet weak var underHeight: NSLayoutConstraint!
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var postCommentHeight: NSLayoutConstraint!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }
    
   
    
    
    
}
