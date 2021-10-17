//
//  userProfileHeaderView.swift
//  PostLike
//
//  Created by taichi on 2021/08/04.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

class UserProfileHeaderView: UIView{
    
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var personImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var postCountLabel: UILabel!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var roomEditButton: UIButton!
    @IBOutlet weak var hostProfileEditButton: UIButton!
    @IBOutlet weak var profileEditButton: UIButton!
    @IBOutlet weak var editButtonStackView: UIStackView!
    
    
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }

    private func loadNib() {
        if let view = UINib(nibName: "UserProfileHeaderView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView{
            view.frame = self.bounds
            self.addSubview(view)
        }
    }
    
}
