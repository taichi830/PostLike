//
//  SearchTableViewCell.swift
//  PostLike
//
//  Created by taichi on 2021/12/17.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

class SearchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var roomImageView: UIImageView!
    @IBOutlet weak var personsImageView: UIImageView!
    @IBOutlet weak var roomNameLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        roomImageView.layer.cornerRadius = roomImageView.frame.height/2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setupCell(roomImageUrl:String,roomName:String){
        roomImageView.sd_setImage(with: URL(string: roomImageUrl), completed: nil)
        roomNameLabel.text = roomName
    }
    
    
    
}
