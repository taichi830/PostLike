//
//  CustomCommentView.swift
//  PostLike
//
//  Created by taichi on 2022/02/06.
//  Copyright © 2022 taichi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class InputCommentView: UIView {
    
    
    @IBOutlet weak var profileImageView: UIImageView!{
        didSet {
            profileImageView.layer.cornerRadius = profileImageView.frame.size.height/2
        }
    }
    @IBOutlet weak var commentTextView: UITextView!{
        didSet {
            commentTextView.text = "コメントを入力する"
            commentTextView.textColor = .lightGray
            commentTextView.layer.cornerRadius = 20
            commentTextView.isScrollEnabled = false
            commentTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            
        }
    }
    @IBOutlet weak var postButton: UIButton!
    
    private let disposeBag = DisposeBag()
    private var viewModel:InputCommentViewModel!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }

    private func loadNib() {
        if let view = UINib(nibName: "InputCommentView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView{
            view.frame = self.bounds
            self.addSubview(view)
        }
    }
    
    func setupBinds(roomID: String, postID: String, roomName: String, passedUid: String, mediaArray: [String]) {
        
        viewModel = InputCommentViewModel(input: (postButtonTap: postButton.rx.tap.asSignal(), commentText: commentTextView.rx.text.orEmpty.asDriver()), postComment: PostCommentAPI(), userListner: UserDefaultLisner(), roomID: roomID, postID: postID, roomName: roomName, passedUid: passedUid, mediaArray: mediaArray)
        
        //バリデーションチェック
        viewModel.validPostDriver.drive { [weak self] bool in
            self?.postButton.isEnabled = bool
            self?.postButton.tintColor = .blue
        }
        .disposed(by: disposeBag)
        
        //プロフィール画像を取得
        viewModel.userInfoDriver.drive { [weak self] content in
            self?.profileImageView.sd_setImage(with: URL(string: content.userImage), completed: nil)
        }
        .disposed(by: disposeBag)
        
        //ルームに参加中かチェック
        viewModel.isJoined.drive { [weak self] bool in
            self?.commentTextView.isEditable = bool
        }
        .disposed(by: disposeBag)
        
        //投稿完了通知を受け取る
        viewModel.isPosted.drive { [weak self] bool in
            if bool == true {
                self?.commentTextView.text = "コメントを入力する"
                self?.commentTextView.textColor = .lightGray
                self?.commentTextView.resignFirstResponder()
            }
        }
        .disposed(by: disposeBag)
        
    }
    
    
    func didStartEditing() {
        self.commentTextView.rx.didBeginEditing.subscribe { [weak self] _ in
            self?.commentTextView.textColor = .label
            self?.commentTextView.text = ""
        }
        .disposed(by: disposeBag)
    }
    
    
}
