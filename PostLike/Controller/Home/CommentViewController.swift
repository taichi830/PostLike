//
//  commentListViewController.swift
//  postLike
//
//  Created by taichi on 2021/02/19.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import Firebase

class CommentViewController: UIViewController,UITextFieldDelegate,UITextViewDelegate {
    
    var passedUserImage = String()
    var passedUserName = String()
    var passedComment = String()
    var passedDate = Timestamp()
    var passedMyImage = UIImage()
    var passedUid = String()
    var passedRoomName = String()
    var passedDocumentID = String()
    var passedMediaArray = Array<String>()
    var commentsArray = [Room]()
    var user:Contents?
    var passedRoomID = String()
    var alertLabel = UILabel()
    
    
    
    
    
   
    @IBOutlet weak var myImage: UIImageView!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var commentTableView: UITableView!
    @IBOutlet weak var personImage2: UIImageView!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentTableView.delegate = self
        commentTableView.dataSource = self
        
        commentTableView.register(UINib(nibName: "CommentTableViewCell", bundle: nil), forCellReuseIdentifier: "commentCell")
        commentTableView.estimatedRowHeight = 89
        commentTableView.rowHeight = UITableView.automaticDimension
        
        
        
        
        setHeaderView()
        
        commentTextView.delegate = self
        commentTextView.layer.cornerRadius = 5
        commentTextView.text = "コメントを入力する"
        commentTextView.textColor = .lightGray
        
