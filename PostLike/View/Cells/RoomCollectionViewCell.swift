//
//  MyroomCollectionViewCell.swift
//  postLike
//
//  Created by taichi on 2021/01/25.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import RxSwift

final class RoomCollectionViewCell: UICollectionViewCell {
    
   
    @IBOutlet weak var personImage: UIImageView!
    @IBOutlet weak var roomName: UILabel!
    @IBOutlet weak var roomImage: UIImageView!
    @IBOutlet weak var roomNameBackView: UIView!
    
    var disposeBag = DisposeBag()
    
    
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
    
    
    func setupCell(item: Contents) {
        roomName.text = item.roomName
        if item.roomImage != "" {
            roomImage.sd_setImage(with: URL(string: item.roomImage), completed: nil)
            personImage.image = UIImage()
        }else{
            roomImage.image = UIImage()
            roomImage.backgroundColor = .systemGray6
            personImage.image = UIImage(systemName: "person.3.fill")
        }
    }
    
    

}
