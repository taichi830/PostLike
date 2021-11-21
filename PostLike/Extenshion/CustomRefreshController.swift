//
//  CustomRefreshController.swift
//  postLike
//
//  Created by taichi on 2021/05/13.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

class CustomRefreshControl: UIRefreshControl{
    override func layoutSubviews() {
        var frame: CGRect = self.frame
        let moveY: CGFloat = 50
         frame.origin.y = frame.origin.y + moveY
         self.frame = frame
    }
}
