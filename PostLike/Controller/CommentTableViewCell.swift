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
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
}

//@IBDesignable public class PaddingClass:UILabel{
//    @IBInspectable var topInset:CGFloat = 0
//    @IBInspectable var buttomInset:CGFloat = 0
//    @IBInspectable var rightInset:CGFloat = 0
//    @IBInspectable var leftInset:CGFloat = 0
//    
//    public override func drawText(in rect: CGRect) {
//        let insets = UIEdgeInsets.init(top: topInset, left: leftInset, bottom: buttomInset, right: rightInset)
//        super.drawText(in: rect.inset(by: insets))
//        
//    }
//    
//    public override var intrinsicContentSize: CGSize{
//        let size = super.intrinsicContentSize
//        return CGSize(width: size.width + leftInset + rightInset, height: size.height + topInset + buttomInset)
//    }
//}
