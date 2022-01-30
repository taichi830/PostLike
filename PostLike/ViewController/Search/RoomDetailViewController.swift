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
    
    private var label = MessageLabel()
    private var contentsArray = [Contents]()
//    private var reportedUsersArray = [Contents]()
//    private var reportedContentsArray = [Contents]()
    private var likeContentsArray = [Contents]()
    private var joinedRoom:Contents?
    private var roomInfo:Room?
//    private var memberCount:Room?
    private var lastDocument:QueryDocumentSnapshot?
    private lazy var indicator:UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.center = roomImageView.center
        indicator.style = .medium
        indicator.color = .white
        indicator.hidesWhenStopped = true
        roomImageView.addSubview(indicator)
        return indicator
    }()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.contentsTableView.delegate = self
        self.contentsTableView.dataSource = self
        self.contentsTableView.register(UINib(nibName: "FeedTableViewCell", bundle: nil), forCellReuseIdentifier: "FeedTableViewCell")
        self.contentsTableView.contentInsetAdjustmentBehavior = .never
        let refleshControl = CustomRefreshControl()
        self.contentsTableView.refreshControl = refleshControl
        self.contentsTableView.refreshControl?.addTarget(self, action: #selector(updateContents), for: .valueChanged)
        
        backButtonBackView.layer.cornerRadius = 15
        dotButtonBackView.layer.cornerRadius = 15
        
        
        headerView.joinButton.clipsToBounds = true
        headerView.joinButton.layer.cornerRadius = 18
        headerView.joinButton.layer.borderWidth = 1
        headerView.joinButton.layer.borderColor = UIColor.systemGray5.cgColor
        headerView.joinButton.addTarget(self, action: #selector(pushedJoinButton(_:)), for: .touchUpInside)
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
        contentsTableView.addGestureRecognizer(swipeGesture)
        
        roomName.adjustsFontSizeToFitWidth = true
        roomName.minimumScaleFactor = 0.9
        
        self.headerView.roomName.adjustsFontSizeToFitWidth = true
        self.headerView.roomName.minimumScaleFactor = 0.7
        
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
    
    
    
    
    
    
    @objc private func updateContents(){
        indicator.startAnimating()
        self.contentsArray.removeAll()
        self.likeContentsArray.removeAll()
        fetchContents {
            self.contentsTableView.refreshControl?.endRefreshing()
            self.indicator.stopAnimating()
            self.contentsTableView.reloadData()
        }
    }
    
    
    
    
    
    private func setupHeaderView(){
        if let tableHeaderView = headerView {
            let size = tableHeaderView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            tableHeaderView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            self.contentsTableView.tableHeaderView = tableHeaderView
        }
    }
    
    
    
    @IBAction private func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    @IBAction private func reportButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
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
        if self.joinedRoom?.documentID == "" {
            let modalVC = self.storyboard?.instantiateViewController(withIdentifier: "modal") as! CreateProfileModalViewController
            modalVC.modalPresentationStyle = .custom
            modalVC.transitioningDelegate = self
            modalVC.createProfileDelegate = self
            present(modalVC, animated: true, completion: nil)
            
        }else if self.joinedRoom?.isJoined == false {
            creatProfileWhenHaveCreated()
            
        } else {
            let storyboard = UIStoryboard(name: "Home", bundle: nil)
            let enteredVC = storyboard.instantiateViewController(identifier: "enteredVC") as! EnteredRoomContentViewController
            enteredVC.passedDocumentID = roomInfo!.documentID
            navigationController?.pushViewController(enteredVC,animated: false)
        }
    }
    
    
    
    
    @objc private func tappedbluredView(_ sender: UITapGestureRecognizer){
        tabBarController?.tabBar.isHidden = false
    }
    
    
    
    
    
    
    private func fetchRoomInfo(){
        Firestore.fetchRoomInfo(roomID: passedDocumentID) { roomInfo in
            if roomInfo?.documentID == "" {
                self.fetchContents {
                    self.contentsTableView.reloadData()
                }
                self.headerView.joinButton.isEnabled = false
                self.headerView.joinButton.backgroundColor = .systemBackground
                self.headerView.joinButton.setTitleColor(.lightGray, for: .normal)
                self.headerView.roomName.text = "このルームは削除されました"
                self.headerView.roomName.textColor = .lightGray
                self.headerView.roomName.font = UIFont.systemFont(ofSize: 17, weight: .regular)
                self.setupHeaderView()
            }else {
                self.roomInfo = roomInfo
                self.roomName.text = roomInfo?.roomName
                self.headerView.roomName.text = roomInfo?.roomName
                self.headerView.roomIntro.text = roomInfo?.roomIntro
                self.setupHeaderView()
                if roomInfo?.roomImage != "" {
                    self.roomImageView.sd_setImage(with: URL(string: roomInfo?.roomImage ?? ""), completed: nil)
                    self.headerView.roomImage.sd_setImage(with: URL(string: roomInfo?.roomImage ?? ""), completed: nil)
                }
                self.fetchContents {
                    self.contentsTableView.reloadData()
                }
            }
        }
    }
    
    
    
    
    
    
    private func fetchJoinedRoom(){
        Firestore.isJoinedCheck(roomID: passedDocumentID) { joinedRoom in
            if joinedRoom == nil {
                self.headerView.joinButton.setTitle("参加する", for: .normal)
                self.headerView.joinButton.setTitleColor(.white, for: .normal)
                self.headerView.joinButton.backgroundColor = .red
            } else if joinedRoom?.isJoined == false {
                self.joinedRoom = joinedRoom
                self.headerView.joinButton.setTitle("参加する", for: .normal)
                self.headerView.joinButton.setTitleColor(.white, for: .normal)
                self.headerView.joinButton.backgroundColor = .red
            } else {
                self.joinedRoom = joinedRoom
                self.headerView.joinButton.setTitle("ルームへ", for: .normal)
                self.headerView.joinButton.setTitleColor(.black, for: .normal)
                self.headerView.joinButton.backgroundColor = .systemBackground
            }
        }
    }
    
    
    
   
    
    
    
    
    
    private func fetchReportedContents(documentIDs:[String],_ completed: @escaping() -> Void){
        Firestore.fetchReportedContents(documentIDs: documentIDs) { contents in
            for content in contents {
                self.contentsArray.removeAll {
                    $0.documentID == content.documentID
                }
            }
            completed()
        }
    }
    
    
    
    
    
    private func fetchReportedUsers(uids:[String],_ completed: @escaping() -> Void){
        Firestore.fetchReportedUsers(uids: uids) { contents in
            for content in contents {
                self.contentsArray.removeAll { element in
                    element.uid == content.uid && element.roomID == content.roomID
                }
            }
            completed()
        }
    }
    
    
    
    private func fetchLikeContents(documentIDs:[String],_ completed: @escaping() -> Void){
        Firestore.fetchLikeContents(documentIDs: documentIDs) { contents in
            self.likeContentsArray.append(contentsOf: contents)
            completed()
        }
    }
    
    
    
    private func fetchContents(_ completed: @escaping() -> Void){
        self.contentsArray.removeAll()
        Firestore.fetchRoomContents(roomID: passedDocumentID, viewController: self) { querySnapshot, contents, uids, documentIDs in
            if contents.isEmpty == true {
                self.label.setupLabel(view: self.view, y: self.view.center.y)
                self.label.text = "投稿がまだありません"
                self.contentsTableView.addSubview(self.label)
                self.contentsTableView.reloadData()
                completed()
            }else{
                self.label.text = ""
                self.lastDocument = querySnapshot.documents.last
                self.contentsArray.append(contentsOf: contents)
                self.fetchReportedUsers(uids: uids) {
                    self.fetchReportedContents(documentIDs: documentIDs) {
                        self.fetchLikeContents(documentIDs: documentIDs) {
                            completed()
                        }
                    }
                }
            }
        }
    }
    
    
    private func fetchMoreContetns(){
        guard let lastDocument = lastDocument else {return}
        Firestore.fetchMoreRoomContents(roomID: passedDocumentID, lastDocument: lastDocument) { querySnapshot,contents,uids,documentIDs  in
            if contents.isEmpty == false {
                self.lastDocument = querySnapshot.documents.last
                self.contentsArray.append(contentsOf: contents)
                self.fetchReportedUsers(uids: uids) {
                    self.fetchReportedContents(documentIDs: documentIDs) {
                        self.fetchLikeContents(documentIDs: documentIDs) {
                            self.contentsTableView.reloadData()
                        }
                    }
                }
            }
        }
    }
   
    
    private func fetchMemberCount(){
        Firestore.fetchRoomMemberCount(roomID: passedDocumentID) { memberCount in
            self.headerView.numberCount.text = "メンバー \(String(describing: memberCount.numberOfMember))人"
        }
    }
    
    
    
    
    
    
    
    
    
    
    
}






