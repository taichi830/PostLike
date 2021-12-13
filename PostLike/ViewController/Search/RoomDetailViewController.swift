//
//  roomDetailViewController.swift
//  postLike
//
//  Created by taichi on 2020/11/25.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import DKImagePickerController


protocol CreateProfileDelegate:AnyObject {
    func joinRoomBatch(_ completed: @escaping() -> Void,userName:String)
    func createStrageWithBatch(_ completed: @escaping() -> Void,userName:String,profileImageView:UIImageView)
}

final class RoomDetailViewController: UIViewController {
    
    
    
    @IBOutlet weak var roomName: UILabel!
    @IBOutlet weak var contentsTableView: UITableView!
    @IBOutlet weak var roomImageView: UIImageView!
    @IBOutlet weak var roomImageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var roomImageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topBlurEffectView: UIVisualEffectView!
    @IBOutlet weak var headerView: SearchResultHeaderView!
    @IBOutlet weak var backButtonBackView: UIView!
    @IBOutlet weak var dotButtonBackView: UIView!
    @IBOutlet weak var effectViewHeight: NSLayoutConstraint!
    
    var passedRoomName = String()
    var passedRoomImage = String()
    var passedDocumentID = String()
    var passedNumberOfMember = Int()
    var passedRoomIntro = String()
    
