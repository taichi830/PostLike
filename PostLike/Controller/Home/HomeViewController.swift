//
//  HomeViewController.swift
//  postLike
//
//  Created by taichi on 2020/11/20.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import GoogleMobileAds


typealias ComplitionClosure = ((_ result:Array<Contents>) -> Void)

protocol RemoveContentsDelegate:AnyObject {
    func removeMutedContent(documentID:String)
    func removeBlockedUserContents(uid:String,roomID:String)
}

protocol TableViewCellDelegate:AnyObject {
    func reportButton(row:Int)
    func tappedPostImageView(row:Int)
    func pushLikeButton(row:Int,sender:UIButton,countLabel:UILabel)
    func pushedCommentButton(row:Int)
}


class HomeViewController: UIViewController{
    
    
    
    @IBOutlet weak var roomCollectionView: UICollectionView!
    @IBOutlet weak var timeLineTableView: UITableView!
    @IBOutlet weak var bluredView: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerSeparaterView: UIView!
    
    
    private var joinedRoomArray = [Contents]()
    private var timeLineContents = [Contents]()
    private var likeContentsArray = [Contents]()
    private var reportedContentsArray = [Contents]()
    private var reportedUsersArray = [Contents]()
    private var nativeAds = [GADUnifiedNativeAd]()
    private var adLoader: GADAdLoader!
    private var tableViewItems = [Any]()
    private var label = UILabel()
    private var timelinePosts = [Contents]()
    private var moreTimelinePosts = [Contents]()
    private var lastDocument:QueryDocumentSnapshot?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupTableView()
        startIndicator()
        fetchModeratorPosts()
        fetchJoinedRoom()
    
    }
    
    
    
    
    
    
    
    
    private func loadAdmob(numberOfAds:Int){
        let multipleAdsOptions = GADMultipleAdsAdLoaderOptions()
        multipleAdsOptions.numberOfAds = numberOfAds
        #if DEBUG
        let adUnitID = "ca-app-pub-3940256099942544/3986624511"
        #else
        let adUnitID = "ca-app-pub-3940256099942544/3986624511"
        #endif
        adLoader = GADAdLoader(adUnitID: adUnitID, rootViewController: self,
                               adTypes: [GADAdLoaderAdType.unifiedNative],
                               options: [multipleAdsOptions])
        adLoader.delegate = self
        adLoader.load(GADRequest())
    }
    
    
    
    
    
    
    
    @objc private func updateContents(){
        self.likeContentsArray.removeAll()
        fetchModeratorPosts()
        fetchJoinedRoom()
    }
    
    
    
    
    
    
    @IBAction func allViewButton(_ sender: Any) {
        let roomList = storyboard?.instantiateViewController(identifier: "roomList") as! RoomListViewController
        roomList.passedFollwedRoomArray = joinedRoomArray
        navigationController?.pushViewController(roomList, animated: true)
    }
    
    
    
    
    private func setupCollectionView(){
        roomCollectionView.delegate = self
        roomCollectionView.dataSource = self
        let nib = UINib(nibName: "RoomCollectionViewCell", bundle: .main)
        roomCollectionView.register(nib, forCellWithReuseIdentifier: "myroomCell")
        roomCollectionView.frame = CGRect(x: 0, y: 5, width: self.view.frame.width, height: 130)
        headerSeparaterView.frame.size.width = self.view.frame.width
        collectionItemSize()
    }
    
    
    private func setupTableView(){
        timeLineTableView.delegate = self
        timeLineTableView.dataSource = self
        timeLineTableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: "postTable")
        timeLineTableView.showsVerticalScrollIndicator = true
        timeLineTableView.register(UINib(nibName: "NativeAdTableViewCell", bundle: nil), forCellReuseIdentifier: "nativeAdCell")
        timeLineTableView.tableHeaderView = headerView
        timeLineTableView.separatorInset = .zero
        
        let refleshControl = UIRefreshControl()
        self.timeLineTableView.refreshControl = refleshControl
        self.timeLineTableView.refreshControl?.addTarget(self, action: #selector(updateContents), for: .valueChanged)
    }
    
    
    
    
    
    
    
   private func fetchJoinedRoom(){
        self.joinedRoomArray.removeAll()
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("rooms").whereField("isJoined", isEqualTo: true).order(by: "createdAt", descending: true).getDocuments { (querySnapshot, err) in
            
            if let err = err {
                print("情報の取得に失敗しました。\(err)")
                return
            }
            for document in querySnapshot!.documents{
                let dic = document.data()
                let followedRoom = Contents.init(dic: dic)
                self.joinedRoomArray.append(followedRoom)
            }
            if self.joinedRoomArray.count == 0 {
                self.timeLineTableView.refreshControl?.endRefreshing()
                self.roomCollectionView.reloadData()
            }else{
                self.roomCollectionView.reloadData()
                self.label.removeFromSuperview()
            }
        }
    }
    
    
    
    
    
    
   private func fetchReportedContents(documentIDs:[String],_ completed: @escaping() -> Void){
        let uid = Auth.auth().currentUser!.uid
        self.reportedContentsArray.removeAll()
        Firestore.firestore().collection("users").document(uid).collection("reports").whereField("documentID", in: documentIDs).limit(to: 10).getDocuments { querySnapshot, err in
            if err != nil {
                return
            }else{
                for document in querySnapshot!.documents{
                    let dic = document.data()
                    let reportedContents = Contents.init(dic: dic)
                    self.reportedContentsArray.append(reportedContents)
                }
                let filteredArray = self.reportedContentsArray.filter {
                    $0.type == "post"
                }
                for content in filteredArray {
                    self.timelinePosts.removeAll(where: {$0.documentID == content.documentID})
                    self.moreTimelinePosts.removeAll(where: {$0.documentID == content.documentID})
                }
                completed()
            }
        }
    }
    
    
    
    
    
   private func fetchReportedUsers(uids:[String],_ completed: @escaping() -> Void){
        let uid = Auth.auth().currentUser!.uid
        self.reportedUsersArray.removeAll()
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
                    self.timelinePosts.removeAll(where: {($0.uid == content.uid)&&($0.roomID == content.roomID)})
                    self.moreTimelinePosts.removeAll(where: {($0.uid == content.uid)&&($0.roomID == content.roomID)})
                }
                completed()
            }
        }
    }
    
    
    
    
    
    
    
    
    
   private func fetchLikeContents(documentIDs:[String]){
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
        }
    }
    
    
    
    
    
    
    
    
   private func fetchTimelinePosts(completionClosure:@escaping ComplitionClosure){
        self.timelinePosts.removeAll()
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("feeds").order(by: "createdAt", descending: true).limit(to: 10).getDocuments { querySnapShot, err in
            if let err = err{
                print(err)
                return
            }
            self.lastDocument = querySnapShot!.documents.last
            for document in querySnapShot!.documents{
                let dic = document.data()
                let followedContent = Contents.init(dic: dic)
                self.timelinePosts.append(followedContent)
            }
            if self.joinedRoomArray.count == 0 {
                self.label.frame = CGRect(x: 0, y: self.view.center.y, width: self.view.frame.width, height: 30)
                self.label.text = "ルームを作成、探して参加しよう！"
                self.label.textAlignment = .center
                self.label.textColor = .lightGray
                self.label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
                self.timeLineTableView.addSubview(self.label)
                completionClosure([])
                
            } else if self.timelinePosts.count == 0 {
                self.label.frame = CGRect(x: 0, y: self.view.center.y, width: self.view.frame.size.width, height: 20)
                self.label.text = "投稿がまだありません"
                self.label.textAlignment = .center
                self.label.textColor = .lightGray
                self.label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
                self.timeLineTableView.addSubview(self.label)
                self.timeLineTableView.reloadData()
                self.timeLineTableView.refreshControl?.endRefreshing()
                completionClosure([])
                
            }else{
                self.label.removeFromSuperview()
                let documentIDs = self.timelinePosts.map { Contents -> String in
                    let documentID = Contents.documentID
                    return documentID
                }
                let uids = self.timelinePosts.map { Contents -> String in
                    let uid = Contents.uid
                    return uid
                }
                self.fetchReportedContents(documentIDs: documentIDs) {
                    self.fetchReportedUsers(uids: uids) {
                        completionClosure(self.timelinePosts)
                    }
                }
                
                
            }
        }
    }
    
    
    
    
    
    private func fetchModeratorPosts(){
        self.timeLineContents.removeAll()
        self.nativeAds.removeAll()
        fetchTimelinePosts(completionClosure: { results in
            if results.isEmpty == true {
                self.tableViewItems.removeAll()
                self.timeLineTableView.reloadData()
                self.timeLineTableView.refreshControl?.endRefreshing()
                self.dismissIndicator()
            }else{
                let documentIDs = results.map { Contents -> String in
                    let documentID = Contents.documentID
                    return documentID
                }
                self.fetchLikeContents(documentIDs: documentIDs)
                Firestore.firestore().collectionGroup("posts").whereField("documentID", in: documentIDs).order(by: "createdAt", descending: true).getDocuments { querySnapshot, err in
                    if let err = err {
                        print("情報の取得に失敗しました。\(err)")
                        return
                    }
                    for document in querySnapshot!.documents {
                        let dic = document.data()
                        let followedContent = Contents.init(dic: dic)
                        self.timeLineContents.append(followedContent)
                    }
                    self.loadAdmob(numberOfAds: self.timelinePosts.count)
                }
            }
        })
    }
    
    
    
    
    
    private func fetchMoreTimelinePosts(completionClosure:@escaping ComplitionClosure){
        self.moreTimelinePosts.removeAll()
        guard let lastDocument = lastDocument else {return}
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("feeds").order(by: "createdAt", descending: true).start(afterDocument: lastDocument).limit(to: 10).getDocuments { (querySnapShot, err) in
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
            for document in querySnapShot!.documents {
                let dic = document.data()
                let followedContent = Contents.init(dic: dic)
                self.moreTimelinePosts.append(followedContent)
            }
            if self.moreTimelinePosts.isEmpty != true {
                let documentIDs = self.moreTimelinePosts.map { Contents -> String in
                    let documentID = Contents.documentID
                    return documentID
                }
                let uids = self.moreTimelinePosts.map { Contents -> String in
                    let uid = Contents.uid
                    return uid
                }
                self.fetchReportedContents(documentIDs: documentIDs) {
                    self.fetchReportedUsers(uids: uids) {
                        completionClosure(self.moreTimelinePosts)
                    }
                }
            }
        }
    }
    
    
    
    
    
    
    private func fetchMoreModeratorPosts(){
        fetchMoreTimelinePosts { (results) in
            let documentIDs = results.map { Contents -> String in
                let documentID = Contents.documentID
                return documentID
            }
            self.fetchLikeContents(documentIDs: documentIDs)
            Firestore.firestore().collectionGroup("posts").whereField("documentID", in: documentIDs).getDocuments { querySnapshot, err in
                if let err = err {
                    print("情報の取得に失敗しました。\(err)")
                    return
                }
                for document in querySnapshot!.documents {
                    let dic = document.data()
                    let followedContent = Contents.init(dic: dic)
                    self.timeLineContents.append(followedContent)
                }
                self.loadAdmob(numberOfAds: self.moreTimelinePosts.count + self.timelinePosts.count)
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
}





extension HomeViewController: UICollectionViewDelegate,UICollectionViewDataSource{
    
    func collectionItemSize(){
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width:130, height: 120)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        roomCollectionView.collectionViewLayout = layout
        layout.scrollDirection = .horizontal
        roomCollectionView.isPagingEnabled = false
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.joinedRoomArray.isEmpty == true {
            return 5
        }else{
            return joinedRoomArray.count
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        let cell = roomCollectionView.dequeueReusableCell(withReuseIdentifier: "myroomCell", for: indexPath) as! RoomCollectionViewCell
        if self.joinedRoomArray.count != 0 {
            cell.roomName.text = joinedRoomArray[indexPath.row].roomName
            if joinedRoomArray[indexPath.row].roomImage != "" {
                cell.roomImage.sd_setImage(with: URL(string: joinedRoomArray[indexPath.row].roomImage), completed: nil)
                cell.personImage.image = UIImage()
            }else{
                cell.roomImage.image = UIImage()
                cell.roomImage.backgroundColor = .systemGray6
                cell.personImage.image = UIImage(systemName: "person.3.fill")
            }
        }else{
            cell.personImage.image = UIImage()
            cell.roomImage.image = UIImage()
            cell.roomName.text = ""
        }
        return cell
    }
    
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.joinedRoomArray.count != 0 {
            let enteredVC = storyboard?.instantiateViewController(withIdentifier: "enteredVC") as! EnteredRoomContentViewController
            enteredVC.passedDocumentID = joinedRoomArray[indexPath.row].documentID
            navigationController?.pushViewController(enteredVC, animated: true)
        }
    }
    
}






extension HomeViewController: UITableViewDelegate,UITableViewDataSource{
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewItems.count
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let timeLineContent = tableViewItems[safe: indexPath.row] as? Contents{
            let cell = timeLineTableView.dequeueReusableCell(withIdentifier: "postTable", for: indexPath) as! PostTableViewCell
            cell.tableViewCellDelegate = self
            cell.setContent(contents: timeLineContent, likeContensArray: likeContentsArray)
            
            let now = Date()
            let createdAt = timeLineContent.createdAt.dateValue()
            let diff = Calendar.current.dateComponents([.day,.hour,.minute,.second], from: createdAt, to: now)
            if diff.day == 0 && diff.hour == 0 && diff.minute == 0 && diff.second != 0 {
                cell.createdAt.text = "moderator・\(diff.second ?? 0)秒前"
            }else if diff.day == 0 && diff.hour == 0 && diff.minute != 0 {
                cell.createdAt.text = "moderator・\(diff.minute ?? 0)分前"
            }else if diff.day == 0 && diff.hour != 0{
                cell.createdAt.text = "moderator・\(diff.hour ?? 0)時間前"
            }else if diff.day != 0 {
                cell.createdAt.text = "moderator・\(diff.day ?? 0)日前"
            }
            
            
            
            let roomNameArray = joinedRoomArray.filter {
                $0.documentID == timeLineContent.roomID
            }
            let roomNameLabel = cell.roomNameLabel
            if roomNameArray.isEmpty != true{
                roomNameLabel?.text = ("\(roomNameArray[0].roomName)")
                roomNameLabel?.adjustsFontSizeToFitWidth = true
                roomNameLabel?.minimumScaleFactor = 0.8
            }
            let tapRoomLabel = UITapGestureRecognizer(target: self, action: #selector(tappedRoomNameLabel(_:)))
            roomNameLabel?.addGestureRecognizer(tapRoomLabel)
            
            
            
            
            return cell
            
        }else{
            
            if let nativeAd = tableViewItems[indexPath.row] as? GADUnifiedNativeAd {
                
                nativeAd.rootViewController = self
                
                let nativeAdCell = tableView.dequeueReusableCell(
                    withIdentifier: "nativeAdCell", for: indexPath) as! NativeAdTableViewCell
                nativeAdCell.setAd(nativeAd: nativeAd)
                
                return nativeAdCell
            }
            
        }
        
        return UITableViewCell()
        
    }
    
    
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath.row + 1 == self.tableViewItems.count)  {
            fetchMoreModeratorPosts()
        }
    }
    
    
    
    @objc private func tappedRoomNameLabel(_ sender:UITapGestureRecognizer){
        let tappedLocation = sender.location(in: timeLineTableView)
        let tappedIndexPath = timeLineTableView.indexPathForRow(at: tappedLocation)
        let tappedRow = tappedIndexPath?.row
        let enteredVC = storyboard?.instantiateViewController(withIdentifier: "enteredVC") as! EnteredRoomContentViewController
        if let followContent = tableViewItems[tappedRow!] as? Contents {
            
            let roomInfo = joinedRoomArray.filter {
                $0.documentID == followContent.roomID
            }
//            enteredVC.passedModerator = roomInfo[0].moderator
            enteredVC.passedDocumentID = roomInfo[0].documentID
//            enteredVC.passedTitle = roomInfo[0].roomName
//            enteredVC.passedProfileImage = roomInfo[0].userImage
//            enteredVC.passedUserName = roomInfo[0].userName
            navigationController?.pushViewController(enteredVC, animated: true)
        }
    }
    

    
    
  
}