extension RoomDetailViewController: UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = contentsTableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell", for: indexPath) as! FeedTableViewCell
        
        
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
        let documentID = contentsArray[row].documentID
        let dic = [
            "media": contentsArray[row].mediaArray,
            "text":contentsArray[row].text,
            "userImage":contentsArray[row].userImage,
            "userName":contentsArray[row].userName,
            "documentID":documentID,
            "roomID":passedDocumentID,
            "createdAt":Timestamp(),
            "uid":contentsArray[row].uid,
            "postedAt":contentsArray[row].createdAt,
            "myUid":myuid] as [String:Any]
        Firestore.createLikedPost(myuid: myuid, documentID: documentID, dic: dic, batch: batch)
    }
    
    
    
    private func updateLikeCount(row:Int,batch:WriteBatch){
        let documentID = contentsArray[row].documentID
        let roomID = contentsArray[row].roomID
        let uid = contentsArray[row].uid
        let myuid = Auth.auth().currentUser!.uid
        let mediaUrl = contentsArray[row].mediaArray[0]
        Firestore.increaseLikeCount(uid: uid, myuid: myuid, roomID: roomID, documentID: documentID, mediaUrl: mediaUrl, batch: batch)
    }
    
    
    
    private func giveNotification(row:Int,batch:WriteBatch){
        let uid = contentsArray[row].uid
        let myuid = Auth.auth().currentUser!.uid
        let postID = contentsArray[row].documentID
        let documentID = "\(myuid)-\(postID)"
        let dic = [
            "userName":joinedRoom?.userName ?? "",
            "userImage":joinedRoom?.userImage ?? "",
            "uid":myuid,
            "roomName":roomInfo?.roomName ?? "",
            "createdAt":Timestamp(),
            "postID":postID,
            "roomID":contentsArray[row].roomID,
            "documentID":documentID,
            "type":"like"] as [String:Any]
        Firestore.createNotification(uid: uid,myuid: myuid, documentID: documentID, dic: dic, batch: batch)
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
                self.likeContentsArray.append(self.contentsArray[row])
            }
        }
    }
    
    
    
    
    
    
    
    //いいねを解除した時の処理
    private func deleteLikeContents(row:Int,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let documentID = contentsArray[row].documentID
        Firestore.deleteLikedPost(uid: uid, documentID: documentID, batch: batch)
    }
    
    
    
    private func deleteLikeCount(row:Int,batch:WriteBatch){
        let documentID = contentsArray[row].documentID
        let roomID = contentsArray[row].roomID
        let uid = contentsArray[row].uid
        let myuid = Auth.auth().currentUser!.uid
        let mediaUrl = contentsArray[row].mediaArray[0]
        Firestore.decreaseLikeCount(uid: uid, myuid: myuid, roomID: roomID, documentID: documentID, mediaUrl: mediaUrl, batch: batch)
        
    }
    
    
    
    
    
    private func deleteNotification(row:Int,batch:WriteBatch){
        let uid = contentsArray[row].uid
        let myuid = Auth.auth().currentUser!.uid
        let postID = contentsArray[row].documentID
        let documentID = "\(myuid)-\(postID)"
        Firestore.deleteNotification(uid: uid, myuid: myuid, documentID: documentID, batch: batch)
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
        self.contentsArray.removeAll { content in
            return content.documentID == documentID
        }
        self.contentsTableView.reloadData()
    }
    
    
    func removeBlockedUserContents(uid:String,roomID:String){
        self.contentsArray.removeAll { content in
            return content.uid == uid && content.roomID == roomID
        }
        self.contentsTableView.reloadData()
    }
}




extension RoomDetailViewController:TableViewCellDelegate{
    func reportButton(row: Int) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
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
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
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
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
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