    private var label = UILabel()
    private var contentsArray = [Contents]()
    private var reportedUsersArray = [Contents]()
    private var reportedContentsArray = [Contents]()
    private var likeContentsArray = [Contents]()
    private var joinedRoom:Contents?
    private var roomInfo:Room?
    private var memberCount:Room?
    private var lastDocument:QueryDocumentSnapshot?
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.contentsTableView.delegate = self
        self.contentsTableView.dataSource = self
        self.contentsTableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: "postTable")
        self.contentsTableView.contentInsetAdjustmentBehavior = .never
        
        backButtonBackView.layer.cornerRadius = 15
        dotButtonBackView.layer.cornerRadius = 15
        
        
        headerView.joinButton.clipsToBounds = true
        headerView.joinButton.layer.cornerRadius = 18
        headerView.joinButton.layer.borderWidth = 1
        headerView.joinButton.layer.borderColor = UIColor.systemGray5.cgColor
        headerView.joinButton.addTarget(self, action: #selector(pushedJoinButton(_:)), for: .touchUpInside)
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
        contentsTableView.addGestureRecognizer(swipeGesture)
        
        
        
        fetchRoomInfo()
        
        
    }
    
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchJoinedRoom()
        fetchMemberCount()
    }
    
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        effectViewHeight.constant = self.view.safeAreaInsets.top + 46
    }
    
    
    
    
    
    private func setupHeaderView(){
        if let tableHeaderView = headerView {
            tableHeaderView.setNeedsLayout()
            tableHeaderView.layoutIfNeeded()
            let size = tableHeaderView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            tableHeaderView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            self.contentsTableView.tableHeaderView = tableHeaderView
        }
    }
    
    
    
    
    @IBAction private func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    @IBAction private func reportButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let modalMenuVC = storyboard.instantiateViewController(withIdentifier: "modalMenu") as! ModalMenuViewController
        modalMenuVC.modalPresentationStyle = .custom
        modalMenuVC.transitioningDelegate = self
        modalMenuVC.passedRoomID = passedDocumentID
        modalMenuVC.passedViewController = self
        modalMenuVC.passedType = ModalType.room.rawValue
        modalMenuVC.passedRoomImageUrl = roomInfo?.roomImage ?? ""
        modalMenuVC.passedRoomName = roomInfo?.roomName ?? ""
        modalMenuVC.passedRoomIntro = roomInfo?.roomIntro ?? ""
        modalMenuVC.passedRoomImage = headerView.roomImage.image ?? UIImage()
        present(modalMenuVC, animated: true, completion: nil)
    }
    
    
    
    
    @objc private func swiped(_ sender:UISwipeGestureRecognizer){
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    
    
    @objc private func tappedBluredView(_ sender:UITapGestureRecognizer){
        tabBarController?.tabBar.isHidden = false
    }
    
    
    
    
    
    
    @objc private func pushedJoinButton(_ sender: UIButton) {
        if sender.titleLabel?.text == "参加する" && self.joinedRoom?.documentID == ""{
            let modalVC = self.storyboard?.instantiateViewController(withIdentifier: "modal") as! CreateProfileModalViewController
            modalVC.modalPresentationStyle = .custom
            modalVC.transitioningDelegate = self
            modalVC.createProfileDelegate = self
            present(modalVC, animated: true, completion: nil)
        }else if sender.titleLabel?.text == "参加する" && self.joinedRoom?.documentID != "" && self.joinedRoom?.isJoined == false{
            creatProfileWhenHaveCreated()
        }else if sender.titleLabel?.text == "ルームへ" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let enteredVC = storyboard.instantiateViewController(identifier: "enteredVC") as! EnteredRoomContentViewController
            enteredVC.passedDocumentID = roomInfo!.documentID
            navigationController?.pushViewController(enteredVC,animated: false)
        }
    }
    
    
    
    
    @objc private func tappedbluredView(_ sender: UITapGestureRecognizer){
        tabBarController?.tabBar.isHidden = false
    }
    
    
    
    
    
    
    
    
    private func fetchRoomInfo(){
        Firestore.firestore().collection("rooms").document(passedDocumentID).getDocument { (snapShot, err) in
            if let err = err {
                print("false\(err)")
                return
            }
            if snapShot?.data() == nil {
                self.headerView.joinButton.isEnabled = false
                self.headerView.joinButton.backgroundColor = .systemBackground
                self.headerView.joinButton.setTitleColor(.lightGray, for: .normal)
                self.headerView.roomName.text = "このルームは削除されました"
                self.headerView.roomName.textColor = .lightGray
                self.headerView.roomName.font = UIFont.systemFont(ofSize: 17, weight: .regular)
                self.setupHeaderView()
                self.contentsTableView.reloadData()
            }else {
                let dic = snapShot!.data()
                let roomInfo = Room.init(dic: dic!)
                self.roomInfo = roomInfo
                self.roomName.text = self.roomInfo?.roomName
                self.roomName.adjustsFontSizeToFitWidth = true
                self.roomName.minimumScaleFactor = 0.9
                self.headerView.roomName.text = self.roomInfo?.roomName
                self.headerView.roomIntro.text = self.roomInfo?.roomIntro
                self.headerView.roomName.adjustsFontSizeToFitWidth = true
                self.headerView.roomName.minimumScaleFactor = 0.7
                self.setupHeaderView()
                if self.roomInfo?.roomImage != "" {
                    self.roomImageView.sd_setImage(with: URL(string: self.roomInfo!.roomImage), completed: nil)
                    self.headerView.roomImage.sd_setImage(with: URL(string: self.roomInfo!.roomImage), completed: nil)
                }
                self.fetchContents {
                    self.contentsTableView.reloadData()
                }
            }
            
        }
    }
    
    
    
    
    
    private func fetchReportedContents(documentIDs:[String],_ completed: @escaping() -> Void){
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("reports").whereField("documentID", in: documentIDs).limit(to: 10).getDocuments { querySnapshot, err in
            if err != nil {
                return
            }else{
                for document in querySnapshot!.documents{
                    let dic = document.data()
                    let reportedContents = Contents.init(dic: dic)
                    self.reportedContentsArray.append(reportedContents)
                }
                let filteredArray = self.reportedUsersArray.filter {
                    $0.type == "post"
                }
                for content in filteredArray {
                    self.contentsArray.removeAll(where: {$0.documentID == content.documentID})
                }
                if self.contentsArray.count == 0{
                    self.label.frame = CGRect(x: 0, y: self.view.center.y, width: self.view.frame.size.width, height: 20)
                    self.label.text = "投稿がまだありません"
                    self.label.textAlignment = .center
                    self.label.textColor = .lightGray
                    self.label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
                    self.contentsTableView.addSubview(self.label)
                    completed()
                }else{
                    completed()
                }
            }
        }
    }
    
    
    
    
    
    private func fetchReportedUsers(uids:[String],_ completed: @escaping() -> Void){
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("reports").whereField("uid", in: uids).limit(to: 10).getDocuments { querySnapshot, err in
            if err != nil {
                return
            }else{
                for document in querySnapshot!.documents{
                    let dic = document.data()
                    let reportedUsers = Contents.init(dic: dic)
                    self.reportedUsersArray.append(reportedUsers)
                }
                let filteredArray = self.reportedUsersArray.filter {
                    $0.type == "user"
                }
                for content in filteredArray {
                    self.contentsArray.removeAll(where: {($0.uid == content.uid)&&($0.roomID == content.roomID)})
                }
                if self.contentsArray.count == 0{
                    self.label.frame = CGRect(x: 0, y: self.view.center.y, width: self.view.frame.size.width, height: 20)
                    self.label.text = "投稿がまだありません"
                    self.label.textAlignment = .center
                    self.label.textColor = .lightGray
                    self.label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
                    self.contentsTableView.addSubview(self.label)
                    completed()
                }else{
                    completed()
                }
                
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    private func fetchLikeContents(documentIDs:[String],_ completed: @escaping() -> Void){
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("likes").whereField("documentID", in: documentIDs).limit(to: 10).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("情報の取得に失敗しました。\(err)")
                return
            }
            for document in querySnapshot!.documents{
                let dic = document.data()
                let likeContents = Contents.init(dic: dic)
                self.likeContentsArray.append(likeContents)
            }
            completed()
        }
    }
    
    
    
    
    
    
    
    
    private func fetchContents(_ completed: @escaping() -> Void){
        self.contentsArray.removeAll()
        Firestore.firestore().collectionGroup("posts").whereField("roomID", isEqualTo: passedDocumentID).order(by: "createdAt", descending: true).limit(to: 10).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("取得に失敗しました。\(err)")
                let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [okAction])
                return
            }
            guard let snapShot = querySnapshot else{
                return
            }
            self.lastDocument = snapShot.documents.last
            for document in querySnapshot!.documents {
                let dic = document.data()
                let content = Contents.init(dic: dic)
                self.contentsArray.append(content)
            }
            if self.contentsArray.count == 0 {
                self.label.frame = CGRect(x: 0, y: self.view.center.y, width: self.view.frame.size.width, height: 20)
                self.label.text = "投稿がまだありません"
                self.label.textAlignment = .center
                self.label.textColor = .lightGray
                self.label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
                self.contentsTableView.addSubview(self.label)
                self.contentsTableView.reloadData()
                completed()
            }else{
                self.label.text = ""
                let mappedDocumentArray = self.contentsArray.map { Room -> String in
                    let documentID = Room.documentID
                    return documentID
                }
                let mappedUidArray = self.contentsArray.map { Room -> String in
                    let uid = Room.uid
                    return uid
                }
                self.fetchReportedUsers(uids: mappedUidArray) {
                    self.fetchReportedContents(documentIDs: mappedDocumentArray) {
                        self.fetchLikeContents(documentIDs: mappedDocumentArray) {
                            completed()
                        }
                    }
                }
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    private func fetchMoreContetns(){
        guard let lastDocument = lastDocument else {return}
        var contentsArray2 = [Contents]()
        contentsArray2.removeAll()
        Firestore.firestore().collectionGroup("posts").whereField("roomID", isEqualTo: passedDocumentID).order(by: "createdAt", descending: true).start(afterDocument: lastDocument).limit(to: 10).getDocuments { (querySnapShot, err) in
            if let err = err{
                print(err)
                return
            }
            guard let snapShot = querySnapShot!.documents.last else {return}
            if snapShot == self.lastDocument {
                return
            }else{
                self.lastDocument = snapShot
            }
            for document in querySnapShot!.documents{
                let dic = document.data()
                let followedContent = Contents.init(dic: dic)
                self.contentsArray.append(followedContent)
                contentsArray2.append(followedContent)
            }
            
            if contentsArray2.count != 0 {
                let mappedDocumentArray = contentsArray2.map { Room -> String in
                    let documentID = Room.documentID
                    return documentID
                }
                let mappedUidArray = contentsArray2.map { Room -> String in
                    let uid = Room.uid
                    return uid
                }
                self.fetchReportedUsers(uids: mappedUidArray) {
                    self.fetchReportedContents(documentIDs: mappedDocumentArray) {
                        self.fetchLikeContents(documentIDs: mappedDocumentArray) {
                            self.contentsTableView.reloadData()
                        }
                    }
                }
                
                
            }
        }
    }
    
    
    
    
    
    
    private func fetchJoinedRoom(){
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).getDocument { snapShot, err in
            
            if let err = err {
                print("情報の取得に失敗しました。\(err)")
                return
            }
            let snapShot = snapShot
            let dic = snapShot?.data()
            let followedRoom = Contents.init(dic: dic ?? ["documentID":""])
            self.joinedRoom = followedRoom
            
            if self.joinedRoom?.documentID == self.passedDocumentID && self.joinedRoom?.isJoined == true {
                self.headerView.joinButton.setTitle("ルームへ", for: .normal)
                self.headerView.joinButton.setTitleColor(.black, for: .normal)
                self.headerView.joinButton.backgroundColor = .systemBackground
                
            }else{
                self.headerView.joinButton.setTitle("参加する", for: .normal)
                self.headerView.joinButton.setTitleColor(.white, for: .normal)
                self.headerView.joinButton.backgroundColor = .red
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    private func fetchMemberCount(){
        Firestore.firestore().collection("rooms").document(passedDocumentID).collection("memberCount").document("count").getDocument { snapShot, err in
            
            if let err = err {
                print("false\(err)")
                return
            }else{
                guard let snap = snapShot,let dic = snap.data() else {return}
                let memberCount = Room.init(dic: dic)
                self.memberCount = memberCount
                self.headerView.numberCount.text = "メンバー \(String(describing: self.memberCount!.numberOfMember))人"
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
}






extension RoomDetailViewController: UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = contentsTableView.dequeueReusableCell(withIdentifier: "postTable", for: indexPath) as! PostTableViewCell
        
        
        cell.setContent(contents: contentsArray[indexPath.row], likeContensArray: likeContentsArray)
        
        cell.tableViewCellDelegate = self
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == self.contentsArray.count  {
            fetchMoreContetns()
        }
    }
    
    
    
    
    
    
    
    
    
    private func fetchLatestLikeContent(){
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("likes").order(by: "createdAt",descending: true).limit(to: 1).getDocuments { querySnapshot, err in
            if let err = err {
                print("情報の取得に失敗しました。\(err)")
                self.contentsTableView.reloadData()
                return
            }
            for document in querySnapshot!.documents{
                let dic = document.data()
                let likeContents = Contents.init(dic: dic)
                self.likeContentsArray.append(likeContents)
            }
        }
    }
    
    
    
    
    
    
    //いいねをした時の処理
    private func createLikeContents(row:Int,batch:WriteBatch){
        let myuid = Auth.auth().currentUser!.uid
        let uid = contentsArray[row].uid
        let timestamp = Timestamp()
        let documentID = contentsArray[row].documentID
        let postedAt = contentsArray[row].createdAt
        let docData = ["media": contentsArray[row].mediaArray,"text":contentsArray[row].text,"userImage":contentsArray[row].userImage,"userName":contentsArray[row].userName,"documentID":documentID,"roomID":passedDocumentID,"createdAt":timestamp,"uid":uid,"postedAt":postedAt,"myUid":myuid] as [String:Any]
        let ref = Firestore.firestore().collection("users").document(myuid).collection("likes").document(documentID)
        batch.setData(docData, forDocument: ref, merge: true)
    }
    
    
    
    private func updateLikeCount(row:Int,batch:WriteBatch){
        let documentID = contentsArray[row].documentID
        let roomID = contentsArray[row].roomID
        let uid = contentsArray[row].uid
        let myUid = Auth.auth().currentUser!.uid
        
        let profileRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("posts").document(documentID)
        batch.setData(["likeCount": FieldValue.increment(1.0)], forDocument: profileRef, merge: true)
        
        let likedCountRef = Firestore.firestore().collection("users").document(myUid).collection("rooms").document(roomID).collection("profileLikeCount").document("count")
        batch.setData(["likeCount": FieldValue.increment(1.0)], forDocument: likedCountRef, merge: true)
        
        if contentsArray[row].mediaArray[0] != "" {
            let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
            batch.updateData(["likeCount":FieldValue.increment(1.0)], forDocument: mediaPostRef)
        }
    }
    
    
    
    private func giveNotification(row:Int,batch:WriteBatch){
        let uid = contentsArray[row].uid
        let myuid = Auth.auth().currentUser!.uid
        let postID = contentsArray[row].documentID
        let documentID = "\(myuid)-\(postID)"
        let docData = ["userName":joinedRoom!.userName,"userImage":joinedRoom!.userImage,"uid":myuid,"roomName":self.roomInfo!.roomName,"createdAt":Timestamp(),"postID":postID,"roomID":contentsArray[row].roomID,"documentID":documentID,"type":"like"] as [String:Any]
        let ref = Firestore.firestore().collection("users").document(uid).collection("notifications").document(documentID)
        
        if uid == myuid {
            return
        }else{
            batch.setData(docData, forDocument: ref, merge: true)
        }
    }
    
    
    
    
    
    
    
    
    private func likeBatch(row:Int){
        let batch = Firestore.firestore().batch()
        updateLikeCount(row: row, batch: batch)
        createLikeContents(row: row, batch: batch)
        giveNotification(row: row, batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                self.fetchLatestLikeContent()
            }
        }
    }
    
    
    
    
    
    
    
    //いいねを解除した時の処理
    private func deleteLikeContents(row:Int,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let documentID = contentsArray[row].documentID
        let ref = Firestore.firestore().collection("users").document(uid).collection("likes").document(documentID)
        batch.deleteDocument(ref)
    }
    
    
    
    private func deleteLikeCount(row:Int,batch:WriteBatch){
        let documentID = contentsArray[row].documentID
        let roomID = contentsArray[row].roomID
        let uid = contentsArray[row].uid
        let myUid = Auth.auth().currentUser!.uid
        
        let profileRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("posts").document(documentID)
        batch.setData(["likeCount": FieldValue.increment(-1.0)], forDocument: profileRef, merge: true)
        
        let likedCountRef = Firestore.firestore().collection("users").document(myUid).collection("rooms").document(roomID).collection("profileLikeCount").document("count")
        batch.setData(["likeCount": FieldValue.increment(-1.0)], forDocument: likedCountRef, merge: true)
        
        if contentsArray[row].mediaArray[0] != "" {
            let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
            batch.updateData(["likeCount":FieldValue.increment(-1.0)], forDocument: mediaPostRef)
        }
        
    }
    
    
    
    
    
    private func deleteNotification(row:Int,batch:WriteBatch){
        let uid = contentsArray[row].uid
        let myuid = Auth.auth().currentUser!.uid
        let postID = contentsArray[row].documentID
        let documentID = "\(myuid)-\(postID)"
        let ref = Firestore.firestore().collection("users").document(uid).collection("notifications").document(documentID)
        if uid == myuid {
            return
        }else{
            batch.deleteDocument(ref)
        }
    }
    
    
    
    
    
    
    private func deleteLikeBatch(row:Int){
        let batch = Firestore.firestore().batch()
        let documentID = contentsArray[row].documentID
        
        deleteLikeCount(row: row, batch: batch)
        deleteLikeContents(row: row, batch: batch)
        deleteNotification(row: row, batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                
                self.likeContentsArray.removeAll(where: {$0.documentID == documentID})
                
            }
        }
    }
    
    
    
    
    
    
    
    
}


extension RoomDetailViewController:RemoveContentsDelegate{
    func removeMutedContent(documentID:String) {
        self.contentsArray.removeAll {
            return ($0.documentID  == documentID )
        }
        self.contentsTableView.reloadData()
    }
    
    
    func removeBlockedUserContents(uid:String,roomID:String){
        self.contentsArray.removeAll {
            return (($0.uid  == uid) && ($0.roomID == roomID))
        }
        self.contentsTableView.reloadData()
    }
}




extension RoomDetailViewController:TableViewCellDelegate{
    func reportButton(row: Int) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let modalMenuVC = storyboard.instantiateViewController(withIdentifier: "modalMenu") as! ModalMenuViewController
        modalMenuVC.modalPresentationStyle = .custom
        modalMenuVC.transitioningDelegate = self
        modalMenuVC.passedDocumentID = contentsArray[row].documentID
        modalMenuVC.passedRoomID = contentsArray[row].roomID
        modalMenuVC.passedUid = contentsArray[row].uid
        modalMenuVC.passedViewController = self
        modalMenuVC.passedType = ReportType.post.rawValue
        present(modalMenuVC, animated: true, completion: nil)
    }
    
    func tappedPostImageView(row: Int) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let showImageVC = storyboard.instantiateViewController(identifier: "showImage") as! ShowImageViewController
        showImageVC.passedMedia = contentsArray[row].mediaArray
        showImageVC.passedUid = contentsArray[row].uid
        showImageVC.passedText = contentsArray[row].text
        showImageVC.passedRoomID = contentsArray[row].roomID
        showImageVC.passedDocumentID = contentsArray[row].documentID
        showImageVC.passedUserName = contentsArray[row].userName
        showImageVC.passedUserImage = contentsArray[row].userImage
        present(showImageVC, animated: true, completion: nil)
    }
    
    func pushLikeButton(row: Int, sender: UIButton, countLabel: UILabel) {
        if sender.tintColor == UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)  {
            sender.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            sender.tintColor = .red
            likeBatch(row:row)
            var count = Int(contentsArray[row].likeCount)
            count += 1
            countLabel.text = count.description
            contentsArray[row].likeCount = count
            
        }else if sender.tintColor == .red {
            sender.setImage(UIImage(systemName: "heart"), for: .normal)
            sender.tintColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
            deleteLikeBatch(row: row)
            self.likeContentsArray.removeAll(where: {$0.documentID == contentsArray[row].documentID})
            var count = Int(countLabel.text!)!
            if count >= 1{
                count -= 1
                countLabel.text = count.description
                contentsArray[row].likeCount = count
            }
        }
    }
    
    func pushedCommentButton(row: Int) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let cLVC = storyboard.instantiateViewController(withIdentifier: "commentList") as! CommentViewController
        cLVC.passedUserImage = contentsArray[row].userImage
        cLVC.passedUserName = contentsArray[row].userName
        cLVC.passedComment = contentsArray[row].text
        cLVC.passedDate = contentsArray[row].createdAt
        cLVC.passedDocumentID = contentsArray[row].documentID
        cLVC.passedRoomID = contentsArray[row].roomID
        cLVC.passedUid = contentsArray[row].uid
        cLVC.passedMediaArray = contentsArray[row].mediaArray
        
        present(cLVC, animated: true, completion: nil)
    }
    
    
}