extension HomeViewController:RemoveContentsDelegate{
    
    func removeMutedContent(documentID:String) {
        self.tableViewItems.removeAll { Protocol  in
            let room = Protocol as? Contents
            return (room?.documentID  == documentID )
        }
        self.timeLineTableView.reloadData()
    }
    
    func removeBlockedUserContents(uid:String,roomID:String) {
        self.tableViewItems.removeAll { Protocol  in
            let room = Protocol as? Contents
            return ((room?.uid  == uid) && (room?.roomID == roomID))
        }
        self.timeLineTableView.reloadData()
    }
    
}



extension HomeViewController:TableViewCellDelegate {
    
    
    
    func updateLikeCount(row:Int,batch:WriteBatch){
        if let followContent = tableViewItems[row] as? Contents {
            
            let roomID = followContent.roomID
            let documentID = followContent.documentID
            let uid = followContent.uid
            let myUid = Auth.auth().currentUser!.uid
            
            let profileContentRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("posts").document(documentID)
            batch.setData(["likeCount": FieldValue.increment(1.0)], forDocument: profileContentRef, merge: true)
            
            let likeCountRef = Firestore.firestore().collection("users").document(myUid).collection("rooms").document(roomID).collection("profileLikeCount").document("count")
            batch.setData(["likeCount": FieldValue.increment(1.0)], forDocument: likeCountRef, merge: true)
            
            if followContent.mediaArray[0] != "" {
                let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
                batch.setData(["likeCount": FieldValue.increment(1.0)], forDocument: mediaPostRef, merge: true)
            }
        }
    }
    
    
    
    
    func createLikeContents(row:Int,batch:WriteBatch){
        
        if let followContent = tableViewItems[row] as? Contents {
            let myuid = Auth.auth().currentUser!.uid
            let uid = followContent.uid
            let documentID = followContent.documentID
            let roomID = followContent.roomID
            let createdAt = Timestamp()
            let postedAt = followContent.createdAt
            let media = followContent.mediaArray
            let text = followContent.text
            let userName = followContent.userName
            let userImage = followContent.userImage
            let docData = ["media": media,"text":text,"userName":userName,"userImage":userImage,"documentID":documentID,"roomID":roomID,"createdAt":createdAt,"uid":uid,"postedAt":postedAt,"myUid":myuid] as [String:Any]
            let likeRef = Firestore.firestore().collection("users").document(myuid).collection("likes").document(documentID)
            
            batch.setData(docData, forDocument: likeRef)
        }
    }
    
    
    
    
    func giveNotification(row:Int,batch:WriteBatch){
        if let followContent = tableViewItems[row] as? Contents {
            let myUid = Auth.auth().currentUser!.uid
            let uid = followContent.uid
            let postID = followContent.documentID
            let roomID = followContent.roomID
            let roomInfo = joinedRoomArray.filter{ $0.documentID == followContent.roomID }
            let documentID = "\(myUid)-\(postID)"
            let docData = ["userName":roomInfo[0].userName,"userImage":roomInfo[0].userImage,"uid":myUid,"roomName":roomInfo[0].roomName,"createdAt":Timestamp(),"postID":postID,"roomID":roomID,"documentID":documentID,"type":"like"] as [String:Any]
            let ref = Firestore.firestore().collection("users").document(uid).collection("notifications").document(documentID)
            if uid == myUid {
                return
            }else{
                batch.setData(docData, forDocument: ref)
            }
        }
    }
    
    
    
    
    
