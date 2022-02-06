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
    
    
    
    
    @IBOutlet private weak var commentTableView: UITableView!
    @IBOutlet weak var backView: CustomCommentView!
    @IBOutlet weak var messageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var messageViewButtomConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentTableView.delegate = self
        commentTableView.dataSource = self
        commentTableView.register(UINib(nibName: "CommentTableViewCell", bundle: nil), forCellReuseIdentifier: "commentCell")
        commentTableView.rowHeight = UITableView.automaticDimension
        
        setupHeaderView()

        backView.setupBinds()
        backView.didStartEditing()
        textViewDidChange()
        showKeyBoard()
        hideKeyboard()
       
    }
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchComments()
//        fetchUserInfo()
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
    
    
    
    
    
    @IBAction private func sendButton(_ sender: Any) {
//        if commentTextView.text == "" || commentTextView.text == "コメントを入力する" {
//            return
//        }else{
//            let documentID = NSUUID().uuidString
//            let batch = Firestore.firestore().batch()
//            createComment(documentID: documentID, batch: batch)
//            incrementCommentCount(batch: batch)
//            giveNotification(documentID: documentID,batch: batch)
//            batch.commit { err in
//                if let err = err {
//                    print("false\(err)")
//                    let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
//                        self.dismissIndicator()
//                    }
//                    self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
//                    return
//                }else{
//                    self.fetchComments()
//                    self.commentTextView.text = ""
//                }
//            }
//        }
    }
    
    
    
    
//    private func fetchUserInfo(){
//        Firestore.fetchUserInfo(roomID: passedRoomID) { userInfo in
//            if userInfo.isJoined == false {
//                self.commentTextView.text = "ルームに参加するとコメントできます"
//                self.commentTextView.isEditable = false
//                self.sendButton.isEnabled = false
//                self.sendButton.setTitleColor(.lightGray, for: .normal)
//            }
//            self.user = userInfo
//            if userInfo.userImage != "" {
//                self.myImage.sd_setImage(with: URL(string: userInfo.userImage), completed: nil)
//                self.personImage2.image = UIImage()
//            }
//
//        }
//    }
    
    
     
    
    

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
//        if uid != passedUid {
//            
//        }
    }
    
    
    
    
    private func fetchComments(){
        self.commentsArray.removeAll()
        Firestore.fetchComments(documentID: passedDocumentID) { comments in
            if comments.isEmpty == true {
                self.label.setupLabel(view: self.view, y: self.view.center.y - 100)
                self.label.text = "コメントがありません"
                self.commentTableView.addSubview(self.label)
            }else {
                self.label.text = ""
                self.commentsArray.append(contentsOf: comments)
                self.commentTableView.reloadData()
            }
            
        }
    }
    
    
    
}



extension CommentViewController: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = commentTableView.dequeueReusableCell(withIdentifier: "commentCell") as! CommentTableViewCell
        
        let userName = cell.userName
        userName?.text = commentsArray[indexPath.row].userName
        
        let userImage = cell.userImage
        userImage?.layer.cornerRadius = 20
        if commentsArray[indexPath.row].userImage != "" {
            userImage?.sd_setImage(with: URL(string: commentsArray[indexPath.row].userImage), completed: nil)
            cell.personView.image = UIImage()
            
        }
        
        let comment = cell.commentLabel
        comment?.text = commentsArray[indexPath.row].text
        
        let createdAtLabel = cell.timeLabel!
        let createdAt = commentsArray[indexPath.row].createdAt.dateValue()
        createdAtLabel.text = UILabel().createdAtString(createdAt: createdAt)
        
        return cell
        
        
    }
    
    
    
}



extension CommentViewController:UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if commentTableView.isDragging == true{
            self.backView.commentTextView.resignFirstResponder()
        }
    }
}
