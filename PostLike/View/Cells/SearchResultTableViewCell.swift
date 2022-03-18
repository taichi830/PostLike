//
//  SearchResultTableViewCell.swift
//  PostLike
//
//  Created by taichi on 2022/03/17.
//  Copyright © 2022 taichi. All rights reserved.
//

import UIKit

class SearchResultTableViewCell: UITableViewCell {
    
    
    @IBOutlet private weak var roomImageView: UIImageView! {
        didSet {
            roomImageView.layer.cornerRadius = 10
        }
    }
    
    @IBOutlet private weak var roomNameLabel: UILabel!
    
    @IBOutlet private weak var roomIntroLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupCell(roomName: String, roomImage: String, roomIntro: String) {
        roomImageView.setImage(imageUrl: roomImage)
        roomNameLabel.text = roomName
        roomIntroLabel.text = roomIntro
        if roomIntro == "" {
            roomIntroLabel.textColor = .lightGray
            roomIntroLabel.text = "紹介文はありません"
        }else{
            roomIntroLabel.textColor = .black
            roomIntroLabel.text = roomIntro
        }
    }
    
}
