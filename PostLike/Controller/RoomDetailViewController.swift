//
//  roomDetailViewController.swift
//  postLike
//
//  Created by taichi on 2020/11/25.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import DKImagePickerController

protocol CreateProfileDelegate {
    func joinRoomBatch(_ completed: @escaping() -> Void,userName:String)
    func createStrageWithBatch(_ completed: @escaping() -> Void,userName:String,profileImageView:UIImageView)
}

class RoomDetailViewController: UIViewController {
    
    
    
    @IBOutlet weak var roomName: UILabel!
    @IBOutlet weak var bluredView: UIView!
    @IBOutlet weak var contentsTableView: UITableView!
    @IBOutlet weak var backView2: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var cancelView: UIView!
    
    
    
    
    
    var passedRoomName = String()
    var passedRoomImage = String()
    var passedDocumentID = String()
    var passedNumberOfMember = Int()
    var passedRoomIntro = String()
    var reportDocumentID = String()
    var reportRoomID = String()
    var reportUid = String()
    var label = UILabel()
    var contentsArray = [Contents]()
    var reportedUsersArray = [Contents]()
    var reportedContentsArray = [Contents]()
    var joinedRoom:Contents?
    var roomInfo:Room?
    var likeContentsArray = [Contents]()
    var memberCount:Room?
    let headerView:SearchResultHeaderView = SearchResultHeaderView()
    var lastDocument:QueryDocumentSnapshot?
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.contentsTableView.delegate = self
        self.contentsTableView.dataSource = self
        self.contentsTableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: "postTable")
        
       
        
        cancelView.layer.cornerRadius = 10
        backView2.layer.cornerRadius = 10
        stackView.layer.cornerRadius = 10
        
        
        
        headerView.roomImage.layer.cornerRadius = 40
        headerView.roomImage.layer.borderColor = UIColor.systemGray6.cgColor
        headerView.roomImage.layer.borderWidth = 1
        
        
        headerView.joinButton.clipsToBounds = true
        headerView.joinButton.layer.cornerRadius = 20
        headerView.joinButton.layer.borderWidth = 1
        headerView.joinButton.layer.borderColor = UIColor.systemGray5.cgColor
        headerView.joinButton.addTarget(self, action: #selector(pushedJoinButton(_:)), for: .touchUpInside)
        
        
        
        fetchRoomDetail()
    }
    
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchFollowedRoom()
        fetchMemberCount()
    }
    
    
    
    
    
    func sizefit(){
        self.contentsTableView.tableHeaderView = headerView
        if let tableHeaderView = self.contentsTableView.tableHeaderView {
            tableHeaderView.setNeedsLayout()
            tableHeaderView.layoutIfNeeded()
            let size = tableHeaderView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            tableHeaderView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            self.contentsTableView.tableHeaderView = tableHeaderView
        }
    }
    
    
    
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    @IBAction func reportButton(_ sender: Any) {
        bluredView.isHidden = false
        backView2.isHidden = false
        cancelView.isHidden = false
        tabBarController?.tabBar.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedBluredView(_:)))
        bluredView.addGestureRecognizer(tapGesture)
    }
    
    
    
    @IBAction func reportPost(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let reportVC = storyboard.instantiateViewController(withIdentifier: "report") as! ReportViewController
        stackView.isHidden = true
        bluredView.isHidden = true
        cancelView.isHidden = true
        tabBarController?.tabBar.isHidden = false
        reportVC.passedDocumentID = self.reportDocumentID
        reportVC.passedRoomID = self.reportRoomID
        reportVC.passedUid = self.reportUid
        reportVC.reportCategory = "post"
        reportVC.titleTableViewDelegate = self
        present(reportVC, animated: true, completion: nil)
    }
    
    
    
    @IBAction func reportUser(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let reportVC = storyboard.instantiateViewController(withIdentifier: "report") as! ReportViewController
        stackView.isHidden = true
        bluredView.isHidden = true
        cancelView.isHidden = true
        tabBarController?.tabBar.isHidden = false
        reportVC.passedDocumentID = self.reportDocumentID
        reportVC.passedRoomID = self.reportRoomID
        reportVC.passedUid = self.reportUid
        reportVC.reportCategory = "user"
        reportVC.titleTableViewDelegate = self
        present(reportVC, animated: true, completion: nil)
    }
    
    
    
    
    
    
    
    @objc func tappedBluredView(_ sender:UITapGestureRecognizer){
        bluredView.isHidden = true
        backView2.isHidden = true
        cancelView.isHidden = true
        stackView.isHidden = true
        tabBarController?.tabBar.isHidden = false
    }
    
    
    
    
    @IBAction func reportRoom(_ sender: Any) {
        bluredView.isHidden = true
        backView2.isHidden = true
        cancelView.isHidden = true
        tabBarController?.tabBar.isHidden = false
        let reportRoomVC = storyboard?.instantiateViewController(identifier: "reportRoom") as! ReportRoomViewController
        reportRoomVC.passedRoomID = passedDocumentID
        present(reportRoomVC, animated: true, completion: nil)
    }
    
    
    
    
    @IBAction func cancelButton(_ sender: Any) {
        bluredView.isHidden = true
        backView2.isHidden = true
        cancelView.isHidden = true
        stackView.isHidden = true
        tabBarController?.tabBar.isHidden = false
    }
    
    
    
    
    @objc func pushedJoinButton(_ sender: UIButton) {
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
            enteredVC.passedTitle = roomInfo!.roomName
            enteredVC.passedProfileImage = self.joinedRoom!.userImage
            navigationController?.pushViewController(enteredVC,animated: false)
        }
    }
    
    
    
    
    @objc func tappedbluredView(_ sender: UITapGestureRecognizer){
        bluredView.isHidden = true
        tabBarController?.tabBar.isHidden = false
    }
    
    


    
    
    
    
    func fetchRoomDetail(){
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
                self.sizefit()
                self.contentsTableView.reloadData()
            }else {
                
                let dic = snapShot!.data()
                let roomInfo = Room.init(dic: dic!)
                self.roomInfo = roomInfo
                if self.roomInfo?.roomImage != "" {
                    self.headerView.roomImage.sd_setImage(with: URL(string: self.roomInfo?.roomImage ?? ""), completed: nil)
                    self.headerView.personsImage.image = UIImage()
                }
                self.roomName.text = self.roomInfo?.roomName
                self.roomName.adjustsFontSizeToFitWidth = true
                self.roomName.minimumScaleFactor = 0.9
                self.headerView.roomName.text = self.roomInfo?.roomName
                self.headerView.roomIntro.text = self.roomInfo?.roomIntro
                self.headerView.roomName.adjustsFontSizeToFitWidth = true
                self.headerView.roomName.minimumScaleFactor = 0.8
                self.sizefit()
                self.fetchContents {
                    self.contentsTableView.reloadData()
                }
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
    
    
    
    
    
    
    func fetchFollowedRoom(){
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
    
    
    
    
    
    
    
    
    
    
    
    
    func fetchMemberCount(){
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






extension RoomDetailViewController: UITableViewDelegate,UITableViewDataSource,TimeLineTableViewControllerDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = contentsTableView.dequeueReusableCell(withIdentifier: "postTable", for: indexPath) as! PostTableViewCell
        
        let userName = cell.postProfileName!
        userName.text = contentsArray[indexPath.row].userName
        
        
        let userImage = cell.postProfileImage!
        userImage.layer.cornerRadius = userImage.frame.height/2
        if contentsArray[indexPath.row].userImage != "" {
            userImage.sd_setImage(with: URL(string: contentsArray[indexPath.row].userImage), completed: nil)
            cell.personImage.image = UIImage()
        }else{
            userImage.image = UIImage()
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
        
        let postImage = cell.MyPostImage!
        let postImage2 = cell.myPostImage2!
        let underView = cell.underView!
        let singleView = cell.singlePostImage!
        
        if self.contentsArray[indexPath.row].mediaArray[0] == "" {
            singleView.isHidden = true
            postImage.isHidden = true
            postImage2.isHidden = true
            underView.isHidden = false
            cell.underHeight.constant = 0
        }else {
            cell.underHeight.constant = 210 * underView.frame.width / 340
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
            
            
        }else if self.contentsArray[indexPath.row].mediaArray.count == 2 {
            
            singleView.isHidden = true
            postImage.isHidden = false
            postImage2.isHidden = false
            postImage.sd_setImage(with: URL(string: contentsArray[indexPath.row].mediaArray[0] ), completed: nil)
            cell.underView.addSubview(postImage)
            postImage.layer.cornerRadius = 8
            postImage.layer.borderWidth = 1
            postImage.layer.borderColor = UIColor.systemGray6.cgColor
            
            
            postImage2.sd_setImage(with: URL(string: contentsArray[indexPath.row].mediaArray[1] ), completed: nil)
            postImage2.layer.cornerRadius = 8
            postImage2.layer.borderWidth = 1
            postImage2.layer.borderColor = UIColor.systemGray6.cgColor
            cell.underView.addSubview(postImage2)
        }
        
        
        
        cell.likeButton.addTarget(self, action: #selector(pushedLikeButton(_:)), for: .touchUpInside)
        cell.likeButton.tag = indexPath.row
        cell.likeCountLabel.tag = indexPath.row+1000000000
        
        
        
        cell.commentButton.addTarget(self, action: #selector(pushedCommentButton(_:)), for: .touchUpInside)
        cell.commentButton.tag = -indexPath.row
        
    
        
        cell.reportButton.addTarget(self, action: #selector(pushedReportButton(_:)), for: .touchUpInside)
        cell.reportButton.tag = indexPath.row+10000000000000
        
        
        
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
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == self.contentsArray.count  {
            fetchMoreContetns()
        }
    }
    
    
    
    
    
    @objc func pushedLikeButton(_ sender: UIButton){
        
        if sender.tintColor == UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1) && self.joinedRoom?.documentID != "" && self.joinedRoom?.isJoined == true {

            sender.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            sender.tintColor = .red
    
            likeBatch(sender: sender)
            
            if let countLabel = sender.superview?.viewWithTag(sender.tag+1000000000) as? UILabel {
                
                var count = Int(contentsArray[sender.tag].likeCount)
                count += 1
                countLabel.text = count.description
//                roomPostsArray[sender.tag].likeCount = count
            }
        }else if sender.tintColor == .red && self.joinedRoom?.documentID != "" && self.joinedRoom?.isJoined == true{

            
            sender.setImage(UIImage(systemName: "heart"), for: .normal)
            sender.tintColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
            deleteLikeBatch(sender: sender)
            if let countLabel = sender.superview?.viewWithTag(sender.tag+1000000000) as? UILabel {
                var count = Int(countLabel.text!)!
                count -= 1
                countLabel.text = count.description
//                roomPostsArray[sender.tag].likeCount = count
            }
        }else {
            print("can't push!!!!!")
        }
    }
    
    
    
    @objc func pushedCommentButton(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let cLVC = storyboard.instantiateViewController(withIdentifier: "commentList") as! CommentListViewController
        cLVC.passedUserImage = contentsArray[-sender.tag].userImage
        cLVC.passedUserName = contentsArray[-sender.tag].userName
        cLVC.passedComment = contentsArray[-sender.tag].text
        cLVC.passedDate = contentsArray[-sender.tag].createdAt
        cLVC.passedRoomName = contentsArray[-sender.tag].roomName
        cLVC.passedDocumentID = contentsArray[-sender.tag].documentID
        cLVC.passedRoomID = contentsArray[-sender.tag].roomID
        cLVC.passedUid = contentsArray[-sender.tag].uid
        cLVC.passedMediaArray = contentsArray[-sender.tag].mediaArray
        present(cLVC, animated: true, completion: nil)
    }
    
    
    
    
    
    
    @objc func pushedReportButton(_ sender: UIButton){
        stackView.isHidden = false
        bluredView.isHidden = false
        cancelView.isHidden = false
        tabBarController?.tabBar.isHidden = false
        bluredView.isHidden = false
        stackView.isHidden = false
        cancelView.isHidden = false
        tabBarController?.tabBar.isHidden = true
        self.reportDocumentID = contentsArray[sender.tag - 10000000000000].documentID
        self.reportRoomID = contentsArray[sender.tag - 10000000000000].roomID
        self.reportUid = contentsArray[sender.tag - 10000000000000].uid
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedBluredView(_:)))
        bluredView.addGestureRecognizer(tapGesture)
        
    }
    
    
    
    
    
    
    
    
    
     
    func fetchLatestLikeContent(){
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
    
    
    
    
    
    
    //likeBatch
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
        
        let likedCountRef = Firestore.firestore().collection("users").document(myUid).collection("rooms").document(roomID).collection("profileLikeCount").document("count")
        batch.setData(["likeCount": FieldValue.increment(1.0)], forDocument: likedCountRef, merge: true)
        
        if contentsArray[sender.tag].mediaArray[0] != "" {
            let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
            batch.updateData(["likeCount":FieldValue.increment(1.0)], forDocument: mediaPostRef)
        }
    }
    
    
    
    func giveNotification(sender:UIButton,batch:WriteBatch){
        let uid = contentsArray[sender.tag].uid
        let myuid = Auth.auth().currentUser!.uid
        let postID = contentsArray[sender.tag].documentID
        let documentID = "\(myuid)-\(postID)"
        let docData = ["userName":joinedRoom!.userName,"userImage":joinedRoom!.userImage,"uid":myuid,"roomName":self.roomInfo!.roomName,"createdAt":Timestamp(),"postID":postID,"roomID":contentsArray[sender.tag].roomID,"documentID":documentID,"category":"like"] as [String:Any]
        let ref = Firestore.firestore().collection("users").document(uid).collection("notifications").document(documentID)
        
        if uid == myuid {
            return
        }else{
            batch.setData(docData, forDocument: ref, merge: true)
        }
    }
    
    

    

    
    
    
    func likeBatch(sender:UIButton){
        let batch = Firestore.firestore().batch()
        updateLikeCount(sender: sender, batch: batch)
        createLikeContents(sender: sender, batch: batch)
        giveNotification(sender: sender, batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                self.fetchLatestLikeContent()
            }
        }
    }
    
    
    
    
    
    
    
    //deleteBatch
    
    
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
        
        let likedCountRef = Firestore.firestore().collection("users").document(myUid).collection("rooms").document(roomID).collection("profileLikeCount").document("count")
        batch.setData(["likeCount": FieldValue.increment(-1.0)], forDocument: likedCountRef, merge: true)
        
        if contentsArray[sender.tag].mediaArray[0] != "" {
            let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
            batch.updateData(["likeCount":FieldValue.increment(-1.0)], forDocument: mediaPostRef)
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

        deleteLikeCount(sender: sender, batch: batch)
        deleteLikeContents(sender: sender, batch: batch)
        deleteNotification(sender: sender, batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                return
            }else{

                self.likeContentsArray.removeAll(where: {$0.documentID == documentID})

            }
        }
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


extension RoomDetailViewController:UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
            return PresentationController(presentedViewController: presented, presenting: presenting)
        }
}


extension RoomDetailViewController:CreateProfileDelegate {
    
    func createMemberList(batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let docData = ["uid":uid]
        let ref =  Firestore.firestore().collection("rooms").document(passedDocumentID).collection("members").document(uid)
        batch.setData(docData, forDocument: ref)
    }
    
    
    
    func increaseMemberCount(batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(passedDocumentID).collection("memberCount").document("count")
        batch.setData(["memberCount": FieldValue.increment(1.0)], forDocument: ref, merge: true)
    }
    
    
    
    
    func creatProfileWhenHaveCreated(){
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
    
    
    
    
    
    func createRoomDetail(userName:String,userImageUrl:String,batch:WriteBatch){
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


