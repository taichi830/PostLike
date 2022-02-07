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
    private var commentsArray = [Contents]()
    private var user:Contents?
    private var label = MessageLabel()
    private let disposeBag = DisposeBag()
    private var viewModel:CommentViewModel!
    
    
    
    
    @IBOutlet private weak var commentTableView: UITableView!
    @IBOutlet weak var backView: CustomCommentView!
    @IBOutlet weak var messageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var messageViewButtomConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentTableView.register(UINib(nibName: "CommentTableViewCell", bundle: nil), forCellReuseIdentifier: "commentCell")
        commentTableView.rowHeight = UITableView.automaticDimension
        
        setupHeaderView()

        backView.setupBinds(roomID: passedRoomID)
        backView.didStartEditing()
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

        backView.commentTextView.rx.didChange.subscribe({ [weak self] _ in
            let size:CGSize = self!.backView.commentTextView.sizeThatFits(self!.backView.commentTextView.frame.size)
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
    
    
    
    
    
    
    
    
    

    
    
     
    
    

//    private func createComment(documentID:String,batch:WriteBatch){
//        let uid = Auth.auth().currentUser!.uid
//        let dic =  [
//            "userName":user?.userName ?? "",
//            "userImage":user?.userImage ?? "",
//            "text":commentTextView.text ?? "",
//            "createdAt":Timestamp(),
//            "documentID":documentID,
//            "roomID":passedRoomID,
//            "postID":passedDocumentID,
//            "uid":uid,
//            "likeCount":0,
//            "commentCount":0]
//            as [String:Any]
//        Firestore.createComment(uid: uid, roomID: passedRoomID, documentID: documentID, dic: dic, batch: batch)
//
//    }
    
    
    
    
    private func incrementCommentCount(batch:WriteBatch){
        Firestore.increaseCommentCount(uid: passedUid, roomID: passedRoomID, documentID: passedDocumentID, batch: batch)
        if passedMediaArray[0] != "" {
            Firestore.increaseMediaPostCommentCount(roomID: passedRoomID, documentID: passedDocumentID, batch: batch)
        }
    }
    
    
    
    private func giveNotification(documentID:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let dic = [
            "userName":user?.userName ?? "",
            "userImage":user?.userImage ?? "",
            "uid":uid,
            "roomName":passedRoomName,
            "createdAt":Timestamp(),
            "postID":passedDocumentID,
            "roomID":passedRoomID,
            "documentID":documentID,
            "type":"comment"] as [String:Any]
        Firestore.createNotification(uid: passedUid, myuid: uid, documentID: documentID, dic: dic, batch: batch)
    }
    
    
    private func fetchComments() {
        viewModel = CommentViewModel(commentListner: CommentDefaultListner(), documentID: passedDocumentID)
        viewModel.items
            .drive( commentTableView.rx.items(cellIdentifier: "commentCell", cellType: CommentTableViewCell.self)) { row, item, cell in
                print("item:",item)
                cell.userImage.layer.cornerRadius = cell.userImage.frame.height/2
                if item.userImage != "" {
                    cell.userImage.sd_setImage(with: URL(string: item.userImage), completed: nil)
                }else{
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
            self.backView.commentTextView.resignFirstResponder()
        }
    }
}
