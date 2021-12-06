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

class EnteredRoomContentViewController: UIViewController{
    
    
    
    @IBOutlet weak var contentsTableView: UITableView!
    @IBOutlet weak var backButtonBackButton: UIView!
    @IBOutlet weak var dotsButtonBackView: UIView!
    @IBOutlet weak var headerView: RoomHeaderView!
    @IBOutlet weak var headerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var headerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var roomImageView: UIImageView!
    @IBOutlet weak var topBlurEffect: UIVisualEffectView!
    @IBOutlet weak var topRoomNameLabel: UILabel!
    @IBOutlet weak var effectViewHeight: NSLayoutConstraint!
    
    
    var passedDocumentID = String()
    private var contentsArray = [Contents]()
    private var profileArray = [Room]()
    private var likeContentsArray = [Contents]()
    private var reportedContentsArray = [Contents]()
    private var reportedUsersArray = [Contents]()
    private var roomInfo:Room?
    private var profileInfo:Contents?
    private var lastDocument:QueryDocumentSnapshot?
    private var lastLikeDocument:QueryDocumentSnapshot?
    private var label = UILabel()
    private var memberCount:Room?
    private var indicator = UIActivityIndicatorView()
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        startIndicator()
        fetchContents {
            self.dismissIndicator()
            self.contentsTableView.reloadData()
        }
        