extension RoomDetailViewController:UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        return PresentModalViewController(presentedViewController: presented, presenting: presenting)
        
    }
}


extension RoomDetailViewController:CreateProfileDelegate {
    
    private func createMemberList(batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let docData = ["uid":uid]
        let ref =  Firestore.firestore().collection("rooms").document(passedDocumentID).collection("members").document(uid)
        batch.setData(docData, forDocument: ref)
    }
    
    
    
    private func increaseMemberCount(batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(passedDocumentID).collection("memberCount").document("count")
        batch.setData(["memberCount": FieldValue.increment(1.0)], forDocument: ref, merge: true)
    }
    
    
    
    
    private func creatProfileWhenHaveCreated(){
        let batch = Firestore.firestore().batch()
        let uid = Auth.auth().currentUser!.uid
        let timestamp = Timestamp()
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID)
        
        batch.updateData(["isJoined":true,"createdAt":timestamp,"roomName":self.roomInfo!.roomName,"roomImage":self.roomInfo!.roomImage], forDocument: ref)
        increaseMemberCount(batch: batch)
        createMemberList(batch: batch)
        batch.commit { err in
            if let err = err{
                print("false\(err)")
                return
            }else{
                print("scucces")
                self.headerView.joinButton.setTitle("ルームへ", for: .normal)
                self.headerView.joinButton.setTitleColor(.black, for: .normal)
                self.headerView.joinButton.backgroundColor = .systemBackground
            }
        }
    }
    
    
    
    
    
    private func createRoomDetail(userName:String,userImageUrl:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let timestamp = Timestamp()
        let docData = ["createdAt":timestamp,"userName":userName,"userImage":userImageUrl,"documentID":passedDocumentID,"roomName":self.roomInfo!.roomName,"roomImage":self.roomInfo!.roomImage,"uid":uid,"moderator":self.roomInfo!.moderator,"isJoined":true] as [String:Any]
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID)
        
        batch.setData(docData, forDocument: ref)
        
    }
    
    
    
    func joinRoomBatch(_ completed: @escaping() -> Void,userName:String){
        let batch = Firestore.firestore().batch()
        createRoomDetail(userName: userName, userImageUrl: "", batch: batch)
        increaseMemberCount(batch: batch)
        createMemberList(batch: batch)
        batch.commit { err in
            if let err = err{
                print("false\(err)")
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }else{
                print("scucces")
                self.headerView.joinButton.setTitle("ルームへ", for: .normal)
                self.headerView.joinButton.setTitleColor(.black, for: .normal)
                self.headerView.joinButton.backgroundColor = .systemBackground
                self.dismissIndicator()
                completed()
            }
        }
    }
    
    
    func createStrageWithBatch(_ completed: @escaping() -> Void,userName:String,profileImageView:UIImageView){
        guard let profileImage = profileImageView.image?.jpegData(compressionQuality: 0.1) else {return}
        let fileName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_images").child(fileName)
        storageRef.putData(profileImage, metadata: nil) { (metadata, err) in
            
            if let err = err{
                print("Firestorageへの保存に失敗しました。\(err)")
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }else{
                print("Firestorageへの保存に成功しました。")
                storageRef.downloadURL { (url, err) in
                    if let err = err {
                        print("firestorageからのダウンロードに失敗しました。\(err)")
                        let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                            self.dismissIndicator()
                        }
                        self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                        return
                    }
                    guard let urlString = url?.absoluteString else{return}
                    let batch = Firestore.firestore().batch()
                    self.createRoomDetail(userName: userName, userImageUrl: urlString, batch: batch)
                    self.increaseMemberCount(batch: batch)
                    self.createMemberList(batch: batch)
                    batch.commit { err in
                        if let err = err{
                            print("false\(err)")
                            let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                                self.dismissIndicator()
                            }
                            self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                            return
                        }else{
                            print("scucces")
                            self.headerView.joinButton.setTitle("ルームへ", for: .normal)
                            self.headerView.joinButton.setTitleColor(.black, for: .normal)
                            self.headerView.joinButton.backgroundColor = .systemBackground
                            self.dismissIndicator()
                            completed()
                        }
                    }
                }
            }
        }
    }
    
    
    
}

extension RoomDetailViewController:UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0 {
            self.roomImageViewHeight.constant = -(scrollView.contentOffset.y - 180)
            self.roomImageViewTopConstraint.constant = 0
        }else{
            self.roomImageViewHeight.constant = 180
            self.roomImageViewTopConstraint.constant = -scrollView.contentOffset.y
        }
        
        //下にスクロールに合わせて徐々にblurをかける
        topBlurEffectView.alpha = -0.7 + (scrollView.contentOffset.y - 50)/50
        
        
    }
}



