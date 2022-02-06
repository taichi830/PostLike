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

final class CustomCommentView: UIView {
    
    
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
    private var viewModel:CommentViewModel!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
        didTapPostButton()
    }

    private func loadNib() {
        if let view = UINib(nibName: "CustomCommentView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView{
            view.frame = self.bounds
            self.addSubview(view)
        }
    }
    
    func setupBinds() {
        self.viewModel = CommentViewModel(input: (postButtonTap: postButton.rx.tap.asSignal(), commentText: commentTextView.rx.text.orEmpty.asDriver()))
        
        //プレスホルダーが入っていたらtextColorをlightgrayにする
        viewModel.isPlaceholderDriver.drive { [weak self] bool in
            print("isPlaceHolder:",bool)
            self?.commentTextView.textColor = bool ? .lightGray : .label
        }
        .disposed(by: disposeBag)
        
        //バリデーションチェック
        viewModel.validPostDriver.drive { [weak self] bool in
            self?.postButton.isEnabled = bool
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
    
    
    
    
    private func didTapPostButton() {
        postButton.rx.tap.subscribe {  _ in
            print("tapped!!!!!!!!!!!!!!!!!!!!")
        }
        .disposed(by: disposeBag)
    }
    
}
