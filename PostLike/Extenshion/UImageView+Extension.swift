//
//  UImageView+Extension.swift
//  PostLike
//
//  Created by taichi on 2022/03/14.
//  Copyright © 2022 taichi. All rights reserved.
//

import UIKit

extension UIImageView {
    func setImage(imageUrl: String) {
        if imageUrl == "" {
            self.image = UIImage(named: "person")
        }else {
            self.sd_setImage(with: URL(string: imageUrl), completed: nil)
        }
    }
}
