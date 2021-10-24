//
//  enteredRoomContentViewController.swift
//  postLike
//
//  Created by taichi on 2020/12/23.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import Firebase

class EnteredRoomContentViewController: UIViewController{
    
    
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var memberCountLabel: UILabel!
    @IBOutlet weak var roomTitle: UILabel!
    @IBOutlet weak var contentsTableView: UITableView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var bluredView: UIView!
    @IBOutlet weak var backView2: UIView!
    @IBOutlet weak var cancelView: UIView!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var collectionButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    
    
    
    
    
    private var contentsArray = [Contents]()
    private var profileArray = [Room]()
    private var likeContentsArray = [Contents]()
    private var reportedContentsArray = [Contents]()
    private var reportedUsersArray = [Contents]()
    var passedTitle = String()
    var passedDocumentID = String()
    var passedProfileImage = String()
    var passedUserName = String()
    var passedModerator = String()
    private var roomInfo:Room?
    private var profileInfo:Contents?
    private var scrollBeginingPoint:CGPoint?
    private var currentScrollPoint:CGPoint?
    private var lastDocument:QueryDocumentSnapshot?
    private var lastLikeDocument:QueryDocumentSnapshot?
    private var label = UILabel()
    private var reportdocumentID = String()
    private var reportroomID = String()
    private var reportUid = String()
    private var memberCount:Room?
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentsTableView.delegate = self
        contentsTableView.dataSource = self
        
        
        let tapGesure:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapMyprofile(_:)))
        self.profileImage.addGestureRecognizer(tapGesure)
        tapGesure.delegate = self
        profileImage.layer.cornerRadius = 15
        
        
        self.contentsTableView.tableHeaderView =  self.backView2
        contentsTableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: "postTable")
        
        
        
        let refleshControl = CustomRefreshControl()
        self.contentsTableView.refreshControl = refleshControl
        self.contentsTableView.refreshControl?.addTarget(self, action: #selector(updateContents), for: .valueChanged)
        
        
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
        contentsTableView.addGestureRecognizer(swipeGesture)
        
        
        cancelView.layer.cornerRadius = 10
        stackView.layer.cornerRadius = 10
        
        startIndicator()
        
        self.fetchContents {
            self.dismissIndicator()
            self.contentsTableView.reloadData()
        }
        
        
        
        
        
    }
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        fetchProfileInfo()
        roomExistCheck()
        
        
    }
    
    
    
    
    
    @objc func swiped(_ sender:UISwipeGestureRecognizer){
        navigationController?.popViewController(animated: true)
    }
    
    
    
    @objc func updateContents(){
        
        roomExistCheck()
        fetchProfileInfo()
        self.likeContentsArray.removeAll()
        fetchContents {
            self.contentsTableView.refreshControl?.endRefreshing()
            self.contentsTableView.reloadData()
        }
    }
    
    
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        
    }
    
    
    
    @IBAction func toImageCollection(_ sender: Any) {
        let imageVC = storyboard?.instantiateViewController(withIdentifier: "images") as! RoomImageContentsViewController
        imageVC.passedRoomID = passedDocumentID
        imageVC.passedRoomName = passedTitle
        navigationController?.pushViewController(imageVC, animated: true)
    }
    
    
    
    @IBAction func postButton(_ sender: Any) {
        let postVC = storyboard?.instantiateViewController(withIdentifier: "postVC") as! PostContentViewController
        postVC.roomTitle = roomTitle.text!
        postVC.passedDocumentID = self.roomInfo!.documentID
        postVC.passedDocumentID = self.roomInfo!.documentID
        postVC.passedUserImageUrl = self.profileInfo!.userImage
        postVC.passedUserName = self.profileInfo!.userName
        postVC.passedHostUid = self.profileInfo!.moderator
        present(postVC, animated: true, completion: nil)
    }
    
    
    
    @objc func tapMyprofile(_ sender: UITapGestureRecognizer){
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        let myproVC = storyboard.instantiateViewController(withIdentifier: "myproVC") as! ProfileViewController
        myproVC.passedDocumentID = passedDocumentID
        myproVC.passedModerator = passedModerator
        navigationController?.pushViewController(myproVC, animated: true)
    }
    
    
    
    @IBAction func repotContent(_ sender: Any) {
        let reportVC = storyboard?.instantiateViewController(withIdentifier: "report") as! ReportViewController
        stackView.isHidden = true
        bluredView.isHidden = true
        cancelView.isHidden = true
        tabBarController?.tabBar.isHidden = false
        reportVC.passedDocumentID = self.reportdocumentID
        reportVC.passedRoomID = self.reportroomID
        reportVC.passedUid = self.reportUid
        reportVC.reportCategory = "post"
        reportVC.titleTableViewDelegate = self
        present(reportVC, animated: true, completion: nil)
    }
    
    
    
    @IBAction func reportAndBlockUser(_ sender: Any) {
        let reportVC = storyboard?.instantiateViewController(withIdentifier: "report") as! ReportViewController
        stackView.isHidden = true
        bluredView.isHidden = true
        cancelView.isHidden = true
        tabBarController?.tabBar.isHidden = false
        reportVC.passedDocumentID = self.reportdocumentID
        reportVC.passedRoomID = self.reportroomID
        reportVC.passedUid = self.reportUid
        reportVC.reportCategory = "user"
        reportVC.titleTableViewDelegate = self
        present(reportVC, animated: true, completion: nil)
    }
    
    
    
    
    
    
    @IBAction func cancelButton(_ sender: Any) {
        stackView.isHidden = true
        bluredView.isHidden = true
        cancelView.isHidden = true
        tabBarController?.tabBar.isHidden = false
    }
    
    
    
    

    
    
    func fetchProfileInfo(){
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
                self.createButton.isEnabled = false
                self.createButton.tintColor = .lightGray
                self.profileImage.isUserInteractionEnabled = false
                self.memberCountLabel.text = "このルームから退出しました"
            }else{
                if self.profileInfo?.userImage == "" {
                    self.profileImage.image = UIImage(systemName: "person.fill")
                }else{
                    self.profileImage.sd_setImage(with: URL(string: self.profileInfo!.userImage), completed: nil)
                }
            }
        }
    }
    
    
    
    
    
    func roomExistCheck(){
        Firestore.firestore().collection("rooms").document(passedDocumentID).getDocument { (snapShot, err) in
            if let err = err {
                print("false\(err)")
                return
            }
            if snapShot?.exists == nil {
                self.createButton.isEnabled = false
                self.createButton.tintColor = .lightGray
                self.profileImage.isUserInteractionEnabled = false
                self.memberCountLabel.text = "このルームは削除されました"
            }else{
                guard let snapShot = snapShot,let dic = snapShot.data() else {return}
                let roomInfo = Room.init(dic: dic)
                self.roomInfo = roomInfo
                self.roomTitle.text = self.roomInfo!.roomName
                self.roomTitle.adjustsFontSizeToFitWidth = true
                self.roomTitle.minimumScaleFactor = 0.8
                self.fetchMemberCount()
            }
        }
    }
    
    
    
    
    
    
    
    
    func fetchMemberCount(){
        Firestore.firestore().collection("rooms").document(passedDocumentID).collection("memberCount").document("count").getDocument { snapShot, err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                guard let snap = snapShot,let dic = snap.data() else {return}
                let memberCount = Room.init(dic: dic)
                self.memberCount = memberCount
                self.memberCountLabel.text = "メンバー \(String(describing: self.memberCount!.numberOfMember))人"
            }
        }
    }
    
    
    
    func fetchReportedContents(documentIDs:[String],_ completed: @escaping() -> Void){
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
                    $0.category == "post"
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
    
    
    
    
    
    func fetchReportedUsers(uids:[String],_ completed: @escaping() -> Void){
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
                    $0.category == "user"
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
    
    
    
    
    
    
    
    
    
    
    func fetchLikeContents(documentIDs:[String],_ completed: @escaping() -> Void){
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
    
    
    

    
    
    
    
    func fetchContents(_ completed: @escaping() -> Void){
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
    
    
    
    
    
    
    
    
    
    
    
    
    func fetchMoreContetns(){
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





extension EnteredRoomContentViewController: UITableViewDelegate,UITableViewDataSource,TimeLineTableViewControllerDelegate{
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if contentsArray.count == 0 {
            return 0
        }else{
            return contentsArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = contentsTableView.dequeueReusableCell(withIdentifier: "postTable")  as! PostTableViewCell
        
        let userName = cell.postProfileName!
        let profileImage = cell.postProfileImage!
        profileImage.layer.cornerRadius = profileImage.frame.height/2
        
        userName.text = contentsArray[indexPath.row].userName
        
        if contentsArray[indexPath.row].userImage != "" {
            profileImage.sd_setImage(with: URL(string: contentsArray[indexPath.row].userImage), completed: nil)
            cell.personImage.image = UIImage()
        }else{
            profileImage.image = UIImage()
            cell.personImage.image = UIImage(systemName: "person.fill")
        }
        
        let comment = cell.postCommentLabel!
        let postText = contentsArray[indexPath.row].text
        comment.text = postText
        if postText == "" {
            cell.postCommentHeight.constant = 0
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
        
        cell.selectionStyle = .none
        contentsTableView.separatorInset = .zero
        
        
        cell.likeButton.addTarget(self, action: #selector(pushedLikeButton(_:)), for: .touchUpInside)
        cell.likeButton.tag = indexPath.row
        cell.likeCountLabel.tag = indexPath.row+1000000000
        cell.commentButton.addTarget(self, action: #selector(pushedCommentButton(_:)), for: .touchUpInside)
        cell.commentButton.tag = -indexPath.row
        cell.reportButton.addTarget(self, action: #selector(pushedReportButton), for: .touchUpInside)
        cell.reportButton.tag = indexPath.row+10000000000000
        
        let postImage = cell.MyPostImage!
        let postImage2 = cell.myPostImage2!
        let underView = cell.underView!
        let singleView = cell.singlePostImage!
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedPhoto(_:)))
        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(tappedPhoto(_:)))
        
        if self.contentsArray[indexPath.row].mediaArray[0] == "" {
            
            singleView.isHidden = true
            postImage.isHidden = true
            postImage2.isHidden = true
            underView.isHidden = false
            cell.underHeight.constant = 0
            
        }else {
            cell.underHeight.constant = 210 * underView.frame.width / 339
        }
        
        
        if self.contentsArray[indexPath.row].mediaArray.count == 1 {
            
            singleView.isHidden = false
            postImage.isHidden = true
            postImage2.isHidden = true
            singleView.sd_setImage(with: URL(string: contentsArray[indexPath.row].mediaArray[0] ), completed: nil)
            cell.underView.addSubview(singleView)
            singleView.layer.cornerRadius = 8
            singleView.layer.borderWidth = 1
            singleView.layer.borderColor = UIColor.systemGray6.cgColor
            singleView.addGestureRecognizer(tapGesture)
            singleView.isUserInteractionEnabled = true
            
            
            
        }else if self.contentsArray[indexPath.row].mediaArray.count == 2 {
            singleView.isHidden = true
            postImage.isHidden = false
            postImage2.isHidden = false
            
            
            postImage.sd_setImage(with: URL(string: contentsArray[indexPath.row].mediaArray[0] ), completed: nil)
            cell.underView.addSubview(postImage)
            postImage.layer.cornerRadius = 8
            postImage.layer.borderWidth = 1
            postImage.layer.borderColor = UIColor.systemGray6.cgColor
            postImage.addGestureRecognizer(tapGesture)
            postImage.isUserInteractionEnabled = true
            
            
            postImage2.sd_setImage(with: URL(string: contentsArray[indexPath.row].mediaArray[1] ), completed: nil)
            cell.underView.addSubview(postImage2)
            postImage2.layer.cornerRadius = 8
            postImage2.layer.borderWidth = 1
            postImage2.layer.borderColor = UIColor.systemGray6.cgColor
            postImage2.addGestureRecognizer(tapGesture2)
            postImage2.isUserInteractionEnabled = true
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
        
        return cell
    }
    
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if ((indexPath.row + 1) == (self.contentsArray.count - 8)) && self.contentsArray.count == 10 {
            fetchMoreContetns()
        }
        
        
    }
    
    
    
    @objc func pushedReportButton(_ sender:UIButton){
        bluredView.isHidden = false
        stackView.isHidden = false
        cancelView.isHidden = false
        tabBarController?.tabBar.isHidden = true
        self.reportdocumentID = contentsArray[sender.tag - 10000000000000].documentID
        self.reportroomID = contentsArray[sender.tag - 10000000000000].roomID
        self.reportUid = contentsArray[sender.tag - 10000000000000].uid
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedbluredView(_:)))
        bluredView.addGestureRecognizer(tapGesture)
    }
    
    
    
    
    @objc func tappedbluredView(_ sender: UITapGestureRecognizer){
        stackView.isHidden = true
        bluredView.isHidden = true
        cancelView.isHidden = true
        tabBarController?.tabBar.isHidden = false
    }
    
    
    
    @objc func tappedPhoto(_ sender: UITapGestureRecognizer){
        let tappedLocation = sender.location(in: contentsTableView)
        let tappedIndexPath = contentsTableView.indexPathForRow(at: tappedLocation)
        let tappedRow = tappedIndexPath?.row
        let showImageVC = storyboard?.instantiateViewController(identifier: "showImage") as! ShowImageViewController
        showImageVC.passedMedia = contentsArray[tappedRow!].mediaArray
        showImageVC.passedUid = contentsArray[tappedRow!].uid
        showImageVC.passedText = contentsArray[tappedRow!].text
        showImageVC.passedRoomID = contentsArray[tappedRow!].roomID
        showImageVC.passedDocumentID = contentsArray[tappedRow!].documentID
        showImageVC.passedUserName = contentsArray[tappedRow!].userName
        showImageVC.passedUserImage = contentsArray[tappedRow!].userImage
        showImageVC.hidesBottomBarWhenPushed = true
        present(showImageVC, animated: true, completion: nil)
    }
    
    
    
    func createLikeContents(sender:UIButton,batch:WriteBatch){
        let myuid = Auth.auth().currentUser!.uid
        let uid = contentsArray[sender.tag].uid
        let timestamp = Timestamp()
        let documentID = contentsArray[sender.tag].documentID
        let postedAt = contentsArray[sender.tag].createdAt
        let docData = ["media": contentsArray[sender.tag].mediaArray,"text":contentsArray[sender.tag].text,"userImage":contentsArray[sender.tag].userImage,"userName":contentsArray[sender.tag].userName,"documentID":documentID,"roomID":passedDocumentID,"createdAt":timestamp,"uid":uid,"postedAt":postedAt,"myUid":myuid] as [String:Any]
        
        let ref = Firestore.firestore().collection("users").document(myuid).collection("likes").document(documentID)
        batch.setData(docData, forDocument: ref, merge: true)
        
    }
    
    
    
    func updateLikeCount(sender:UIButton,batch:WriteBatch){
        let documentID = contentsArray[sender.tag].documentID
        let roomID = contentsArray[sender.tag].roomID
        let uid = contentsArray[sender.tag].uid
        let myUid = Auth.auth().currentUser!.uid
        
        let profileRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("posts").document(documentID)
        batch.setData(["likeCount": FieldValue.increment(1.0)], forDocument: profileRef, merge: true)
        
        let likeCountRef = Firestore.firestore().collection("users").document(myUid).collection("rooms").document(roomID).collection("profileLikeCount").document("count")
        batch.setData(["likeCount": FieldValue.increment(1.0)], forDocument: likeCountRef, merge: true)
        
        if contentsArray[sender.tag].mediaArray[0] != "" {
            let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
            batch.updateData(["likeCount": FieldValue.increment(1.0)], forDocument: mediaPostRef)
        }
        
    }
    
    
    
    func giveNotification(sender:UIButton,batch:WriteBatch){
        let uid = contentsArray[sender.tag].uid
        let myUid = Auth.auth().currentUser!.uid
        let postID = contentsArray[sender.tag].documentID
        let documentID = "\(myUid)-\(postID)"
        let docData = ["userName":profileInfo!.userName,"userImage":profileInfo!.userImage,"uid":myUid,"roomName":self.roomInfo!.roomName,"createdAt":Timestamp(),"postID":postID,"roomID":contentsArray[sender.tag].roomID,"documentID":documentID,"category":"like"] as [String:Any]
        let ref = Firestore.firestore().collection("users").document(uid).collection("notifications").document(documentID)
        
        if uid == myUid {
            return
        }else{
            batch.setData(docData, forDocument: ref, merge: true)
        }
    }
    
    
    
    
    
    
    
    
    func likeBatch(sender:UIButton){
        let batch = Firestore.firestore().batch()
        createLikeContents(sender: sender, batch: batch)
        updateLikeCount(sender: sender, batch: batch)
        giveNotification(sender: sender, batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                print("scucces")
                let likedContent = self.contentsArray[sender.tag]
                self.likeContentsArray.append(likedContent)
            }
        }
    }
    
    
    
    
    
    func deleteLikeContents(sender:UIButton,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let documentID = contentsArray[sender.tag].documentID
        let ref = Firestore.firestore().collection("users").document(uid).collection("likes").document(documentID)
        batch.deleteDocument(ref)
    }
    
    
    
    func deleteLikeCount(sender: UIButton,batch:WriteBatch){
        let documentID = contentsArray[sender.tag].documentID
        let roomID = contentsArray[sender.tag].roomID
        let uid = contentsArray[sender.tag].uid
        let myUid = Auth.auth().currentUser!.uid
        
        let profileRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("posts").document(documentID)
        batch.setData(["likeCount": FieldValue.increment(-1.0)], forDocument: profileRef, merge: true)
        
        let likeCountRef = Firestore.firestore().collection("users").document(myUid).collection("rooms").document(roomID).collection("profileLikeCount").document("count")
        batch.setData(["likeCount": FieldValue.increment(-1.0)], forDocument: likeCountRef, merge: true)
        
        if contentsArray[sender.tag].mediaArray[0] != "" {
            let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
            batch.updateData(["likeCount": FieldValue.increment(-1.0)], forDocument: mediaPostRef)
        }
    }
    
    
    
    
    
    func deleteNotification(sender:UIButton,batch:WriteBatch){
        let uid = contentsArray[sender.tag].uid
        let myuid = Auth.auth().currentUser!.uid
        let postID = contentsArray[sender.tag].documentID
        let documentID = "\(myuid)-\(postID)"
        let ref = Firestore.firestore().collection("users").document(uid).collection("notifications").document(documentID)
        if uid == myuid {
            return
        }else{
            batch.deleteDocument(ref)
        }
    }
    
    

    
    
    
    
    
    func deleteLikeBatch(sender:UIButton){
        let batch = Firestore.firestore().batch()
        let documentID = contentsArray[sender.tag].documentID
        deleteLikeContents(sender: sender, batch: batch)
        deleteLikeCount(sender: sender, batch: batch)
        deleteNotification(sender: sender, batch: batch)
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
    
    
    
    
    
    
    
    
    @objc func pushedLikeButton(_ sender: UIButton){
        if sender.tintColor == UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1) && profileInfo?.isJoined == true {
            sender.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            sender.tintColor = .red
            likeBatch(sender: sender)
            if let countLabel = sender.superview?.viewWithTag(sender.tag+1000000000) as? UILabel {
                var count = Int(contentsArray[sender.tag].likeCount)
                count += 1
                countLabel.text = count.description
                contentsArray[sender.tag].likeCount = count
            }
        }else if sender.tintColor == .red && profileInfo?.isJoined == true{
            
            sender.setImage(UIImage(systemName: "heart"), for: .normal)
            sender.tintColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
            deleteLikeBatch(sender: sender)
            if let countLabel = sender.superview?.viewWithTag(sender.tag+1000000000) as? UILabel {
                var count = Int(countLabel.text!)!
                count -= 1
                countLabel.text = count.description
                contentsArray[sender.tag].likeCount = count
            }
        }
    }
    
    
    
    
    
    
    @objc func pushedCommentButton(_ sender: UIButton) {
        
        let cLVC = storyboard?.instantiateViewController(withIdentifier: "commentList") as! CommentListViewController
        cLVC.passedUserImage = contentsArray[-sender.tag].userImage
        cLVC.passedUserName = contentsArray[-sender.tag].userName
        cLVC.passedComment = contentsArray[-sender.tag].text
        cLVC.passedDate = contentsArray[-sender.tag].createdAt
        cLVC.passedMediaArray = contentsArray[-sender.tag].mediaArray
        cLVC.passedMyImage = profileImage.image!
        cLVC.passedRoomName = roomTitle.text!
        cLVC.passedDocumentID = contentsArray[-sender.tag].documentID
        cLVC.passedRoomID = contentsArray[-sender.tag].roomID
        cLVC.passedUid = contentsArray[-sender.tag].uid
        cLVC.hidesBottomBarWhenPushed = true
        present(cLVC, animated: true, completion: nil)
    }
    

    
    

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

extension EnteredRoomContentViewController:UIScrollViewDelegate,UIGestureRecognizerDelegate{
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        currentScrollPoint = self.contentsTableView.contentOffset
        if currentScrollPoint?.y ?? 0 > scrollBeginingPoint?.y ?? 0 {
            topView.frame.origin.y = self.view.safeAreaInsets.top - self.contentsTableView.contentOffset.y
        }else{
            UIView.animate(withDuration: 0.4) {
                self.topView.frame.origin.y = self.view.safeAreaInsets.top
            }
        }
    }
    
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollBeginingPoint = self.contentsTableView.contentOffset
        
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
    
    
    
    
    
}
