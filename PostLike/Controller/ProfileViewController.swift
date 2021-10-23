//
//  ProfileViewController.swift
//  postLike
//
//  Created by taichi on 2021/04/10.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController {
    
    
    var passedDocumentID = String()
    var passedModerator = String()
    var likeTableView:UITableView!
    var contentsArray = [Contents]()
    var userInfo:Contents?
    var likeCount:Contents?
    var postCount:Contents?
    var likeContentsArray = [Contents]()
    var row:Int = 0
    var lastDocument:QueryDocumentSnapshot?
    
    
    
    
    
    @IBOutlet weak var headerView: UserProfileHeaderView!
    @IBOutlet weak var titleName: UILabel!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var deleteRoomButton: UIButton!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var cancelView: UIView!
    @IBOutlet weak var deleteContentButton: UIButton!
    @IBOutlet weak var comfirmView: UIView!
    @IBOutlet weak var comfirmLabel: UILabel!
    @IBOutlet weak var deleteRoomContainerView: UIView!
    @IBOutlet weak var profileTableView: UITableView!
    
    
    
    
    override func viewDidLoad(){
        
        super.viewDidLoad()
        
        headerView.userImageView.layer.cornerRadius = 50
        headerView.userImageView.layer.borderColor = UIColor.systemGray5.cgColor
        headerView.userImageView.layer.borderWidth = 1
        
        
        createProfileTableView()
        setUpEditButton()
        
        
        let refleshControl = UIRefreshControl()
        self.profileTableView.refreshControl = refleshControl
        self.profileTableView.refreshControl?.addTarget(self, action: #selector(updateContents), for: .valueChanged)
        
        menuView.layer.cornerRadius = 10
        cancelView.layer.cornerRadius = 10
        deleteContentButton.layer.cornerRadius = 10
        
        fetchPostContents {
//            self.profileTableView.reloadData()
        }
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
        profileTableView.addGestureRecognizer(swipeGesture)
        
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchUserInfo()
        fetchPostCount()
        fetchLikeCount()
        
    }
    
    
    
    
    
    @objc func swiped(_ sender:UISwipeGestureRecognizer){
        navigationController?.popViewController(animated: true)
    }
    
    
    
    @objc func updateContents(){
        self.likeContentsArray.removeAll()
        self.fetchPostContents {
//            self.profileTableView.reloadData()
            self.profileTableView.refreshControl?.endRefreshing()
        }
        
    }
    
    
    
    
    func createProfileTableView(){
        profileTableView.delegate = self
        profileTableView.dataSource = self
        profileTableView.tableHeaderView = headerView
        profileTableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: "postTable")
    }
    
    
    
    
    func setUpEditButton(){
        let uid = Auth.auth().currentUser!.uid
        if passedModerator == uid {
            headerView.hostProfileEditButton.layer.cornerRadius = 2
            headerView.hostProfileEditButton.layer.borderColor = UIColor.systemGray5.cgColor
            headerView.hostProfileEditButton.layer.borderWidth = 1
            headerView.profileEditButton.isHidden = true
            headerView.hostProfileEditButton.addTarget(self, action: #selector(self.pushProfileEditButton), for: .touchUpInside)
            
            headerView.roomEditButton.layer.cornerRadius = 2
            headerView.roomEditButton.layer.borderColor = UIColor.systemGray5.cgColor
            headerView.roomEditButton.layer.borderWidth = 1
            headerView.roomEditButton.addTarget(self, action: #selector(self.pushRoomEditButton), for: .touchUpInside)
            
            deleteRoomButton.setTitleColor(.black, for: .normal)
            deleteRoomButton.isEnabled = true
        }else{
            headerView.profileEditButton.layer.cornerRadius = 2
            headerView.profileEditButton.layer.borderColor = UIColor.systemGray5.cgColor
            headerView.profileEditButton.layer.borderWidth = 1
            headerView.profileEditButton.addTarget(self, action: #selector(self.pushProfileEditButton), for: .touchUpInside)
            
            headerView.editButtonStackView.isHidden = true
            
            deleteRoomButton.setTitleColor(.lightGray, for: .normal)
            deleteRoomButton.isEnabled = false
        }
    }
    
    
    
    
    @objc func pushProfileEditButton(){
        let editVC = storyboard?.instantiateViewController(identifier: "editVC") as! EditProfileViewController
        editVC.passedRoomName = titleName.text!
        editVC.passedDocumentID = passedDocumentID
        editVC.passedUserImage = self.userInfo!.userImage
        editVC.passedUserName = self.userInfo!.userName
        editVC.hidesBottomBarWhenPushed = true
        present(editVC, animated: true, completion: nil)
    }
    
    
    
    
    @objc func pushRoomEditButton(){
        let roomEditVC = storyboard?.instantiateViewController(identifier: "editRoom") as! RoomEditViewController
        roomEditVC.passedRoomName = titleName.text!
        roomEditVC.passedRoomImage = self.userInfo!.roomImage
        roomEditVC.passedDocumentID = passedDocumentID
        roomEditVC.hidesBottomBarWhenPushed = true
        present(roomEditVC, animated: true, completion: nil)
    }
    
    
    
    
    
    @IBAction func menuButton(_ sender: Any) {
        blurView.isHidden = false
        menuView.isHidden = false
        cancelView.isHidden = false
        tabBarController?.tabBar.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        blurView.addGestureRecognizer(tapGesture)
    }
    
    
    
    
    @objc func tapped(_ sender:UITapGestureRecognizer){
        blurView.isHidden = true
        menuView.isHidden = true
        cancelView.isHidden = true
        deleteContentButton.isHidden = true
        comfirmView.isHidden = true
        deleteRoomContainerView.isHidden = true
        tabBarController?.tabBar.isHidden = false
    }
    
    
    
    
    @IBAction func exitRoom(_ sender: Any) {
        comfirmView.isHidden = false
        menuView.isHidden = true
        cancelView.isHidden = true
        comfirmLabel.text = "このルームを退出しますか？"
    }
    
    
    
    @IBAction func deleteRoom(_ sender: Any) {
        deleteRoomContainerView.isHidden = false
        menuView.isHidden = true
        cancelView.isHidden = true
        tabBarController?.tabBar.isHidden = true
    }
    
    
    @IBAction func cancelButton(_ sender: Any) {
        blurView.isHidden = true
        menuView.isHidden = true
        cancelView.isHidden = true
        deleteContentButton.isHidden = true
        tabBarController?.tabBar.isHidden = false
    }
    
    
    
    func callAtDeleteContainerView(){
        blurView.isHidden = true
        menuView.isHidden = true
        cancelView.isHidden = true
        deleteContentButton.isHidden = true
        comfirmView.isHidden = true
        deleteRoomContainerView.isHidden = true
        tabBarController?.tabBar.isHidden = false
    }
    
    
    
    func deleteRoom(batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(self.passedDocumentID)
        batch.deleteDocument(ref)
    }
    
    
    
    
    func deleteMyprofile(batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID)
        batch.updateData(["isJoined":false], forDocument: ref)
    }
    
    
    
    
    func deleteRoomAtContainerView(){
        let batch = Firestore.firestore().batch()
        deleteRoom(batch: batch)
        deleteMyprofile(batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                self.tabBarController?.tabBar.isHidden = false
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    
    
    
    @IBAction func deleteContent(_ sender: Any) {
        comfirmView.isHidden = false
        comfirmLabel.text = "投稿を削除してよろしいですか？"
    }
    
    
    
    
    
    
    //投稿削除時のバッチ処理
    
    func deleteMediaPosts(batch:WriteBatch){
        let documentID = contentsArray[row].documentID
        let ref =  Firestore.firestore().collection("rooms").document(passedDocumentID).collection("mediaPosts").document(documentID)
        batch.deleteDocument(ref)
    }
    
    
    func deletePosts(batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let documentID = contentsArray[row].documentID
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).collection("posts").document(documentID)
        batch.deleteDocument(ref)
    }
    
    
    func deleteModeratorPosts(batch:WriteBatch){
        let documentID = contentsArray[row].documentID
        let ref = Firestore.firestore().collection("rooms").document(passedDocumentID).collection("moderatorPosts").document(documentID)
        batch.deleteDocument(ref)
    }
    
    func decreaseRoomPostCount(batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(passedDocumentID).collection("roomPostCount").document("count")
        batch.setData(["postCount": FieldValue.increment(-1.0)], forDocument: ref, merge: true)
    }
    
    
    
    func decreasePostCount(batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).collection("profilePostCount").document("count")
        batch.setData(["postCount": FieldValue.increment(-1.0)], forDocument: ref, merge: true)
    }
    
    
    
    
    
    
    
    
    
    //ルーム退出時のバッチ処理
    
    func exitRoom(batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(self.passedDocumentID)
        batch.updateData(["isJoined":false], forDocument: ref)
    }
    
    func decreaseMemberCount(batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(self.passedDocumentID).collection("memberCount").document("count")
        batch.setData(["memberCount": FieldValue.increment(-1.0)], forDocument: ref, merge: true)
    }
    
    func deleteUidFromRoomMateList(batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let ref = Firestore.firestore().collection("rooms").document(passedDocumentID).collection("members").document(uid)
        batch.deleteDocument(ref)
    }
    
    
    
    
    
    
    
    
    
    
    @IBAction func allowButton(_ sender: Any) {
        let uid = Auth.auth().currentUser?.uid
        let comfirmText = comfirmLabel.text
        let batch = Firestore.firestore().batch()
        if comfirmText == "投稿を削除してよろしいですか？"{
            deletePosts(batch: batch)
            decreasePostCount(batch: batch)
            decreaseRoomPostCount(batch: batch)
            if passedModerator == uid {
                deleteModeratorPosts(batch: batch)
            }
            if contentsArray[row].mediaArray[0] != "" {
                deleteMediaPosts(batch: batch)
            }
            batch.commit { err in
                if let err = err {
                    print("false\(err)")
                    return
                }else{
                    self.contentsArray.remove(at: self.row)
                    self.profileTableView.reloadData()
                    self.blurView.isHidden = true
                    self.deleteContentButton.isHidden = true
                    self.cancelView.isHidden = true
                    self.comfirmView.isHidden = true
                    self.tabBarController?.tabBar.isHidden = false
                }
            }
            
        }else if comfirmText == "このルームを退出しますか？" {
            exitRoom(batch: batch)
            decreaseMemberCount(batch: batch)
            deleteUidFromRoomMateList(batch: batch)
            batch.commit { err in
                if let err = err {
                    print("false\(err)")
                    return
                }else{
                    self.tabBarController?.tabBar.isHidden = false
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }else{
            return
        }
    }
    
    
    
    
    
    
    @IBAction func cancel(_ sender: Any) {
        self.blurView.isHidden = true
        self.deleteContentButton.isHidden = true
        self.cancelView.isHidden = true
        self.comfirmView.isHidden = true
        self.tabBarController?.tabBar.isHidden = false
    }
    
    
    
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    
    
    
    func fetchLikeContents(documentIDs:[String]){
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("likes").whereField("documentID", in: documentIDs).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("取得に失敗しました。\(err)")
                return
            }
            for document in querySnapshot!.documents {
                let dic = document.data()
                let content = Contents.init(dic: dic)
                self.likeContentsArray.append(content)
            }
            self.profileTableView.reloadData()
        }
    }
    
    
    
    
    func fetchPostContents(_ comleted: @escaping() -> Void){
        let uid = Auth.auth().currentUser!.uid
        self.contentsArray.removeAll()
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).collection("posts").order(by: "createdAt", descending: true).limit(to: 5).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("取得に失敗しました。\(err)")
                return
            }
            for document in querySnapshot!.documents {
                let dic = document.data()
                let content = Contents.init(dic: dic)
                self.contentsArray.append(content)
            }
            if self.contentsArray.count == 0 {
                let label = UILabel(frame: CGRect(x: 0, y: self.headerView.frame.height + (self.profileTableView.frame.height - self.headerView.frame.height)/2 - 45, width: self.view.frame.width, height: 30))
                label.text = "投稿がまだありません"
                label.textAlignment = .center
                label.textColor = .lightGray
                label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
                self.profileTableView.addSubview(label)
                self.profileTableView.reloadData()
            }else{
                guard let lastSnapShot = querySnapshot!.documents.last else { return }
                self.lastDocument = lastSnapShot
                let mappedArray = self.contentsArray.map { Room -> String in
                    let documentID = Room.documentID
                    return documentID
                }
                self.fetchLikeContents(documentIDs: mappedArray)
            }
            comleted()
        }
    }
    
    
    
    
    
    
    func fetchMoreContents(){
        guard let lastDoc = self.lastDocument else {return}
        var contentsArray2 = [Contents]()
        contentsArray2.removeAll()
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).collection("posts").order(by: "createdAt", descending: true).start(afterDocument: lastDoc).limit(to: 5).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("取得に失敗しました。\(err)")
                return
            }
            guard let lastSnapShot = querySnapshot!.documents.last else { return }
            if lastSnapShot == self.lastDocument {
                return
            }else{
                self.lastDocument = lastSnapShot
            }
            for document in querySnapshot!.documents {
                let dic = document.data()
                let content = Contents.init(dic: dic)
                self.contentsArray.append(content)
                contentsArray2.append(content)
            }
            if contentsArray2.count != 0 {
                let mappedArray = contentsArray2.map { Room -> String in
                    let documentID = Room.documentID
                    return documentID
                }
                self.fetchLikeContents(documentIDs: mappedArray)
            }
        }
    }
    
    
    
    func fetchPostCount(){
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).collection("profilePostCount").document("count").getDocument { snapShot, err in
            if let err = err {
                print("false\(err)")
                return
            }
            guard let snapShot = snapShot,let dic = snapShot.data() else {return}
            let postCount = Contents(dic: dic)
            self.postCount = postCount
            self.headerView.postCountLabel.text = self.postCount?.postCount.description
        }
    }
    
    
    
    
    
    func fetchLikeCount(){
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).collection("profileLikeCount").document("count").getDocument { snapShot, err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                guard let snap = snapShot,let dic = snap.data() else {return}
                let likedCount = Contents(dic: dic)
                self.postCount = likedCount
                self.headerView.likeCountLabel.text = self.postCount?.likeCount.description
            }
        }
    }
    
    
    
    
    func fetchUserInfo(){
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).getDocument { (snapShot, err) in
            if let err = err {
                print("情報の取得に失敗しました。\(err)")
                return
            }
            guard let snapShot = snapShot,let dic = snapShot.data() else {return}
            let userInfo = Contents(dic: dic)
            self.userInfo = userInfo
            
            self.titleName.text = self.userInfo?.roomName
            self.titleName.adjustsFontSizeToFitWidth = true
            self.titleName.minimumScaleFactor = 0.9
            self.headerView.userNameLabel.text = self.userInfo?.userName
            if self.userInfo?.userImage != "" {
                self.headerView.userImageView.sd_setImage(with: URL(string: self.userInfo!.userImage), completed: nil)
                self.headerView.personImageView.image = UIImage()
                self.profileTableView.reloadData()
            }
        }
    }
    
    
}