    func likeBatch(row:Int){
        let batch = Firestore.firestore().batch()
        updateLikeCount(row: row, batch: batch)
        createLikeContents(row: row, batch: batch)
        giveNotification(row: row, batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                guard let followContent = self.tableViewItems[row] as? Contents else{return}
                self.likeContentsArray.append(followContent)
            }
        }
    }
    
    
    
    
    func deleteLikeCount(row:Int,batch:WriteBatch){
        if let followContent = tableViewItems[row] as? Contents {
            
            let documentID = followContent.documentID
            let roomID = followContent.roomID
            let uid = followContent.uid
            let myUid = Auth.auth().currentUser!.uid
            
            
            let profileRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("posts").document(documentID)
            batch.setData(["likeCount": FieldValue.increment(-1.0)], forDocument: profileRef, merge: true)
            
            
            let likeCountRef = Firestore.firestore().collection("users").document(myUid).collection("rooms").document(roomID).collection("profileLikeCount").document("count")
            batch.setData(["likeCount": FieldValue.increment(-1.0)], forDocument: likeCountRef, merge: true)
            
            if followContent.mediaArray[0] != "" {
                let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
                batch.setData(["likeCount": FieldValue.increment(-1.0)], forDocument: mediaPostRef,merge: true)
            }
            
        }
    }
    
    
    
    
    
    
    func deleteLikeContent(row:Int,batch:WriteBatch){
        if let followContent = tableViewItems[row] as? Contents {
            let uid = Auth.auth().currentUser!.uid
            let documentID = followContent.documentID
            let likeRef = Firestore.firestore().collection("users").document(uid).collection("likes").document(documentID)
            batch.deleteDocument(likeRef)
        }
    }
    
    
    
    
    func deleteNotification(row:Int,batch:WriteBatch){
        if let followContent = tableViewItems[row] as? Contents {
            let uid = followContent.uid
            let myuid = Auth.auth().currentUser!.uid
            let postID = followContent.documentID
            let documentID = "\(myuid)-\(postID)"
            let ref = Firestore.firestore().collection("users").document(uid).collection("notifications").document(documentID)
            if uid == myuid {
                return
            }else{
                batch.deleteDocument(ref)
            }
        }
    }
    
    
    
    
    
    func deleteLikeBatch(row:Int){
        let batch = Firestore.firestore().batch()
        deleteLikeCount(row: row, batch: batch)
        deleteLikeContent(row: row, batch: batch)
        deleteNotification(row: row, batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                print("scucces")
            }
        }
    }
    
    
    
    
    
    
    func pushLikeButton(row:Int,sender:UIButton,countLabel:UILabel){
        if let followContent = tableViewItems[row] as? Contents {
            if sender.tintColor == UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)  {
                sender.setImage(UIImage(systemName: "heart.fill"), for: .normal)
                sender.tintColor = .red
                likeBatch(row:row)
                var count = Int(followContent.likeCount)
                count += 1
                countLabel.text = count.description
                followContent.likeCount = count
                
            }else if sender.tintColor == .red {
                sender.setImage(UIImage(systemName: "heart"), for: .normal)
                sender.tintColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
                deleteLikeBatch(row: row)
                self.likeContentsArray.removeAll(where: {$0.documentID == followContent.documentID})
                var count = Int(countLabel.text!)!
                if count >= 1{
                    count -= 1
                    countLabel.text = count.description
                    followContent.likeCount = count
                }
            }
        }
    }
    
    
    
    
    
    
    func pushedCommentButton(row:Int){
        if let followContent = tableViewItems[row] as? Contents {
            
            let cLVC = storyboard?.instantiateViewController(withIdentifier: "commentList") as! CommentViewController
            let roomInfo = joinedRoomArray.filter{ $0.documentID == followContent.roomID }
            cLVC.passedUserImage = followContent.userImage
            cLVC.passedUserName = followContent.userName
            cLVC.passedComment = followContent.text
            cLVC.passedDate = followContent.createdAt
            cLVC.passedRoomName = roomInfo[0].roomName
            cLVC.passedDocumentID = followContent.documentID
            cLVC.passedRoomID = followContent.roomID
            cLVC.passedUid = followContent.uid
            cLVC.passedMediaArray = followContent.mediaArray
            
            
            present(cLVC, animated: true, completion: nil)
            
        }
    }
    
    
    
    
    
    
    func tappedPostImageView(row:Int){
        let showImageVC = storyboard?.instantiateViewController(identifier: "showImage") as! ShowImageViewController
        let followContent = tableViewItems[row] as? Contents
        showImageVC.passedMedia = followContent!.mediaArray
        showImageVC.passedUid = followContent!.uid
        showImageVC.passedText = followContent!.text
        showImageVC.passedRoomID = followContent!.roomID
        showImageVC.passedDocumentID = followContent!.documentID
        showImageVC.passedUserName = followContent!.userName
        showImageVC.passedUserImage = followContent!.userImage
        present(showImageVC, animated: true, completion: nil)
    }
    
    
    
    
    func reportButton(row:Int){
        let modalMenuVC = storyboard!.instantiateViewController(withIdentifier: "modalMenu") as! ModalMenuViewController
        modalMenuVC.modalPresentationStyle = .custom
        modalMenuVC.transitioningDelegate = self
        if let followContent = tableViewItems[row] as? Contents {
            modalMenuVC.passedDocumentID = followContent.documentID
            modalMenuVC.passedRoomID = followContent.roomID
            modalMenuVC.passedUid = followContent.uid
        }
        modalMenuVC.passedViewController = self
        modalMenuVC.passedType = "post"
        present(modalMenuVC, animated: true, completion: nil)
    }
    
    
    
}






