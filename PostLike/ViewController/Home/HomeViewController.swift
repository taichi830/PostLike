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


final class HomeViewController: UIViewController{
    
    
    
    @IBOutlet private weak var roomCollectionView: UICollectionView!
    @IBOutlet private weak var timeLineTableView: UITableView!
    @IBOutlet private weak var bluredView: UIView!
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var headerSeparaterView: UIView!
    
    
    private var joinedRoomsArray = [Contents]()
    private var likeContentsArray = [Contents]()
    private var timeLineContents = [Contents]()
    private var moderatorPosts = [Contents]()
    private var nativeAds = [GADUnifiedNativeAd]()
    private var tableViewItems = [Any]()
    private var adLoader: GADAdLoader!
    private var label = MessageLabel()
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
        self.joinedRoomsArray.removeAll()
        self.moderatorPosts.removeAll()
        self.nativeAds.removeAll()
        self.likeContentsArray.removeAll()
        self.tableViewItems.removeAll()
        fetchModeratorPosts()
        fetchJoinedRoom()
    }
    
    
    
    
    
    
    @IBAction private func allViewButton(_ sender: Any) {
        let roomList = storyboard?.instantiateViewController(identifier: "roomList") as! RoomListViewController
        roomList.passedFollwedRoomArray = joinedRoomsArray
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
        timeLineTableView.register(UINib(nibName: "FeedTableViewCell", bundle: nil), forCellReuseIdentifier: "FeedTableViewCell")
        timeLineTableView.showsVerticalScrollIndicator = true
        timeLineTableView.register(UINib(nibName: "NativeAdTableViewCell", bundle: nil), forCellReuseIdentifier: "nativeAdCell")
        timeLineTableView.tableHeaderView = headerView
        timeLineTableView.separatorInset = .zero
        
        let refleshControl = UIRefreshControl()
        self.timeLineTableView.refreshControl = refleshControl
        self.timeLineTableView.refreshControl?.addTarget(self, action: #selector(updateContents), for: .valueChanged)
    }
    
    
    
    
    
    
    
    private func fetchJoinedRoom(){
        self.joinedRoomsArray.removeAll()
        Firestore.fetchJoinedRooms { contents in
            if contents.isEmpty == true {
                self.timeLineTableView.refreshControl?.endRefreshing()
                self.roomCollectionView.reloadData()
            }else{
                self.label.removeFromSuperview()
                self.joinedRoomsArray.append(contentsOf: contents)
                self.roomCollectionView.reloadData()
                
            }
        }
    }
    
    
    
    
    
    
    private func fetchReportedContents(documentIDs:[String],_ completed: @escaping() -> Void) {
        Firestore.fetchReportedContents(documentIDs: documentIDs) { contents in
            for content in contents {
                self.timeLineContents.removeAll { timeLineContent in
                    timeLineContent.documentID == content.documentID
                }
            }
            completed()
        }
    }
    
    
    
    
    
    private func fetchReportedUsers(uids:[String],_ completed: @escaping() -> Void){
        Firestore.fetchReportedUsers(uids: uids) { contents in
            for content in contents {
                self.timeLineContents.removeAll { timeLineContent in
                    timeLineContent.uid == content.uid && timeLineContent.roomID == content.roomID
                }
            }
            completed()
        }
    }
    
    
    
    
    
    
    
    
    
    private func fetchLikeContents(documentIDs:[String]){
        Firestore.fetchLikeContents(documentIDs: documentIDs) { contents in
            self.likeContentsArray.append(contentsOf: contents)
        }
    }
    
    
    
    
    
    
    
    
    private func fetchTimelinePosts(completion: @escaping([Contents]) -> Void){
        self.timeLineContents.removeAll()
        Firestore.fetchTimeLinePosts { querySnapshot, contents, uids, documentIDs in
            if self.joinedRoomsArray.count == 0 {
                self.label.setup(text: "ルームを作成、探して参加しよう！", at: self.timeLineTableView)
                completion([])
                
            } else if contents.count == 0 {
                self.label.setup(text: "投稿がまだありません。", at: self.timeLineTableView)
                self.timeLineTableView.refreshControl?.endRefreshing()
                completion([])
                
            }else{
                self.label.removeFromSuperview()
                self.timeLineContents.append(contentsOf: contents)
                self.fetchReportedContents(documentIDs: documentIDs) {
                    self.fetchReportedUsers(uids: uids) {
                        completion(self.timeLineContents)
                    }
                }
            }
        }
    }
    
    
    
    
    
    private func fetchModeratorPosts(){
        fetchTimelinePosts(completion: { timeLineContents in
            if timeLineContents.isEmpty == true {
                self.timeLineTableView.reloadData()
                self.timeLineTableView.refreshControl?.endRefreshing()
                self.dismissIndicator()
            }else{
                let documentIDs = timeLineContents.map { element -> String in
                    return element.documentID
                }
                self.fetchLikeContents(documentIDs: documentIDs)
                Firestore.fetchModeratorPosts(documentIDs: documentIDs) { contents in
                    self.moderatorPosts.append(contentsOf: contents)
                    self.loadAdmob(numberOfAds: contents.count)
                }
            }
        })
    }
    
    
    
    
    
    private func fetchMoreTimelinePosts(completion: @escaping([Contents]) -> Void){
        self.timeLineContents.removeAll()
        guard let lastDocument = lastDocument else {return}
        Firestore.fetchMoreTimelinePosts(lastDocument: lastDocument) { querySnapshot, contents, uids, documentIDs in
            if contents.isEmpty == false {
                self.lastDocument = querySnapshot.documents.last
                self.timeLineContents.append(contentsOf: contents)
                self.fetchReportedContents(documentIDs: documentIDs) {
                    self.fetchReportedUsers(uids: uids) {
                        completion(self.timeLineContents)
                    }
                }
            }
        }
    }
    
    
    
    
    
    
    private func fetchMoreModeratorPosts(){
        fetchMoreTimelinePosts { timeLineContents in
            let documentIDs = timeLineContents.map { element -> String in
                return element.documentID
            }
            self.fetchLikeContents(documentIDs: documentIDs)
            Firestore.fetchMoreModeratorPosts(documentIDs: documentIDs) { contents in
                self.moderatorPosts.append(contentsOf: contents)
                self.loadAdmob(numberOfAds: self.moderatorPosts.count)
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
        if self.joinedRoomsArray.isEmpty == true {
            return 5
        }else{
            return joinedRoomsArray.count
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        let cell = roomCollectionView.dequeueReusableCell(withReuseIdentifier: "myroomCell", for: indexPath) as! RoomCollectionViewCell
        if self.joinedRoomsArray.count != 0 {
            cell.roomName.text = joinedRoomsArray[indexPath.row].roomName
            if joinedRoomsArray[indexPath.row].roomImage != "" {
                cell.roomImage.sd_setImage(with: URL(string: joinedRoomsArray[indexPath.row].roomImage), completed: nil)
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
        if self.joinedRoomsArray.count != 0 {
            let enteredVC = storyboard?.instantiateViewController(withIdentifier: "enteredVC") as! EnteredRoomContentViewController
            enteredVC.passedDocumentID = joinedRoomsArray[indexPath.row].documentID
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
            let cell = timeLineTableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell", for: indexPath) as! FeedTableViewCell
            
            cell.tableViewCellDelegate = self
            
            cell.setContent(contents: timeLineContent, likeContensArray: likeContentsArray)
            
            let roomNameArray = joinedRoomsArray.filter {
                $0.documentID == timeLineContent.roomID
            }
            let roomNameLabel = cell.roomNameLabel
            if roomNameArray.isEmpty != true {
                roomNameLabel?.text = ("\(roomNameArray[0].roomName)")
                roomNameLabel?.adjustsFontSizeToFitWidth = true
                roomNameLabel?.minimumScaleFactor = 0.8
            }
            let tapRoomLabel = UITapGestureRecognizer(target: self, action: #selector(tappedRoomNameLabel(_:)))
            roomNameLabel?.addGestureRecognizer(tapRoomLabel)
            
            
            
            
            return cell
            
        }else{
            
            if let nativeAd = tableViewItems[safe:indexPath.row] as? GADUnifiedNativeAd {
                
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
        let tappedRow = tappedIndexPath!.row
        let enteredVC = storyboard?.instantiateViewController(withIdentifier: "enteredVC") as! EnteredRoomContentViewController
        if let followContent = tableViewItems[tappedRow] as? Contents {
            let roomInfo = joinedRoomsArray.filter {
                $0.documentID == followContent.roomID
            }
            enteredVC.passedDocumentID = roomInfo[0].documentID
            navigationController?.pushViewController(enteredVC, animated: true)
        }
    }
    
    
    
    
    
}







extension HomeViewController:RemoveContentsDelegate{
    
    func removeMutedContent(documentID:String) {
        self.tableViewItems.removeAll { content  in
            let content = content as? Contents
            return (content?.documentID  == documentID )
        }
        self.timeLineTableView.reloadData()
    }
    
    func removeBlockedUserContents(uid:String,roomID:String) {
        self.tableViewItems.removeAll { content  in
            let content = content as? Contents
            return content?.uid  == uid && content?.roomID == roomID
        }
        self.timeLineTableView.reloadData()
    }
    
}



extension HomeViewController:TableViewCellDelegate {
    
    private func updateLikeCount(row:Int,batch:WriteBatch){
        if let followContent = tableViewItems[row] as? Contents {
            let roomID = followContent.roomID
            let documentID = followContent.documentID
            let mediaArray = followContent.mediaArray[0]
            let uid = followContent.uid
            let myuid = Auth.auth().currentUser!.uid
            Firestore.increaseLikeCount(uid: uid, myuid: myuid, roomID: roomID, documentID: documentID, mediaUrl: mediaArray, batch: batch)
        }
    }
    
    
    
    
    private func createLikeContents(row:Int,batch:WriteBatch){
        
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
            let dic = [
                "media": media,
                "text":text,
                "userName":userName,
                "userImage":userImage,
                "documentID":documentID,
                "roomID":roomID,
                "createdAt":createdAt,
                "uid":uid,
                "postedAt":postedAt,
                "myUid":myuid
            ] as [String:Any]
            Firestore.createLikedPost(myuid: myuid, documentID: documentID, dic: dic, batch: batch)
        }
    }
    
    
    
    
    private func giveNotification(row:Int,batch:WriteBatch){
        if let followContent = tableViewItems[row] as? Contents {
            let myuid = Auth.auth().currentUser!.uid
            let uid = followContent.uid
            let postID = followContent.documentID
            let roomID = followContent.roomID
            let roomInfo = joinedRoomsArray.filter{ $0.documentID == followContent.roomID }
            let documentID = "\(myuid)-\(postID)"
            let dic = [
                "userName":roomInfo[0].userName,
                "userImage":roomInfo[0].userImage,
                "uid":myuid,
                "roomName":roomInfo[0].roomName,
                "createdAt":Timestamp(),
                "postID":postID,
                "roomID":roomID,
                "documentID":documentID,
                "type":"like"
            ] as [String:Any]
            Firestore.createNotification(uid: uid, myuid: myuid, documentID: documentID, dic: dic, batch: batch)
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
                guard let followContent = self.tableViewItems[row] as? Contents else{return}
                self.likeContentsArray.append(followContent)
            }
        }
    }
    
    
    
    
    private func deleteLikeCount(row:Int,batch:WriteBatch){
        if let followContent = tableViewItems[row] as? Contents {
            
            let documentID = followContent.documentID
            let roomID = followContent.roomID
            let uid = followContent.uid
            let myuid = Auth.auth().currentUser!.uid
            let mediaArray = followContent.mediaArray[0]
            Firestore.decreaseLikeCount(uid: uid, myuid: myuid, roomID: roomID, documentID: documentID, mediaUrl: mediaArray, batch: batch)
        }
    }
    
    
    
    
    
    
    private func deleteLikeContent(row:Int,batch:WriteBatch){
        if let followContent = tableViewItems[row] as? Contents {
            let uid = Auth.auth().currentUser!.uid
            let documentID = followContent.documentID
            Firestore.deleteLikedPost(uid: uid, documentID: documentID, batch: batch)
        }
    }
    
    
    
    
    private func deleteNotification(row:Int,batch:WriteBatch){
        if let followContent = tableViewItems[row] as? Contents {
            let uid = followContent.uid
            let myuid = Auth.auth().currentUser!.uid
            let postID = followContent.documentID
            let documentID = "\(myuid)-\(postID)"
            Firestore.deleteNotification(uid: uid, myuid: myuid, documentID: documentID, batch: batch)
        }
    }
    
    
    
    
    
    private func deleteLikeBatch(row:Int){
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
            let roomInfo = joinedRoomsArray.filter{ $0.documentID == followContent.roomID }
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
        modalMenuVC.passedType = ModalType.post.rawValue
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
    
    
    private func addNativeAds(){
        self.tableViewItems.removeAll()
        
        self.tableViewItems.append(contentsOf: self.moderatorPosts)
        
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





