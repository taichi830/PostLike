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

final class CommentViewController: UIViewController,UITextFieldDelegate,UITextViewDelegate {
    
    
    
    
    var passedUserImage = String()
    var passedUserName = String()
    var passedComment = String()
    var passedDate = Timestamp()
    var passedUid = String()
    var passedRoomName = String()
    var passedDocumentID = String()
    var passedMediaArray = Array<String>()
    var passedRoomID = String()
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
    @IBOutlet weak var customCommentView: CustomCommentView!
    @IBOutlet weak var messageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var messageViewButtomConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentTableView.register(UINib(nibName: "CommentTableViewCell", bundle: nil), forCellReuseIdentifier: "commentCell")
        commentTableView.rowHeight = UITableView.automaticDimension
        
        setupHeaderView()

        customCommentView.setupBinds(roomID: passedRoomID, postID: passedDocumentID, roomName: passedRoomName, passedUid: passedUid, mediaArray: passedMediaArray)
        customCommentView.didStartEditing()
        textViewDidChange()
        showKeyBoard()
        hideKeyboard()
        fetchComments()
       
    }
    
    

    
    
    
    private func setupHeaderView(){
        let headerView = CommentHeaderView()
        headerView.setupHeaderView(userName: passedUserName, userImageUrl: passedUserImage, comment: passedComment, date: passedDate)
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
        customCommentView.commentTextView.rx.didChange.subscribe({ [weak self] _ in
            let size:CGSize = self!.customCommentView.commentTextView.sizeThatFits(self!.customCommentView.commentTextView.frame.size)
            self?.messageViewHeight.constant = size.height + 40
            self?.view.setNeedsLayout()
            self?.view.layoutIfNeeded()
        })
        .disposed(by: disposeBag)
    }
    
    
    
    
    
    private func showKeyBoard() {
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
                self?.messageViewButtomConstraint.constant = -rect.height + self!.view.safeAreaInsets.bottom
                self?.view.setNeedsLayout()
                self?.view.layoutIfNeeded()
            }
        }
        .disposed(by: disposeBag)
    }
    
    
    
    
    private func hideKeyboard() {
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification, object: nil)
            .subscribe({ [weak self] _ in
                self?.messageViewButtomConstraint.constant = 0
                self?.view.setNeedsLayout()
                self?.view.layoutIfNeeded()
            })
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    
    
    
    
    

    
    private func fetchComments() {
        indicator.startAnimating()
        viewModel = CommentViewModel(commentListner: CommentDefaultListner(), documentID: passedDocumentID)
        
        //itemsが空かチェック
        viewModel.isEmpty.drive { [weak self] bool in
            if bool == true {
                self?.indicator.stopAnimating()
                self?.label.setupLabel(view: self!.view, y: self!.view.center.y - 100)
                self?.label.text = "コメントがありません"
                self?.commentTableView.addSubview(self!.label)
            }else{
                self?.label.text = ""
            }
        }
        .disposed(by: disposeBag)
        
        //itemsをtableViewにバインド
        viewModel.items
            .drive( commentTableView.rx.items(cellIdentifier: "commentCell", cellType: CommentTableViewCell.self)) { [weak self] (row, item, cell) in
                cell.userImage.layer.cornerRadius = cell.userImage.frame.height/2
                if item.userImage != "" {
                    self?.indicator.stopAnimating()
                    cell.userImage.sd_setImage(with: URL(string: item.userImage), completed: nil)
                    cell.personView.image = UIImage()
                }
                cell.commentLabel.text = item.text
                cell.userName.text = item.userName
                cell.timeLabel.text = UILabel().createdAtString(createdAt: item.createdAt.dateValue())
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
}






extension CommentViewController:UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if commentTableView.isDragging == true{
            self.customCommentView.commentTextView.resignFirstResponder()
        }
    }
}
