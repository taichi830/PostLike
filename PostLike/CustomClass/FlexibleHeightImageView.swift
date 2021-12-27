//
//  FlexibleHeightImageView.swift
//  PostLike
//
//  Created by taichi on 2021/12/26.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

final class FlexibleHeightImageView: UIView {
    
    private let imageView = UIImageView()
    private let vc = UIViewController()
    public var x = CGFloat()
    public var imageUrl: String? {
        didSet {
            imageView.sd_setImage(with: URL(string: imageUrl ?? ""), completed: nil)
            updateImageViewConstraints()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let img = imageView.image else { return }
        let width = vc.view.frame.width
        let height = width * img.size.height / img.size.width
        //縦長の場合heightを小さくする
        if height >= vc.view.frame.height - 50 {
            let height2 = height - 88
            self.frame = CGRect(x: x, y: vc.view.center.y - height2/2, width: width, height: height2)
        }else{
            self.frame = CGRect(x: x, y: vc.view.center.y - height/2, width: width, height: height)
        }
        
    }
    
    
    private func updateImageViewConstraints() {
        imageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    
}
