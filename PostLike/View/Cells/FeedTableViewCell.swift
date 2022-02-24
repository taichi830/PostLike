//
//  PostTableViewCell2.swift
//  postLike
//
//  Created by taichi on 2021/01/16.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import SDWebImage

final class FeedTableViewCell: UITableViewCell{
    
    
    
    @IBOutlet weak var postTextView: LinkTextView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var personImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var singlePostImageView: UIImageView!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var postImageView2: UIImageView!
    @IBOutlet weak var underView: UIView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    @IBOutlet weak var createdAt: UILabel!
    @IBOutlet weak var underHeight: NSLayoutConstraint!
    @IBOutlet weak var roomNameLabel: UILabel!
    
    weak var tableViewCellDelegate:TableViewCellDelegate?
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        
        
        userImageView.layer.cornerRadius = userImageView.frame.height/2
        
        roomNameLabel.adjustsFontSizeToFitWidth = true
        roomNameLabel.minimumScaleFactor = 0.8
        
        postImageView.isHidden = true
        postImageView2.isHidden = true
        singlePostImageView.isHidden = true
        
        singlePostImageView.layer.cornerRadius = 8
        singlePostImageView.isUserInteractionEnabled = true
        singlePostImageView.layer.borderWidth = 1
        singlePostImageView.layer.borderColor = UIColor.systemGray6.cgColor
        
        postImageView.layer.cornerRadius = 8
        postImageView.isUserInteractionEnabled = true
        postImageView.layer.borderWidth = 1
        postImageView.layer.borderColor = UIColor.systemGray6.cgColor
        
        postImageView2.layer.cornerRadius = 8
        postImageView2.isUserInteractionEnabled = true
        postImageView2.layer.borderWidth = 1
        postImageView2.layer.borderColor = UIColor.systemGray6.cgColor
        
    }
    
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    
    func setContent(contents:Contents,likeContensArray:[Contents]){
        //ユーザー画像をセット
        if contents.userImage != "" {
            userImageView.sd_setImage(with: URL(string: contents.userImage as String), completed: nil)
            personImageView.image = UIImage()
        }else{
            userImageView.image = UIImage()
            personImageView.image = UIImage(systemName: "person.fill")
        }
        
        //ユーザーネームをセット
        userNameLabel.text = contents.userName
        
        
//        投稿文をセット
        postTextView.setText(text: contents.text, urls: contents.text.urlsFromRegexs)
        postTextView.textContainerInset = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: -3)
        if contents.text == "" {
            postTextView.isHidden = true
        }else{
            postTextView.isHidden = false
        }
        
        
        
        
        
        //投稿画像をセット
        if contents.mediaArray[0] == "" {
            underHeight.constant = 0
        }else{
            underHeight.constant = 210 * underView.frame.width / 340
        }
        
        
        if contents.mediaArray.count == 1 && contents.mediaArray[0] != "" {
            singlePostImageView.isHidden = false
            postImageView.isHidden = true
            postImageView2.isHidden = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedPostImageView(_:)))
            singlePostImageView.isHidden = false
            singlePostImageView.sd_setImage(with: URL(string: contents.mediaArray[0]), completed: nil)
            singlePostImageView.addGestureRecognizer(tapGesture)
        }else if contents.mediaArray.count == 2 {
            
            singlePostImageView.isHidden = true
            postImageView.isHidden = false
            postImageView2.isHidden = false
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedPostImageView(_:)))
            let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(tappedPostImageView(_:)))
            
            postImageView.sd_setImage(with: URL(string: contents.mediaArray[0] as String), completed: nil)
            postImageView.addGestureRecognizer(tapGesture)
            
            postImageView2.sd_setImage(with: URL(string: contents.mediaArray[1] as String), completed: nil)
            postImageView2.addGestureRecognizer(tapGesture2)
        }
        
        
        
        //いいね数をセット
        likeCountLabel.text = contents.likeCount.description
        
        
        let likeCheck = likeContensArray.filter {
            $0.documentID == contents.documentID
        }
        
        if likeCheck.isEmpty == true {
            likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
            likeButton.tintColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
        }else {
            likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            likeButton.tintColor = .red
            
        }
        
        
        //コメント数をセット
        commentCountLabel.text = contents.commentCount.description
        
        
        
        //投稿から何日経ったかを算出
        let createdAt = contents.createdAt.dateValue()
        self.createdAt.text = UILabel().createdAtString(createdAt: createdAt)
        
        
        
    }
    
   
    
    
    
    
    @IBAction func pushLikeButton(_ sender: Any) {
        let tableView = superview as!
            UITableView
        let tappedIndexPath = tableView.indexPath(for: self)
        let row = tappedIndexPath?.row
        self.tableViewCellDelegate?.pushLikeButton(row: row!, sender: likeButton, countLabel: likeCountLabel)
    }
    
    
    
    
    
    @IBAction func pushCommentButton(_ sender: Any) {
        let tableView = superview as!
            UITableView
        let tappedIndexPath = tableView.indexPath(for: self)
        let row = tappedIndexPath?.row
        self.tableViewCellDelegate?.pushedCommentButton(row: row!)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    @IBAction func pushReportButton(_ sender: Any) {
        let tableView = superview as!
            UITableView
        let tappedIndexPath = tableView.indexPath(for: self)
        let row = tappedIndexPath?.row
        tableViewCellDelegate?.reportButton(row: row!)
    }
    
    
    
    
    
    @objc func tappedPostImageView(_ sender: UITapGestureRecognizer) {
        let tableView = superview as!
            UITableView
        let tappedLocation = sender.location(in: tableView)
        let tappedIndexPath = tableView.indexPathForRow(at: tappedLocation)
        let tappedRow = tappedIndexPath?.row
        self.tableViewCellDelegate?.tappedPostImageView(row: tappedRow!)
    }
    
    
    
    
    
    
    
}