extension ProfileViewController:UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return contentsArray.count
    }
    
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let cell = profileTableView.dequeueReusableCell(withIdentifier: "postTable")  as! PostTableViewCell
        cell.selectionStyle = .none
        
        let userName = cell.postProfileName!
        userName.text = userInfo?.userName
        
        let userImage = cell.postProfileImage!
        userImage.layer.cornerRadius = userImage.frame.height/2
        
        
        if self.userInfo?.userImage != "" {
            userImage.sd_setImage(with: URL(string: userInfo?.userImage ?? ""), completed: nil)
            cell.personImage.image = UIImage()
        }
        
        let comment = cell.postCommentLabel!
        let text = contentsArray[indexPath.row].text
        comment.text = text
        if text == "" {
            cell.postCommentHeight.constant = 0
        }
        
        let postImage = cell.MyPostImage!
        let postImage2 = cell.myPostImage2!
        let underView = cell.underView!
        let singleView = cell.singlePostImage!
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedPhoto(_:)))
        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(tappedPhoto(_:)))
        
        
        
        
        if self.contentsArray[indexPath.row].mediaArray[0]  == "" {
            
            
            cell.underHeight.constant = 0
            
        }else {
            cell.underHeight.constant = 210 * underView.frame.width / 340
        }
        
        
        
        if self.contentsArray[indexPath.row].mediaArray.count == 1 {
            
            singleView.isHidden = false
            postImage.isHidden = true
            postImage2.isHidden = true
            
            singleView.sd_setImage(with: URL(string: contentsArray[indexPath.row].mediaArray[0] ), completed: nil)
            underView.addSubview(singleView)
            singleView.layer.cornerRadius = 8
            singleView.layer.borderWidth = 1
            singleView.layer.borderColor = UIColor.systemGray6.cgColor
            singleView.addGestureRecognizer(tapGesture)
            
        }
        
        if self.contentsArray[indexPath.row].mediaArray.count == 2 {
            
            singleView.isHidden = true
            postImage.isHidden = false
            postImage2.isHidden = false
            
            
            postImage.sd_setImage(with: URL(string: contentsArray[indexPath.row].mediaArray[0] ), completed: nil)
            underView.addSubview(postImage)
            postImage.layer.cornerRadius = 8
            postImage.layer.borderWidth = 1
            postImage.layer.borderColor = UIColor.systemGray6.cgColor
            postImage.addGestureRecognizer(tapGesture)
            
            
            
            postImage2.sd_setImage(with: URL(string: contentsArray[indexPath.row].mediaArray[1] ), completed: nil)
            underView.addSubview(postImage2)
            postImage2.layer.cornerRadius = 8
            postImage2.layer.borderWidth = 1
            postImage2.layer.borderColor = UIColor.systemGray6.cgColor
            postImage2.addGestureRecognizer(tapGesture2)
        }
        
        let createTime = cell.createdAt!
        let timestamp = contentsArray[indexPath.row].createdAt
        let dt = timestamp.dateValue()
        let dt2 = Date()
        let cal = Calendar(identifier: .gregorian)
        let diff = cal.dateComponents([.day,.hour,.minute,.second], from: dt, to: dt2)
        let day = diff.day
        let hour = diff.hour
        let minute = diff.minute
        let second = diff.second
        
        
        if day == 0 && hour == 0 && minute == 0    {
            createTime.text = "\(second?.description ?? "")秒前"
        }else if day == 0 && hour == 0 && minute != 0{
            createTime.text = "\(minute?.description ?? "")分前"
        }else if day == 0 && hour != 0 {
            createTime.text = "\(hour?.description ?? "")時間前"
        }else if day != 0 {
            createTime.text = "\(day?.description ?? "")日前"
        }
        
        let likeCountLabel = cell.likeCountLabel!
        likeCountLabel.text = contentsArray[indexPath.row].likeCount.description
        
        let commentCountLabel = cell.commentCountLabel!
        commentCountLabel.text = contentsArray[indexPath.row].commentCount.description
        
        
        let likeCheck = likeContentsArray.filter {
            $0.documentID == contentsArray[indexPath.row].documentID
        }
        
        
        if likeCheck.isEmpty == true {
            cell.likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
            cell.likeButton.tintColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
            
            
        }else {
            cell.likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            cell.likeButton.tintColor = .red
            
        }
        
        
        
        
        cell.likeButton.addTarget(self, action: #selector(pushedLikeButton(_:)), for: .touchUpInside)
        cell.likeButton.tag = indexPath.row
        cell.likeCountLabel.tag = indexPath.row+10000000000000
        
        cell.reportButton.addTarget(self, action: #selector(pushedReportButton), for: .touchUpInside)
        cell.reportButton.tag = indexPath.row-10000000000000
        
        cell.commentButton.addTarget(self, action: #selector(pushedCommentButton(_:)), for: .touchUpInside)
        cell.commentButton.tag = -indexPath.row
        
        return cell
    }
    
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == contentsArray.count {
            fetchMoreContents()
        }
    }
    
    
    
    
    
    //likeBatch
    
    func createLikeContents(sender:UIButton,batch:WriteBatch){
        let row = sender.tag
        let uid = Auth.auth().currentUser!.uid
        let documentID = contentsArray[row].documentID
        let roomID = passedDocumentID
        let postedAt = contentsArray[row].createdAt
        let timestamp = Timestamp()
        let docData = ["media": contentsArray[row].mediaArray,"text":contentsArray[row].text,"userImage":contentsArray[row].userImage,"userName":contentsArray[row].userName,"documentID":documentID,"roomID":roomID,"uid":uid,"postedAt":postedAt,"createdAt":timestamp,"myUid":uid] as [String:Any]
        let ref = Firestore.firestore().collection("users").document(uid).collection("likes").document(documentID)
        batch.setData(docData, forDocument: ref)
    }
    
    
    
    func updateLikeCount(sender:UIButton,batch:WriteBatch){
        let documentID = contentsArray[sender.tag].documentID
        let roomID = passedDocumentID
        let uid = Auth.auth().currentUser!.uid
        
        let profileRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("posts").document(documentID)
        batch.setData(["likeCount": FieldValue.increment(1.0)], forDocument: profileRef, merge: true)
        
        let likeCountRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("profileLikeCount").document("count")
        batch.setData(["likeCount": FieldValue.increment(1.0)], forDocument: likeCountRef, merge: true)
        
        if contentsArray[sender.tag].mediaArray[0] != "" {
            let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
            batch.updateData(["likeCount":FieldValue.increment(1.0)], forDocument: mediaPostRef)
        }
    }
    
    
    
    func likeBatch(sender:UIButton){
        let batch = Firestore.firestore().batch()
        createLikeContents(sender: sender, batch: batch)
        updateLikeCount(sender: sender, batch: batch)
        batch.commit()
    }
    
    
    
    
    
    
    
    
    
    
    //deleteBatch
    
    func decreaseLikeCount(sender: UIButton,batch:WriteBatch){
        let documentID = contentsArray[sender.tag].documentID
        let roomID = passedDocumentID
        let uid = Auth.auth().currentUser!.uid
        
        let profileContentRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).collection("posts").document(documentID)
        batch.setData(["likeCount": FieldValue.increment(-1.0)], forDocument: profileContentRef, merge: true)
        
        let likeCountRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).collection("profileLikeCount").document("count")
        batch.setData(["likeCount": FieldValue.increment(-1.0)], forDocument: likeCountRef, merge: true)
        
        if contentsArray[sender.tag].mediaArray[0] != "" {
            let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
            batch.updateData(["likeCount":FieldValue.increment(-1.0)], forDocument: mediaPostRef)
        }
    }
    
    
    
    
    func deleteLikeContents(sender:UIButton,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let documentID = contentsArray[sender.tag].documentID
        let ref = Firestore.firestore().collection("users").document(uid).collection("likes").document(documentID)
        batch.deleteDocument(ref)
    }
    

    
    
    func deleteLikeBatch(sender:UIButton){
        let batch = Firestore.firestore().batch()
        let documentID = contentsArray[sender.tag].documentID
        decreaseLikeCount(sender: sender, batch: batch)
        deleteLikeContents(sender: sender, batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                print("scuccess")
                self.likeContentsArray.removeAll(where: {$0.documentID == documentID})
            }
        }
    }
    
    
    
    
    
    
    
    
    @objc func pushedLikeButton(_ sender:UIButton){
        
        if sender.tintColor == UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1) {
            sender.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            sender.tintColor = .red
            likeBatch(sender: sender)
            
            if let countLabel = sender.superview?.viewWithTag(sender.tag+10000000000000) as? UILabel {
                var count = Int(contentsArray[sender.tag].likeCount)
                count += 1
                countLabel.text = count.description
                contentsArray[sender.tag].likeCount = count
            }
            
        }else if sender.tintColor == .red{
            
            sender.setImage(UIImage(systemName: "heart"), for: .normal)
            sender.tintColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
            deleteLikeBatch(sender: sender)
            
            if let countLabel = sender.superview?.viewWithTag(sender.tag+10000000000000) as? UILabel {
                var count = Int(countLabel.text!)!
                count -= 1
                countLabel.text = count.description
                contentsArray[sender.tag].likeCount = count
                
            }
        }
    }
    
    
    
    
    
    @objc func pushedReportButton(_ sender:UIButton){
        row = sender.tag+10000000000000
        blurView.isHidden = false
        deleteContentButton.isHidden = false
        cancelView.isHidden = false
        tabBarController?.tabBar.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        blurView.addGestureRecognizer(tapGesture)
        
    }
    
    
    
    @objc func pushedCommentButton(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let cLVC = storyboard.instantiateViewController(withIdentifier: "commentList") as! CommentListViewController
        let uid = Auth.auth().currentUser!.uid
        
        cLVC.passedUserImage = self.userInfo!.userImage
        cLVC.passedUserName = self.userInfo!.userName
        cLVC.passedComment = contentsArray[-sender.tag].text
        cLVC.passedDate = contentsArray[-sender.tag].createdAt
        cLVC.passedMyImage = headerView.userImageView.image ?? UIImage()
        cLVC.passedRoomName = titleName.text!
        cLVC.passedDocumentID = contentsArray[-sender.tag].documentID
        cLVC.passedRoomID = passedDocumentID
        cLVC.passedUid = uid
        cLVC.passedMediaArray = contentsArray[-sender.tag].mediaArray
        cLVC.hidesBottomBarWhenPushed = true
        present(cLVC, animated: true, completion: nil)
        
    }
    
    
    
    @objc func tappedPhoto(_ sender: UITapGestureRecognizer){
        let tappedLocation = sender.location(in: profileTableView)
        let tappedIndexPath = profileTableView.indexPathForRow(at: tappedLocation)
        let tappedRow = tappedIndexPath?.row
        let uid = Auth.auth().currentUser!.uid
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let showImageVC = storyboard.instantiateViewController(identifier: "showImage") as! ShowImageViewController
        
        showImageVC.passedMedia = contentsArray[tappedRow!].mediaArray
        showImageVC.passedUid = uid
        showImageVC.passedText = contentsArray[tappedRow!].text
        showImageVC.passedUserImage = self.userInfo!.userImage
        showImageVC.passedUserName = self.userInfo!.userName
        
        present(showImageVC, animated: true, completion: nil)
    }
    
    
    
    
}










