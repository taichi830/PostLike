//
//  headerView.swift
//  postLike
//
//  Created by taichi on 2021/06/17.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

class SearchResultHeaderView: UIView {
    
    @IBOutlet weak var roomImage: UIImageView!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var roomName: UILabel!
    @IBOutlet weak var roomIntro: UILabel!
    @IBOutlet weak var numberCount: UILabel!
    
    
    

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }
    
    private func loadNib() {
        if let view = UINib(nibName: "SearchResultHeaderView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView{
            view.frame = self.bounds
            self.addSubview(view)
        }
    }
   

}