extension HomeViewController:UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
            return PresentModalViewController(presentedViewController: presented, presenting: presenting)
    }
}









extension HomeViewController: GADUnifiedNativeAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADUnifiedNativeAd) {
        nativeAds.append(nativeAd)
    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: GADRequestError) {
        print("\(adLoader) failed with error: \(error.localizedDescription)")
        return
    }
    
    
    func adLoaderDidFinishLoading(_ adLoader: GADAdLoader) {
        addNativeAds()
    }
    
    
    func addNativeAds(){
        self.tableViewItems.removeAll()
        
        self.tableViewItems.append(contentsOf: self.timeLineContents)
        
        if nativeAds.count <= 0 {
            return
        }
        #if DEBUG
        let adInterval = (tableViewItems.count / nativeAds.count) + 6
        var index = 6
        for nativeAd in nativeAds {
            if index < tableViewItems.count {
                tableViewItems.insert(nativeAd, at: index)
                index += adInterval
            }
        }
        timeLineTableView.reloadData()
        timeLineTableView.refreshControl?.endRefreshing()
        self.dismissIndicator()
        #else
        timeLineTableView.refreshControl?.endRefreshing()
        timeLineTableView.reloadData()
        roomCollectionView.reloadData()
        self.dismissIndicator()
        #endif
        
        
    }
    
    
}





