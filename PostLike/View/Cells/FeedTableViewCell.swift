//
//  PostTableViewCell2.swift
//  postLike
//
//  Created by taichi on 2021/01/16.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
//import SDWebImage
import RxSwift
//import RxCocoa

final class FeedTableViewCell: UITableViewCell, UIViewControllerTransitioningDelegate{
    
    
    
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
    private var disposeBag = DisposeBag()
    private var viewModel: FeedTableViewModel!
    private var feedViewModel: FeedViewModel!
    
    
    
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
    
    
    
    override func prepareForReuse() {
        self.disposeBag = DisposeBag()
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
            singlePostImageView.sd_setImage(with: URL(string: contents.mediaArray[0]), completed: nil)
        }else if contents.mediaArray.count == 2 {
            
            singlePostImageView.isHidden = true
            postImageView.isHidden = false
            postImageView2.isHidden = false
            
            postImageView.sd_setImage(with: URL(string: contents.mediaArray[0] as String), completed: nil)
            
            postImageView2.sd_setImage(with: URL(string: contents.mediaArray[1] as String), completed: nil)
        }
        
        
        
        //いいね数をセット
        likeCountLabel.text = contents.likeCount.description
        
        
        let likeCheck = likeContensArray.filter {
            $0.documentID == contents.documentID
        }
        
        if likeCheck.isEmpty == true {
            likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
            likeButton.tintColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
            contents.isLiked = false
        }else {
            likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            likeButton.tintColor = .red
            contents.isLiked = true
        }
        
        
        //コメント数をセット
        commentCountLabel.text = contents.commentCount.description
        
        
        
        //投稿から何日経ったかを算出
        let createdAt = contents.createdAt.dateValue()
        self.createdAt.text = UILabel().createdAtString(createdAt: createdAt)
        
        
        
    }
    
    
    func setupBinds(content: Contents, roomID: String, vc: UIViewController, modalType: ModalType) {
        viewModel = FeedTableViewModel(likeButtonTap: likeButton.rx.tap.asSignal(), createLikes: CreateDefaultLikes(), content: content, userInfoListner: UserDefaultLisner(), roomID: roomID)
        didTapCommentButton(content: content, vc: vc)
        didTapPhotos(content: content, vc: vc)
        didTapDotsButton(content: content, vc: vc, modalType: modalType)
        didTapLikeButton(content: content)
        
    }
    
    
    private func didTapLikeButton(content: Contents) {
        likeButton.rx.tap
            .subscribe { [weak self] _ in
                var count = content.likeCount
                if content.isLiked == false {
                    count += 1
                    content.isLiked = true
                    content.likeCount = count
                    self?.likeCountLabel.text = count.description
                    self?.likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
                    self?.likeButton.tintColor = .red

                } else {
                    count -= 1
                    if count >= 0 {
                        content.isLiked = false
                        content.likeCount = count
                        self?.likeCountLabel.text = count.description
                        self?.likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
                        self?.likeButton.tintColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
                        
                    }
                }
                
            }
            .disposed(by: disposeBag)
    }
    
    
    
    private func didTapCommentButton(content: Contents, vc: UIViewController) {
        commentButton.rx.tap
            .subscribe { _ in
                let storyboard = UIStoryboard(name: "Home", bundle: nil)
                let commentVC = storyboard.instantiateViewController(withIdentifier: "commentList") as! CommentViewController
                commentVC.passedContent = content
                vc.present(commentVC, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
    }
    
    
    private func didTapPhotos(content: Contents, vc: UIViewController) {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.rx.event
            .subscribe { _ in
                let storyboard = UIStoryboard(name: "Home", bundle: nil)
                let showImageVC = storyboard.instantiateViewController(identifier: "showImage") as! ShowImageViewController
                showImageVC.passedContent = content
                showImageVC.tappedNumber = 1
                vc.present(showImageVC, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
        
        
        
        
        
        if content.mediaArray.count == 1 {

            singlePostImageView.addGestureRecognizer(tapGesture)

        }else if content.mediaArray.count == 2 {
            
            postImageView.addGestureRecognizer(tapGesture)
            
            let tapGesture2 = UITapGestureRecognizer()
            tapGesture2.rx.event
                .subscribe { _ in
                    let storyboard = UIStoryboard(name: "Home", bundle: nil)
                    let showImageVC = storyboard.instantiateViewController(identifier: "showImage") as! ShowImageViewController
                    showImageVC.passedContent = content
                    showImageVC.tappedNumber = 2
                    vc.present(showImageVC, animated: true, completion: nil)
                }
                .disposed(by: disposeBag)
            postImageView2.addGestureRecognizer(tapGesture2)
            
        }
    }
    
    
    private func didTapDotsButton(content: Contents, vc: UIViewController, modalType: ModalType) {
        reportButton.rx.tap
            .subscribe { _ in
                let storyboard = UIStoryboard(name: "Home", bundle: nil)
                let modalMenuVC = storyboard.instantiateViewController(withIdentifier: "modalMenu") as! ModalMenuViewController
                modalMenuVC.modalPresentationStyle = .custom
                modalMenuVC.transitioningDelegate = vc as? UIViewControllerTransitioningDelegate
                modalMenuVC.passedViewController = vc
                modalMenuVC.passedModalType = modalType
                modalMenuVC.passedContent = content
                vc.present(modalMenuVC, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
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
