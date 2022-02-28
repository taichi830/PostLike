//
//  ReportTableViewCell.swift
//  PostLike
//
//  Created by taichi on 2022/02/27.
//  Copyright © 2022 taichi. All rights reserved.
//

import UIKit

class ReportTableViewCell: UITableViewCell {
    
    @IBOutlet weak var circleImageBackView: UIView! {
        didSet {
            circleImageBackView.layer.cornerRadius = 20
            circleImageBackView.layer.borderColor = UIColor.systemGray5.cgColor
            circleImageBackView.layer.borderWidth = 1
        }
    }
    @IBOutlet private weak var circleImageView: UIImageView!
    @IBOutlet private weak var munuLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if circleImageView.image == UIImage() {
            circleImageView.image = UIImage(systemName: "circlebadge.fill")
            circleImageView.tintColor = .red
        } else {
            circleImageView.image = UIImage()
        }
    }
    
    
    func setupBinds(item: ReportItems) {
        munuLabel.text = item.title
    }
    
}
