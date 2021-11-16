//
//  RoomHeaderView.swift
//  PostLike
//
//  Created by taichi on 2021/11/11.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

class RoomHeaderView: UIView {
    
    @IBOutlet weak var bluredImageView: UIImageView!
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var memberLabel: UILabel!
    @IBOutlet weak var myProfileImageView: UIImageView!
    @IBOutlet weak var imageCollectionButton: UIButton!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var backView: UIView!
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }

    private func loadNib() {
        if let view = UINib(nibName: "RoomHeaderView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView{
            view.frame = self.bounds
            self.addSubview(view)
        }
        myProfileImageView.layer.cornerRadius = 15
    }


}