        let tapGesure:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapMyprofile(_:)))
        tapGesure.delegate = self
        headerView.myProfileImageView.layer.cornerRadius = 15
        headerView.myProfileImageView.isUserInteractionEnabled = true
        headerView.myProfileImageView.addGestureRecognizer(tapGesure)
        
        headerView.imageCollectionButton.addTarget(self, action: #selector(tappedImageCollectionButton(_:)), for: .touchUpInside)
        headerView.postButton.addTarget(self, action: #selector(tappedPostButton(_:)), for: .touchUpInside)
        
        backButtonBackButton.clipsToBounds = true
        backButtonBackButton.layer.cornerRadius = backButtonBackButton.frame.height/2
        
        dotsButtonBackView.clipsToBounds = true
        dotsButtonBackView.layer.cornerRadius = dotsButtonBackView.frame.height/2
        
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
    
    
    
    
    
    
    private func setupTableView(){
        contentsTableView.delegate = self
        contentsTableView.dataSource = self
        contentsTableView.tableHeaderView =  headerView
        contentsTableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: "postTable")
        contentsTableView.contentInsetAdjustmentBehavior = .never
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
        contentsTableView.addGestureRecognizer(swipeGesture)
        
        let refleshControl = CustomRefreshControl()
        indicator.center = roomImageView.center
        indicator.style = .medium
        indicator.color = .white
        indicator.hidesWhenStopped = true
        roomImageView.addSubview(indicator)
        contentsTableView.refreshControl = refleshControl
        contentsTableView.refreshControl?.addTarget(self, action: #selector(updateContents), for: .valueChanged)
    }
    
    

    
    

    
    
    
    
    @objc private func tappedImageCollectionButton(_ sender:UIButton){
        let imageVC = storyboard?.instantiateViewController(withIdentifier: "images") as! RoomImageContentsViewController
        imageVC.passedRoomID = passedDocumentID
        imageVC.passedRoomName = headerView.roomNameLabel.text ?? ""
        navigationController?.pushViewController(imageVC, animated: true)
    }
    
    
    
    
    
    @objc func tappedPostButton(_ sender:UIButton){
        let postVC = storyboard?.instantiateViewController(withIdentifier: "postVC") as! PostViewController
        postVC.passedRoomTitle = self.headerView.roomNameLabel.text!
        postVC.passedDocumentID = self.roomInfo!.documentID
        postVC.passedHostUid = self.roomInfo!.moderator
        postVC.passedUserImageUrl = self.profileInfo!.userImage
        postVC.passedUserName = self.profileInfo!.userName
        present(postVC, animated: true, completion: nil)
    }
    
    
    
    
    
    @objc func tapMyprofile(_ sender: UITapGestureRecognizer){
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        let myproVC = storyboard.instantiateViewController(withIdentifier: "myproVC") as! ProfileViewController
        myproVC.passedDocumentID = passedDocumentID
        myproVC.passedModerator = roomInfo?.moderator ?? ""
        navigationController?.pushViewController(myproVC, animated: true)
    }
    
    
    
    
    
    
    @objc private func swiped(_ sender:UISwipeGestureRecognizer){
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    
    @objc private func updateContents(){
        roomExistCheck()
        fetchProfileInfo()
        indicator.startAnimating()
        self.likeContentsArray.removeAll()
        fetchContents {
            self.contentsTableView.refreshControl?.endRefreshing()
            self.indicator.stopAnimating()
            self.contentsTableView.reloadData()
        }
    }
    
    
    
    
    
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    
    @IBAction func menuButton(_ sender: Any) {
        let modalMenuVC = storyboard?.instantiateViewController(withIdentifier: "modalMenu") as! ModalMenuViewController
        modalMenuVC.modalPresentationStyle = .custom
        modalMenuVC.transitioningDelegate = self
        modalMenuVC.passedRoomID = passedDocumentID
        modalMenuVC.passedViewController = self
        modalMenuVC.passedType = "room"
        modalMenuVC.passedRoomImageUrl = roomInfo?.roomImage ?? ""
        modalMenuVC.passedRoomName = roomInfo?.roomName ?? ""
        modalMenuVC.passedRoomIntro = roomInfo?.roomIntro ?? ""
        modalMenuVC.passedRoomImage = roomImageView.image ?? UIImage()
        present(modalMenuVC, animated: true, completion: nil)
    }
    
    
  
    
    
    private func fetchProfileInfo(){
        let uid = Auth.auth().currentUser!.uid
        
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).getDocument { snapShot, err in
            if let err = err {
                print("false\(err)")
                return
            }
            guard let snapShot = snapShot,let dic = snapShot.data() else {return}
            let profileInfo = Contents(dic: dic)
            self.profileInfo = profileInfo
            if  self.profileInfo?.isJoined == false {
                self.headerView.postButton.isEnabled = false
                self.headerView.postButton.tintColor = .lightGray
                self.headerView.myProfileImageView.isUserInteractionEnabled = false
                self.headerView.memberLabel.text = "このルームから退出しました"
            }else{
                if self.profileInfo?.userImage == "" {
                    self.headerView.myProfileImageView.image = UIImage(systemName: "person.fill")
                }else{
                    self.headerView.myProfileImageView.sd_setImage(with: URL(string: self.profileInfo!.userImage), completed: nil)
                }
            }
        }
    }
    
    
    
    
    
    private func roomExistCheck(){
        Firestore.firestore().collection("rooms").document(passedDocumentID).getDocument { (snapShot, err) in
            if let err = err {
                print("false\(err)")
                return
            }
            if snapShot?.exists == nil {
                self.headerView.postButton.isEnabled = false
                self.headerView.postButton.tintColor = .lightGray
                self.headerView.myProfileImageView.isUserInteractionEnabled = false
                self.headerView.memberLabel.text = "このルームは削除されました"
            }else{
                guard let snapShot = snapShot,let dic = snapShot.data() else {return}
                let roomInfo = Room.init(dic: dic)
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
    
    
    
    
    
    
    
    
   private  func fetchMemberCount(){
        Firestore.firestore().collection("rooms").document(passedDocumentID).collection("memberCount").document("count").getDocument { snapShot, err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                guard let snap = snapShot,let dic = snap.data() else {return}
                let memberCount = Room.init(dic: dic)
                self.memberCount = memberCount
                self.headerView.memberLabel.text = "メンバー \(String(describing: self.memberCount!.numberOfMember))人"
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
        let cell = contentsTableView.dequeueReusableCell(withIdentifier: "postTable")  as! PostTableViewCell
        
        cell.tableViewCellDelegate = self
        
        cell.setContent(contents: contentsArray[indexPath.row], likeContensArray: likeContentsArray)
        
        
        return cell
    }
    
    
    
    
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if ((indexPath.row + 1) == (self.contentsArray.count - 8)) && self.contentsArray.count == 10 {
            fetchMoreContetns()
        }
    }
    
    
    
   
    
    //いいねした時の処理
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
        
        let likeCountRef = Firestore.firestore().collection("users").document(myUid).collection("rooms").document(roomID).collection("profileLikeCount").document("count")
        batch.setData(["likeCount": FieldValue.increment(1.0)], forDocument: likeCountRef, merge: true)
        
        if contentsArray[row].mediaArray[0] != "" {
            let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
            batch.updateData(["likeCount": FieldValue.increment(1.0)], forDocument: mediaPostRef)
        }
    }
    
    
    
    private func giveNotification(row:Int,batch:WriteBatch){
        let uid = contentsArray[row].uid
        let myUid = Auth.auth().currentUser!.uid
        let postID = contentsArray[row].documentID
        let documentID = "\(myUid)-\(postID)"
        let docData = ["userName":profileInfo!.userName,"userImage":profileInfo!.userImage,"uid":myUid,"roomName":self.roomInfo!.roomName,"createdAt":Timestamp(),"postID":postID,"roomID":contentsArray[row].roomID,"documentID":documentID,"type":"like"] as [String:Any]
        let ref = Firestore.firestore().collection("users").document(uid).collection("notifications").document(documentID)
        
        if uid == myUid {
            return
        }else{
            batch.setData(docData, forDocument: ref, merge: true)
        }
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
    
    
    
    
    
    
    //いいねをやめたときの処理
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
        
        let likeCountRef = Firestore.firestore().collection("users").document(myUid).collection("rooms").document(roomID).collection("profileLikeCount").document("count")
        batch.setData(["likeCount": FieldValue.increment(-1.0)], forDocument: likeCountRef, merge: true)
        
        if contentsArray[row].mediaArray[0] != "" {
            let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
            batch.updateData(["likeCount": FieldValue.increment(-1.0)], forDocument: mediaPostRef)
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
