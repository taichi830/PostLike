//
//  enteredRoomContentViewController.swift
//  postLike
//
//  Created by taichi on 2020/12/23.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

final class EnteredRoomContentViewController: UIViewController{
    
    
    
    @IBOutlet private weak var contentsTableView: UITableView!
    @IBOutlet private weak var backButtonBackButton: UIView! {
        didSet {
            backButtonBackButton.clipsToBounds = true
            backButtonBackButton.layer.cornerRadius = backButtonBackButton.frame.height/2
        }
    }
    @IBOutlet private weak var dotsButtonBackView: UIView! {
        didSet {
            dotsButtonBackView.clipsToBounds = true
            dotsButtonBackView.layer.cornerRadius = dotsButtonBackView.frame.height/2
        }
    }
    @IBOutlet private weak var headerView: RoomHeaderView!
    @IBOutlet private weak var headerViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var headerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var roomImageView: UIImageView!
    @IBOutlet private weak var topBlurEffect: UIVisualEffectView!
    @IBOutlet private weak var topRoomNameLabel: UILabel!
    @IBOutlet private weak var effectViewHeight: NSLayoutConstraint!
    
    
    var passedDocumentID = String()
    private var label = MessageLabel()
    private var roomInfo:Room?
    private var contentsArray = [Contents]()
    private var likeContentsArray = [Contents]()
    private var joinedRoom:Contents?
    private var lastDocument:QueryDocumentSnapshot?
    private var lastLikeDocument:QueryDocumentSnapshot?
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
        setupTableView()
        startIndicator()
        fetchContents {
            self.dismissIndicator()
            self.contentsTableView.reloadData()
        }
        setupHeaderView()
        self.setSwipeBackGesture()
        
        
        
        
    }
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchProfileInfo()
        roomExistCheck()
    }
    
    
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewWillLayoutSubviews()
        effectViewHeight.constant = self.view.safeAreaInsets.top + 46
    }
    
    
    
    
    
    private func setupHeaderView() {
        let tapGesure:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapMyprofile(_:)))
        tapGesure.delegate = self
        headerView.myProfileImageView.layer.cornerRadius = 15
        headerView.myProfileImageView.isUserInteractionEnabled = true
        headerView.myProfileImageView.addGestureRecognizer(tapGesure)
        
        headerView.imageCollectionButton.addTarget(self, action: #selector(tappedImageCollectionButton(_:)), for: .touchUpInside)
        headerView.postButton.addTarget(self, action: #selector(tappedPostButton(_:)), for: .touchUpInside)
    }
    
    
    
    
    
    @objc private func tappedImageCollectionButton(_ sender:UIButton){
        let imageVC = storyboard?.instantiateViewController(withIdentifier: "images") as! RoomImageContentsViewController
        imageVC.passedRoomID = passedDocumentID
        imageVC.passedRoomName = headerView.roomNameLabel.text ?? ""
        navigationController?.pushViewController(imageVC, animated: true)
    }
    
    
    
    
    
    @objc private func tappedPostButton(_ sender:UIButton){
        let postVC = storyboard?.instantiateViewController(withIdentifier: "postVC") as! PostViewController
        postVC.passedRoomTitle = self.headerView.roomNameLabel.text!
        postVC.passedDocumentID = self.roomInfo?.documentID ?? ""
        postVC.passedHostUid = self.roomInfo?.moderator ?? ""
        postVC.passedUserImageUrl = self.joinedRoom?.userImage ?? ""
        postVC.passedUserName = self.joinedRoom?.userName ?? ""
        present(postVC, animated: true, completion: nil)
    }
    
    
    
    
    
    @objc private func tapMyprofile(_ sender: UITapGestureRecognizer){
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        let myproVC = storyboard.instantiateViewController(withIdentifier: "myproVC") as! ProfileViewController
        myproVC.passedDocumentID = passedDocumentID
        myproVC.passedModerator = roomInfo?.moderator ?? ""
        navigationController?.pushViewController(myproVC, animated: true)
    }
    
    
    
    
    
    
    
    private func setupTableView(){
        contentsTableView.delegate = self
        contentsTableView.dataSource = self
        contentsTableView.tableHeaderView =  headerView
        contentsTableView.register(UINib(nibName: "FeedTableViewCell", bundle: nil), forCellReuseIdentifier: "FeedTableViewCell")
        contentsTableView.contentInsetAdjustmentBehavior = .never
        let refleshControl = CustomRefreshControl()
        contentsTableView.refreshControl = refleshControl
        contentsTableView.refreshControl?.addTarget(self, action: #selector(updateContents), for: .valueChanged)
        
    }
    
    
    
    
    
    
    
    
    
    @objc private func updateContents(){
        indicator.startAnimating()
        self.contentsArray.removeAll()
        self.likeContentsArray.removeAll()
        roomExistCheck()
        fetchProfileInfo()
        fetchContents {
            self.contentsTableView.refreshControl?.endRefreshing()
            self.indicator.stopAnimating()
            self.contentsTableView.reloadData()
        }
    }
    
    
    
    
    
    
    @IBAction private func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    
    @IBAction private func menuButton(_ sender: Any) {
        let modalMenuVC = storyboard?.instantiateViewController(withIdentifier: "modalMenu") as! ModalMenuViewController
        modalMenuVC.modalPresentationStyle = .custom
        modalMenuVC.transitioningDelegate = self
        modalMenuVC.passedRoomID = passedDocumentID
        modalMenuVC.passedViewController = self
        modalMenuVC.passedType = ModalType.room.rawValue
        modalMenuVC.passedRoomImageUrl = roomInfo?.roomImage ?? ""
        modalMenuVC.passedRoomName = roomInfo?.roomName ?? ""
        modalMenuVC.passedRoomIntro = roomInfo?.roomIntro ?? ""
        modalMenuVC.passedRoomImage = roomImageView.image ?? UIImage()
        present(modalMenuVC, animated: true, completion: nil)
    }
    
    
    
    
    
    private func fetchProfileInfo(){
        Firestore.isJoinedCheck(roomID: passedDocumentID) { joinedRoom in
            if joinedRoom?.isJoined == false {
                self.headerView.postButton.isEnabled = false
                self.headerView.postButton.tintColor = .lightGray
                self.headerView.myProfileImageView.isUserInteractionEnabled = false
                self.headerView.memberLabel.text = "このルームから退出しました"
            }else {
                self.joinedRoom = joinedRoom
                if joinedRoom?.userImage == "" {
                    self.headerView.myProfileImageView.image = UIImage(systemName: "person.fill")
                }else{
                    self.headerView.myProfileImageView.sd_setImage(with: URL(string: joinedRoom?.userImage ?? ""), completed: nil)
                }
            }
        }
    }
    
    
    
    
    
    private func roomExistCheck(){
        Firestore.fetchRoomInfo(roomID: passedDocumentID) { roomInfo in
            if roomInfo?.documentID == "" {
                self.headerView.postButton.isEnabled = false
                self.headerView.postButton.tintColor = .lightGray
                self.headerView.myProfileImageView.isUserInteractionEnabled = false
                self.headerView.memberLabel.text = "このルームは削除されました"
            }else {
                self.roomInfo = roomInfo
                self.fetchMemberCount()
                self.roomImageView.sd_setImage(with: URL(string: self.roomInfo?.roomImage ?? ""), completed: nil)
                self.headerView.bluredImageView.sd_setImage(with: URL(string: self.roomInfo?.roomImage ?? ""), completed: nil)
                
                self.headerView.roomNameLabel.text = self.roomInfo?.roomName
                self.headerView.roomNameLabel.adjustsFontSizeToFitWidth = true
                self.headerView.roomNameLabel.minimumScaleFactor = 0.8
                
                self.topRoomNameLabel.text = self.roomInfo?.roomName
                self.topRoomNameLabel.adjustsFontSizeToFitWidth = true
                self.topRoomNameLabel.minimumScaleFactor = 0.8
            }
        }
    }
    
    
    
    
    
    
    
    
    private func fetchMemberCount(){
        Firestore.fetchRoomMemberCount(roomID: passedDocumentID) { memberCount in
            self.headerView.memberLabel.text = "メンバー \(String(describing: memberCount.numberOfMember))人"
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
        Firestore.fetchRoomContents(roomID: passedDocumentID, viewController: self) { querySnapshot,contents,uids,documentIDs  in
            if contents.isEmpty == true {
                self.label.setup(text: "投稿がまだありません。", at: self.contentsTableView)
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
    
    
    
    
}





extension EnteredRoomContentViewController: UITableViewDelegate,UITableViewDataSource{
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if contentsArray.count == 0 {
            return 0
        }else{
            return contentsArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = contentsTableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell")  as! FeedTableViewCell
        
        cell.tableViewCellDelegate = self
        
        cell.setContent(contents: contentsArray[indexPath.row], likeContensArray: likeContentsArray)
        
        
        return cell
    }
    
    
    
    
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath.row + 1 == self.contentsArray.count - 8) && self.contentsArray.count == 10 {
            fetchMoreContetns()
        }
    }
    
    
    
    
    
    //MARK: いいねした時の処理
    private func createLikeContents(row:Int,batch:WriteBatch){
        let myuid = Auth.auth().currentUser!.uid
        let uid = contentsArray[row].uid
        let timestamp = Timestamp()
        let documentID = contentsArray[row].documentID
        let postedAt = contentsArray[row].createdAt
        let dic = [
            "media": contentsArray[row].mediaArray,
            "text":contentsArray[row].text,
            "userImage":contentsArray[row].userImage,
            "userName":contentsArray[row].userName,
            "documentID":documentID,
            "roomID":passedDocumentID,
            "createdAt":timestamp,
            "uid":uid,
            "postedAt":postedAt,
            "myUid":myuid
        ] as [String:Any]
        
        Firestore.createLikedPost(myuid: myuid, documentID: documentID, dic: dic, batch: batch)
    }
    
    
    
    private func updateLikeCount(row:Int,batch:WriteBatch){
        let myuid = Auth.auth().currentUser!.uid
        let uid = contentsArray[row].uid
        let documentID = contentsArray[row].documentID
        let roomID = contentsArray[row].roomID
        let mediaArray = contentsArray[row].mediaArray[0]
        Firestore.increaseLikeCount(uid: uid, myuid: myuid, roomID: roomID, documentID: documentID, mediaUrl: mediaArray, batch: batch)
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
            "roomName":self.roomInfo!.roomName,
            "createdAt":Timestamp(),
            "postID":postID,
            "roomID":contentsArray[row].roomID,
            "documentID":documentID,
            "type":"like"
        ] as [String:Any]
        Firestore.createNotification(uid: uid, myuid: myuid, documentID: documentID, dic: dic, batch: batch)
    }
    
    
    
    private func likeBatch(row:Int){
        let batch = Firestore.firestore().batch()
        createLikeContents(row: row, batch: batch)
        updateLikeCount(row: row, batch: batch)
        giveNotification(row: row, batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                print("scucces")
                let likedContent = self.contentsArray[row]
                self.likeContentsArray.append(likedContent)
            }
        }
    }
    
    
    
    
    
    
    //MARK: いいねをやめた時の処理
    private func deleteLikeContents(row:Int,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let documentID = contentsArray[row].documentID
        Firestore.deleteLikedPost(uid: uid, documentID: documentID, batch: batch)
    }
    
    
    
    private func deleteLikeCount(row:Int,batch:WriteBatch){
        let myuid = Auth.auth().currentUser!.uid
        let uid = contentsArray[row].uid
        let documentID = contentsArray[row].documentID
        let roomID = contentsArray[row].roomID
        let mediaArray = contentsArray[row].mediaArray[0]
        Firestore.decreaseLikeCount(uid: uid, myuid: myuid, roomID: roomID, documentID: documentID, mediaUrl: mediaArray, batch: batch)
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
        deleteLikeContents(row: row, batch: batch)
        deleteLikeCount(row: row, batch: batch)
        deleteNotification(row: row, batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                print("scucces")
                self.likeContentsArray.removeAll(where: {$0.documentID == documentID})
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
}





extension EnteredRoomContentViewController:TableViewCellDelegate {
    func reportButton(row: Int) {
        let modalMenuVC = storyboard!.instantiateViewController(withIdentifier: "modalMenu") as! ModalMenuViewController
        modalMenuVC.modalPresentationStyle = .custom
        modalMenuVC.transitioningDelegate = self
        modalMenuVC.passedDocumentID = contentsArray[row].documentID
        modalMenuVC.passedRoomID = contentsArray[row].roomID
        modalMenuVC.passedUid = contentsArray[row].uid
        modalMenuVC.passedViewController = self
        modalMenuVC.passedType = "post"
        present(modalMenuVC, animated: true, completion: nil)
    }
    
    func tappedPostImageView(row: Int) {
        let showImageVC = storyboard?.instantiateViewController(identifier: "showImage") as! ShowImageViewController
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
        let cLVC = storyboard?.instantiateViewController(withIdentifier: "commentList") as! CommentViewController
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







extension EnteredRoomContentViewController:RemoveContentsDelegate{
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



extension EnteredRoomContentViewController:UIViewControllerTransitioningDelegate{
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentModalViewController(presentedViewController: presented, presenting: presenting)
    }
}








extension EnteredRoomContentViewController:UIScrollViewDelegate,UIGestureRecognizerDelegate{
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0 {
            self.headerViewHeight.constant = -(scrollView.contentOffset.y - 180)
            self.headerViewTopConstraint.constant = 0
        }else{
            self.headerViewHeight.constant = 180
            self.headerViewTopConstraint.constant = -scrollView.contentOffset.y
        }
        
        //下にスクロールに合わせて徐々にblurをかける
        topBlurEffect.alpha = -0.7 + (scrollView.contentOffset.y - 50)/50
        
        
    }
    
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
    
    
    
    
    
}
