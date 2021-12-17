//
//  messageLabel.swift
//  PostLike
//
//  Created by taichi on 2021/12/17.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

final class MessageLabel: UILabel{
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupLabel(view:UIView,y:CGFloat){
        self.frame = CGRect(x: 0, y: y, width: view.frame.size.width, height: 30)
        self.textColor = .lightGray
        self.textAlignment = .center
        self.font = UIFont.systemFont(ofSize: 17, weight: .regular)
    }
    
    
    
    
    
}
