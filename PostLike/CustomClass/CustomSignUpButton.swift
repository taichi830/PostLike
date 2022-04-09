//
//  CustomSignUpButton.swift
//  PostLike
//
//  Created by taichi on 2022/04/09.
//  Copyright © 2022 taichi. All rights reserved.
//

import UIKit

final class CustomSignUpButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
      }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let iconSize: CGFloat = 20
        let iconX: CGFloat = 20
        imageView?.frame = CGRect(x: iconX, y: (frame.size.height - iconSize)/2, width: iconSize, height: iconSize)
        titleLabel?.center = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
    }
    
    private func initialize() {
        titleLabel?.textColor = .black
        titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        backgroundColor = .white
        layer.cornerRadius = 27
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.2
    }
    
    func configure(title: String, image: UIImage?) {
        titleLabel?.text = title
        setImage(image, for: .normal)
    }
    
}
