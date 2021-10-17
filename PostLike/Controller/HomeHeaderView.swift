//
//  HomeHeaderView.swift
//  PostLike
//
//  Created by taichi on 2021/08/06.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

class HomeHeaderView: UIView{
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }

    private func loadNib() {
        if let view = UINib(nibName: "HomeHeaderView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView{
            view.frame = self.bounds
            self.addSubview(view)
        }
    }
    
}