        myImage.layer.cornerRadius = 18
        
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
       
    }
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchComments()
        fetchUserInfo()
    }
    
    
    
    func setHeaderView(){
        let headerView = CommentHeaderView()
        headerView.userImageView.layer.cornerRadius = 20
        if passedUserImage != "" {
            headerView.userImageView.sd_setImage(with: URL(string: passedUserImage), completed: nil)
            headerView.personImageView.image = UIImage()
        }else{
            headerView.personImageView.image = UIImage(systemName: "person.fill")
        }
        headerView.userNameLabel.text = passedUserName
        headerView.commentLabel.text = passedComment
        setPostedDate(headerView: headerView)
        

        self.commentTableView.tableHeaderView = headerView
        if let tableHeaderView = self.commentTableView.tableHeaderView {
            tableHeaderView.setNeedsLayout()
            tableHeaderView.layoutIfNeeded()
            let size = tableHeaderView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            tableHeaderView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            self.commentTableView.tableHeaderView = tableHeaderView
        }
    }
    

    
    func setPostedDate(headerView:CommentHeaderView){
        let dateLabel = headerView.createdAtLabel
        let timestamp = self.passedDate
        let dt = timestamp.dateValue()
        let dt2 = Date()
        let cal = Calendar(identifier: .gregorian)
        let diff = cal.dateComponents([.day,.hour,.minute,.second], from: dt, to: dt2)
        let day = diff.day
        let hour = diff.hour
        let minute = diff.minute
        let second = diff.second
        
        
        if day == 0 && hour == 0 && minute == 0    {
            dateLabel!.text = "\(second?.description ?? "")秒前"
        }else if day == 0 && hour == 0 && minute != 0{
            dateLabel!.text = "\(minute?.description ?? "")分前"
        }else if day == 0 && hour != 0 {
            dateLabel!.text = "\(hour?.description ?? "")時間前"
        }else if day != 0 {
            dateLabel!.text = "\(day?.description ?? "")日前"
        }
    }
    
    

    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    

    
    func textViewDidBeginEditing(_ textView: UITextView) {
       
        if commentTextView.text == "コメントを入力する" {
            commentTextView.text = ""
        }
        commentTextView.textColor = .black
        
    }
    

    
    
    @objc func keybordWillShow(_ notification: Notification) {
        
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
            self.backView.frame.origin.y = self.view.frame.height - (rect.size.height + self.backView.frame.size.height)
        }
    }
    
    
    
    
    
    
    @objc func keybordWillHide(_ notification: Notification) {
        self.backView.frame.origin.y = self.view.frame.size.height - (self.backView.frame.size.height+self.view.safeAreaInsets.bottom)
    }
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        commentTextView.resignFirstResponder()
    }
    
    
    
    
    
    @IBAction func sendButton(_ sender: Any) {
        if commentTextView.text == "" || commentTextView.text == "コメントを入力する" || self.user == nil{
            return
        }else{
            let batch = Firestore.firestore().batch()
            let documentID = NSUUID().uuidString
            createComment(batch: batch, documentID: documentID)
            incrementCommentCount(batch: batch)
            giveNotification(batch: batch, documentID: documentID)
            batch.commit { err in
                if let err = err {
                    print("false\(err)")
                    let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                        self.dismissIndicator()
                    }
                    self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                    return
                }else{
                    self.fetchComments()
                    self.commentTextView.text = ""
                }
            }
        }
    }
    
    
    
    
    func fetchUserInfo(){
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedRoomID).getDocument { (snapShot, err) in
            if let err = err {
                print("情報の取得に失敗しました。\(err)")
                return
            }
            guard let snapShot = snapShot,let dic = snapShot.data() else {return}
            let user = Contents.init(dic: dic)
            self.user = user
            
            if user.userImage != "" {
                self.myImage.sd_setImage(with: URL(string: user.userImage), completed: nil)
                self.personImage2.image = UIImage()
            }
            if user.isJoined == false {
                self.commentTextView.text = "ルームに参加するとコメントできます"
                self.commentTextView.isEditable = false
                self.sendButton.isEnabled = false
                self.sendButton.setTitleColor(.lightGray, for: .normal)
            }
        }
    }
    
    
     
    
    

    func createComment(batch:WriteBatch,documentID:String){
        let uid = Auth.auth().currentUser!.uid
        let userName = user!.userName
        let userImage = user!.userImage
        let date = Timestamp()
        let docData = ["userName":userName,"userImage":userImage,"text":commentTextView.text!,"createdAt":date,"documentID":documentID,"roomID":passedRoomID,"postID":passedDocumentID,"uid":uid,"likeCount":0,"commentCount":0] as [String:Any]
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedRoomID).collection("comments").document(documentID)
        batch.setData(docData, forDocument: ref)
    }
    
    
    
    
    func incrementCommentCount(batch:WriteBatch){
        let profileRef = Firestore.firestore().collection("users").document(passedUid).collection("rooms").document(passedRoomID).collection("posts").document(passedDocumentID)
        batch.setData(["commentCount": FieldValue.increment(1.0)], forDocument: profileRef, merge: true)
        
        if passedMediaArray[0] != "" {
            let mediaPostRef = Firestore.firestore().collection("rooms").document(passedRoomID).collection("mediaPosts").document(passedDocumentID)
            batch.updateData(["commentCount": FieldValue.increment(1.0)], forDocument: mediaPostRef)
        }
        
        
    }
    
    
    
    func giveNotification(batch:WriteBatch,documentID:String){
        let uid = passedUid
        let myUid = Auth.auth().currentUser!.uid
        let postID = passedDocumentID
        let docData = ["userName":user!.userName,"userImage":user!.userImage,"uid":myUid,"roomName":passedRoomName,"createdAt":Timestamp(),"postID":postID,"roomID":passedRoomID,"documentID":documentID,"type":"comment"] as [String:Any]
        let ref = Firestore.firestore().collection("users").document(uid).collection("notifications").document(documentID)
        
        if uid == myUid {
            return
        }else{
            batch.setData(docData, forDocument: ref, merge: true)
        }
    }
    
    
    
    
    func fetchComments(){
        self.commentsArray.removeAll()
        Firestore.firestore().collectionGroup("comments").whereField("postID", isEqualTo: passedDocumentID).order(by: "createdAt", descending: true).getDocuments { (querySnapShot, err) in
            if let err = err {
                print("取得に失敗しました\(err)")
                return
            }
            for document in querySnapShot!.documents {
                let dic = document.data()
                let comment = Room.init(dic: dic)
                self.commentsArray.append(comment)
            }
            if self.commentsArray.isEmpty == true {
                self.alertLabel = UILabel(frame: CGRect(x: 0, y: self.commentTableView.center.y - 70, width: self.view.frame.width, height: 40))
                self.alertLabel.text = "コメントがありません"
                self.alertLabel.textAlignment = .center
                self.alertLabel.textColor = .lightGray
                self.alertLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
                self.commentTableView.addSubview(self.alertLabel)
            }else {
                self.alertLabel.text = ""
            }
            self.commentTableView.reloadData()
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
        
        let createTime = cell.timeLabel!
        let timestamp = commentsArray[indexPath.row].createdAt
        let dt = timestamp.dateValue()
        let dt2 = Date()
        let cal = Calendar(identifier: .gregorian)
        let diff = cal.dateComponents([.day,.hour,.minute,.second], from: dt, to: dt2)
        let day = diff.day
        let hour = diff.hour
        let minute = diff.minute
        let second = diff.second
        if minute == 0 {
            createTime.text = "\(second?.description ?? "")秒前"
        }else if hour == 0 && minute != 0{
            createTime.text = "\(minute?.description ?? "")分前"
        }else if day == 0 && hour != 0 {
            createTime.text = "\(hour?.description ?? "")時間前"
        }else if day != 0 {
            createTime.text = "\(day?.description ?? "")日前"
        }
        
        return cell
        
        
    }
    
    
    
}



extension CommentViewController:UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if commentTableView.isDragging == true{
            commentTextView.resignFirstResponder()
        }
    }
}
