//
//  PostPreViewTableViewCell.swift
//  PostLike
//
//  Created by taichi on 2022/01/27.
//  Copyright © 2022 taichi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class PostPreViewTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        postImageView.layer.cornerRadius = 8
        deleteButton.layer.cornerRadius = 15
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func setUpCell(image:UIImage) {
        postImageView.image = image
    }

    
    func didTapDeleteButton(viewModel:PostViewModel) {
        let tableView = superview as!
            UITableView
        let tappedIndexPath = tableView.indexPath(for: self)
        guard let row = tappedIndexPath?.row else { return }
        viewModel.remove(row: row)
    }
    
}
