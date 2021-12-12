//
//  MyroomCollectionViewCell.swift
//  postLike
//
//  Created by taichi on 2021/01/25.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

final class RoomCollectionViewCell: UICollectionViewCell {
    
   
    @IBOutlet weak var personImage: UIImageView!
    @IBOutlet weak var roomName: UILabel!
    @IBOutlet weak var roomImage: UIImageView!
    @IBOutlet weak var roomNameBackView: UIView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.clipsToBounds = false
        
        roomName.adjustsFontSizeToFitWidth = true
        roomName.minimumScaleFactor = 0.7
    
        roomNameBackView.clipsToBounds = true
        roomNameBackView.layer.cornerRadius = 8

        roomImage.clipsToBounds = true
        roomImage.layer.cornerRadius = 8
        
        self.contentView.clipsToBounds = false
        self.contentView.layer.shadowRadius = 5
        self.contentView.layer.shadowOpacity = 0.1
        self.contentView.layer.shadowOffset = CGSize(width: 3, height: 3)
        self.contentView.layer.shadowColor = UIColor.black.cgColor
        
        
    }

}
