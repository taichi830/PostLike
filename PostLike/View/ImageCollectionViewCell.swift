//
//  ContentsCollectionViewCell.swift
//  postLike
//
//  Created by taichi on 2021/01/27.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

final class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var collectionImage: UIImageView!
    @IBOutlet weak var multipleImage: UIImageView!
    @IBOutlet weak var darkView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
