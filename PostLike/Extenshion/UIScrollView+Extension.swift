//
//  UIScrollView+Extension.swift
//  PostLike
//
//  Created by taichi on 2022/03/13.
//  Copyright © 2022 taichi. All rights reserved.
//

import UIKit

extension UIScrollView {
    //スクロールで最下部の近くにきたかを検知
    func isNearBottomEdge() -> Bool {
        let edgeOffset: CGFloat = 20
        return contentOffset.y + frame.size.height + edgeOffset > contentSize.height
    }
    
}
