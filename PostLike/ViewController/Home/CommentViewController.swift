//
//  commentListViewController.swift
//  postLike
//
//  Created by taichi on 2021/02/19.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import Firebase
import RxSwift
import RxCocoa
import FirebaseFirestore

final class CommentViewController: UIViewController {
    
    
    
    
//    var passedUserImage = String()
//    var passedUserName = String()
//    var passedComment = String()
//    var passedDate = Timestamp()
//    var passedUid = String()
//    var passedRoomName = String()
//    var passedDocumentID = String()
//    var passedMediaArray = Array<String>()
//    var passedRoomID = String()
    var passedContent = Contents(dic: ["" : ""])
    private var label = MessageLabel()
    private let disposeBag = DisposeBag()
    private var viewModel:CommentViewModel!
    private lazy var indicator:UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.style = .medium
        indicator.color = .lightGray
        indicator.hidesWhenStopped = true
        indicator.center = self.view.center
        self.view.addSubview(indicator)
        return indicator
    }()
    
    
    
    
    @IBOutlet private weak var commentTableView: UITableView!
    @IBOutlet weak var inputCommentView: InputCommentView!
    @IBOutlet weak var inputCommentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var inputCommentViewBottomConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentTableView.register(UINib(nibName: "CommentTableViewCell", bundle: nil), forCellReuseIdentifier: "CommentTableViewCell")
        commentTableView.rowHeight = UITableView.automaticDimension
        
        setupHeaderView()

        inputCommentView.setupBinds(roomID: passedContent.roomID, postID: passedContent.documentID, roomName: passedContent.roomName, passedUid: passedContent.uid, mediaArray: passedContent.mediaArray)
        
        inputCommentView.didStartEditing()
        textViewDidChange()
        keyboardWillShowNotification()
        keyboardWillHideNotification()
        fetchComments()
        didScrollTableView()
       
    }
    
    

    
    
    
    private func setupHeaderView(){
        let headerView = CommentHeaderView()
        headerView.setupHeaderView(userName: passedContent.userName, userImageUrl: passedContent.userImage, comment: passedContent.text, date: passedContent.createdAt)
        self.commentTableView.tableHeaderView = headerView
        if let tableHeaderView = self.commentTableView.tableHeaderView {
            tableHeaderView.setNeedsLayout()
            tableHeaderView.layoutIfNeeded()
            let size = tableHeaderView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            tableHeaderView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            self.commentTableView.tableHeaderView = tableHeaderView
        }
    }
    
    
    
    

    
    @IBAction private func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    private func textViewDidChange() {
        inputCommentView.commentTextView.rx.didChange.subscribe({ [weak self] _ in
            guard let inputCommentView = self?.inputCommentView else { return }
            let size:CGSize = inputCommentView.commentTextView.sizeThatFits(inputCommentView.commentTextView.frame.size)
            self?.inputCommentViewHeight.constant = size.height + 21
            self?.view.setNeedsLayout()
            self?.view.layoutIfNeeded()
        })
        .disposed(by: disposeBag)
    }
    
    
    
    
    
    private func keyboardWillShowNotification() {
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification, object: nil).subscribe { [weak self] notificationEvent in
            guard let notification = notificationEvent.element else { return }
            guard let userInfo = notification.userInfo as? [String:Any] else {
                return
            }
            guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                return
            }
            guard let rect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
            }
            UIView.animate(withDuration: duration) {
                self?.inputCommentViewBottomConstraint.constant = -rect.height + self!.view.safeAreaInsets.bottom
                self?.view.setNeedsLayout()
                self?.view.layoutIfNeeded()
            }
        }
        .disposed(by: disposeBag)
    }
    
    
    
    
    private func keyboardWillHideNotification() {
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification, object: nil)
            .subscribe({ [weak self] _ in
                self?.inputCommentViewBottomConstraint.constant = 0
                self?.view.setNeedsLayout()
                self?.view.layoutIfNeeded()
            })
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    
    
    
    private func didScrollTableView() {
        commentTableView.rx.didEndDragging.subscribe { [weak self] _ in
            self?.inputCommentView.commentTextView.resignFirstResponder()
        }
        .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    

    
    private func fetchComments() {
        indicator.startAnimating()
        viewModel = CommentViewModel(commentListner: CommentDefaultListner(), documentID: passedContent.documentID)
        
        //itemsが空かチェック
        viewModel.isEmpty.drive { [weak self] bool in
            if bool == true {
                self?.indicator.stopAnimating()
                self?.label.setup(text: "コメントがありません。", at: self!.commentTableView)
            }else{
                self?.label.text = ""
            }
        }
        .disposed(by: disposeBag)
        
        //itemsをtableViewにバインド
        viewModel.items
            .drive( commentTableView.rx.items(cellIdentifier: "CommentTableViewCell", cellType: CommentTableViewCell.self)) { [weak self] (row, item, cell) in
                if let indicator = self?.indicator {
                    cell.setupCell(item: item, indicator: indicator)
                }
            }
            .disposed(by: disposeBag)
        
        commentTableView.rx.willDisplayCell
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] _ in
                self?.viewModel.isBottomObserver.onNext(())
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
}






//extension CommentViewController:UIScrollViewDelegate{
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if commentTableView.isDragging == true{
//            self.inputCommentView.commentTextView.resignFirstResponder()
//        }
//    }
//}
