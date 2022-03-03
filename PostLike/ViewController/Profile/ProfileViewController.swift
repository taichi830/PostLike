//
//  ProfileViewController.swift
//  postLike
//
//  Created by taichi on 2021/04/10.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage


protocol DeletePostDelegate:AnyObject {
    func deletePostBatch(documentID:String,imageUrl:[String])
}
protocol ExitRoomDelegate:AnyObject {
    func exitRoomBatch()
}
protocol DeleteRoomDelegate:AnyObject {
    func deleteRoomAtContainerView()
}




final class ProfileViewController: UIViewController {
    
    
    var passedDocumentID = String()
    var passedModerator = String()
    private var contentsArray = [Contents]()
    private var userInfo:Contents?
    private var likeContentsArray = [Contents]()
    private var lastDocument:DocumentSnapshot?
    private var messageLabel = MessageLabel()
    private var viewModel: ProfileViewModel!
    private let disposeBag = DisposeBag()
    
    
    
    @IBOutlet private weak var headerView: UserProfileHeaderView!
    @IBOutlet private weak var titleName: UILabel!
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var profileTableView: UITableView!
    
    
    
    
    override func viewDidLoad(){
        super.viewDidLoad()
        let uid = Auth.auth().currentUser!.uid
        viewModel = ProfileViewModel(profileContentsListner: ProfileContentsDefaultListner(), likeListner: LikeDefaultListner(), uid: uid, roomID: passedDocumentID)
        createProfileTableView()
        setUpEditButton()
        emptyCheck()
        
        let refleshControl = UIRefreshControl()
        self.profileTableView.refreshControl = refleshControl
        self.profileTableView.refreshControl?.addTarget(self, action: #selector(updateContents), for: .valueChanged)
        
        
        self.setSwipeBackGesture()
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserInfo()
        fetchPostCount()
        fetchLikeCount()
    }
    
    
    
    
    
    
    
    
    @objc private func updateContents(){
//        self.likeContentsArray.removeAll()
//        self.fetchPostContents {
//            self.profileTableView.refreshControl?.endRefreshing()
//        }
    }
    
    
    
    
    private func createProfileTableView(){
        profileTableView.delegate = self
        profileTableView.dataSource = self
        profileTableView.tableHeaderView = headerView
        profileTableView.register(UINib(nibName: "FeedTableViewCell", bundle: nil), forCellReuseIdentifier: "FeedTableViewCell")
    }
    
    
    
    
    private func setUpEditButton(){
        let uid = Auth.auth().currentUser!.uid
        if passedModerator == uid {
            headerView.profileEditButton.isHidden = true
            headerView.hostProfileEditButton.addTarget(self, action: #selector(self.pushProfileEditButton), for: .touchUpInside)
            headerView.roomEditButton.addTarget(self, action: #selector(self.pushRoomEditButton), for: .touchUpInside)
        }else{
            headerView.profileEditButton.addTarget(self, action: #selector(self.pushProfileEditButton), for: .touchUpInside)
            headerView.editButtonStackView.isHidden = true
            
        }
    }
    
    
    
    
    @objc private func pushProfileEditButton(){
        let editVC = storyboard?.instantiateViewController(identifier: "editVC") as! ProfileEditViewController
        editVC.passedRoomName = titleName.text ?? ""
        editVC.passedDocumentID = passedDocumentID
        editVC.passedUserImage = self.userInfo?.userImage ?? ""
        editVC.passedUserName = self.userInfo?.userName ?? ""
        editVC.hidesBottomBarWhenPushed = true
        present(editVC, animated: true, completion: nil)
    }
    
    
    
    
    @objc private func pushRoomEditButton(){
        let roomEditVC = storyboard?.instantiateViewController(identifier: "editRoom") as! RoomEditViewController
        roomEditVC.passedRoomName = titleName.text ?? ""
        roomEditVC.passedRoomImage = self.userInfo?.roomImage ?? ""
        roomEditVC.passedDocumentID = passedDocumentID
        roomEditVC.hidesBottomBarWhenPushed = true
        present(roomEditVC, animated: true, completion: nil)
    }
    
    
    
    
    
    @IBAction private func menuButton(_ sender: Any) {
        let uid = Auth.auth().currentUser!.uid
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let modalMenuVC = storyboard.instantiateViewController(withIdentifier: "modalMenu") as! ModalMenuViewController
        modalMenuVC.modalPresentationStyle = .custom
        modalMenuVC.transitioningDelegate = self
        modalMenuVC.exitRoomDelegate = self
        modalMenuVC.passedRoomID = passedDocumentID
        modalMenuVC.passedViewController = self
        if passedModerator == uid {
            modalMenuVC.passedModalType = .moderator
        }else{
            modalMenuVC.passedModalType = .exit
        }
        present(modalMenuVC, animated: true, completion: nil)
    }
    
    
    
    

    @IBAction private func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    
//    private func fetchLikeContents(documentIDs:[String]){
//        Firestore.fetchLikeContents(documentIDs: documentIDs) { contents in
//            self.likeContentsArray.append(contentsOf: contents)
//        }
//    }
    
    
    private func fetchContents() {
        viewModel.items.drive { [weak self] items in
            self?.contentsArray.removeAll()
            self?.contentsArray.append(contentsOf: items)
            self?.profileTableView.reloadData()
        }
        .disposed(by: disposeBag)
        
        viewModel.likes
            .drive { [weak self] likes in
                self?.likeContentsArray.removeAll()
                self?.likeContentsArray.append(contentsOf: likes)
                self?.profileTableView.reloadData()
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    private func emptyCheck(){

        viewModel.isEmpty
            .drive { [weak self] bool in
                if bool == true {
                    self?.messageLabel.setupLabel(view: self!.view, y: self!.view.center.y + 50)
                    self?.messageLabel.text = "投稿がまだありません"
                    self?.profileTableView.addSubview(self!.messageLabel)
                } else {
                    self?.messageLabel.text = ""
                    self?.fetchContents()
                    
                }
            }
            .disposed(by: disposeBag)
        
    }
    
    
    
    
    
    
//    private func fetchMoreContents(){
//        guard let lastDocument = self.lastDocument else {return}
//        Firestore.fetchMoreUserContents(roomID: passedDocumentID, lastDocument: lastDocument) { contents, querySnapshot in
//            if contents.isEmpty == false {
//                let documentIDs = contents.map { contents -> String in
//                    return contents.documentID
//                }
//                self.fetchLikeContents(documentIDs: documentIDs)
//                self.lastDocument = querySnapshot.documents.last
//                self.contentsArray.append(contentsOf: contents)
//                self.profileTableView.reloadData()
//            }
//        }
//    }
    
    
    
    private func fetchPostCount(){
        Firestore.fetchPostCount(roomID: passedDocumentID) { postCount in
            self.headerView.postCountLabel.text = postCount.postCount.description
        }
    }
    
    
    
    
    
    private func fetchLikeCount(){
        Firestore.fetchLikeCount(roomID: passedDocumentID) { likeCount in
            self.headerView.likeCountLabel.text = likeCount.likeCount.description
        }
    }
    
    
    
    
    private func fetchUserInfo(){
        Firestore.fetchUserInfo(roomID: passedDocumentID) { userInfo in
            self.userInfo = userInfo
            self.titleName.adjustsFontSizeToFitWidth = true
            self.titleName.minimumScaleFactor = 0.9
            self.titleName.text = userInfo.roomName
            self.headerView.userNameLabel.text = userInfo.userName
            if userInfo.userImage != "" {
                self.headerView.userImageView.sd_setImage(with: URL(string: userInfo.userImage), completed: nil)
                self.headerView.personImageView.image = UIImage()
            }
        }
    }
    
    
    
    
    
}




extension ProfileViewController:UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentModalViewController(presentedViewController: presented, presenting: presenting)
    }
}







extension ProfileViewController:UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return contentsArray.count
    }
    
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let cell = profileTableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell")  as! FeedTableViewCell
        cell.setContent(contents: contentsArray[indexPath.row], likeContensArray: likeContentsArray)
        cell.setupBinds(content: contentsArray[indexPath.row], roomID: passedDocumentID, vc: self, modalType: .delete)

        
        return cell
    }
    
    
 
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == contentsArray.count {
//            fetchMoreContents()
        }
    }
    
    
    
    
    
    //likeBatch
    
//    private func createLikeContents(uid:String,documentID:String,row:Int,batch:WriteBatch){
//        let dic = [
//            "media": contentsArray[row].mediaArray,
//            "text":contentsArray[row].text,
//            "userImage":contentsArray[row].userImage,
//            "userName":contentsArray[row].userName,
//            "documentID":documentID,
//            "roomID":passedDocumentID,
//            "uid":uid,
//            "postedAt":contentsArray[row].createdAt,
//            "createdAt":Timestamp(),
//            "myUid":uid] as [String:Any]
//        Firestore.createLikedPost(myuid: uid, documentID: documentID, dic: dic, batch: batch)
//    }
//
//
//
//    private func updateLikeCount(uid:String,documentID:String,row:Int,batch:WriteBatch){
//        let mediaUrl = contentsArray[row].mediaArray[0]
//        Firestore.increaseLikeCount(uid: uid, myuid: uid, roomID: passedDocumentID, documentID: documentID, mediaUrl: mediaUrl, batch: batch)
//    }
//
//
//
//    private func likeBatch(row:Int){
//        let uid = Auth.auth().currentUser!.uid
//        let documentID = contentsArray[row].documentID
//        let batch = Firestore.firestore().batch()
//        createLikeContents(uid:uid,documentID:documentID,row: row, batch: batch)
//        updateLikeCount(uid:uid,documentID:documentID,row: row, batch: batch)
//        batch.commit()
//    }
//
//
//
//
//
//
//
//
//
//
//    //deleteBatch
//
//    private func decreaseLikeCount(uid:String,documentID:String,row: Int,batch:WriteBatch){
//        let mediaUrl = contentsArray[row].mediaArray[0]
//        Firestore.decreaseLikeCount(uid: uid, myuid: uid, roomID: passedDocumentID, documentID: documentID, mediaUrl: mediaUrl, batch: batch)
//    }
//
//
//
//
//    private func deleteLikeContents(uid:String,documentID:String,row:Int,batch:WriteBatch){
//        Firestore.deleteLikedPost(uid: uid, documentID: documentID, batch: batch)
//    }
//
//
//
//
//    private func deleteLikeBatch(row:Int){
//        let uid = Auth.auth().currentUser!.uid
//        let documentID = contentsArray[row].documentID
//        let batch = Firestore.firestore().batch()
//        decreaseLikeCount(uid: uid, documentID: documentID, row: row, batch: batch)
//        deleteLikeContents(uid: uid, documentID: documentID,row: row, batch: batch)
//        batch.commit { err in
//            if let err = err {
//                print("false\(err)")
//                return
//            }else{
//                print("scuccess")
//                self.likeContentsArray.removeAll(where: {$0.documentID == documentID})
//            }
//        }
//    }
    
    
    
    
    
    
    

}





//MARK: tableViewのデリゲート処理
//extension ProfileViewController:TableViewCellDelegate{
//    func reportButton(row: Int) {
//        let storyboard = UIStoryboard(name: "Home", bundle: nil)
//        let modalMenuVC = storyboard.instantiateViewController(withIdentifier: "modalMenu") as! ModalMenuViewController
//        modalMenuVC.modalPresentationStyle = .custom
//        modalMenuVC.transitioningDelegate = self
//        modalMenuVC.passedDocumentID = contentsArray[row].documentID
//        modalMenuVC.passedRoomID = contentsArray[row].roomID
//        modalMenuVC.passedImageUrl = contentsArray[row].mediaArray
//        modalMenuVC.passedViewController = self
//        modalMenuVC.deletePostDelegate = self
//        modalMenuVC.passedType = ModalType.delete.rawValue
//        present(modalMenuVC, animated: true, completion: nil)
//    }
//
//    func tappedPostImageView(row: Int) {
//        let storyboard = UIStoryboard(name: "Home", bundle: nil)
//        let showImageVC = storyboard.instantiateViewController(identifier: "showImage") as! ShowImageViewController
//        showImageVC.passedMedia = contentsArray[row].mediaArray
//        showImageVC.passedUid = contentsArray[row].uid
//        showImageVC.passedText = contentsArray[row].text
//        showImageVC.passedRoomID = contentsArray[row].roomID
//        showImageVC.passedDocumentID = contentsArray[row].documentID
//        showImageVC.passedUserName = contentsArray[row].userName
//        showImageVC.passedUserImage = contentsArray[row].userImage
//        present(showImageVC, animated: true, completion: nil)
//    }
//
//    func pushLikeButton(row: Int, sender: UIButton, countLabel: UILabel) {
//        if sender.tintColor == UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)  {
//            sender.setImage(UIImage(systemName: "heart.fill"), for: .normal)
//            sender.tintColor = .red
//            likeBatch(row:row)
//            var count = Int(contentsArray[row].likeCount)
//            count += 1
//            countLabel.text = count.description
//            contentsArray[row].likeCount = count
//
//        }else if sender.tintColor == .red {
//            sender.setImage(UIImage(systemName: "heart"), for: .normal)
//            sender.tintColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
//            deleteLikeBatch(row: row)
//            self.likeContentsArray.removeAll(where: {$0.documentID == contentsArray[row].documentID})
//            var count = Int(countLabel.text!)!
//            if count >= 1{
//                count -= 1
//                countLabel.text = count.description
//                contentsArray[row].likeCount = count
//            }
//        }
//    }
//
//    func pushedCommentButton(row: Int) {
//        let storyboard = UIStoryboard(name: "Home", bundle: nil)
//        let cLVC = storyboard.instantiateViewController(withIdentifier: "commentList") as! CommentViewController
//        cLVC.passedUserImage = contentsArray[row].userImage
//        cLVC.passedUserName = contentsArray[row].userName
//        cLVC.passedComment = contentsArray[row].text
//        cLVC.passedDate = contentsArray[row].createdAt
//        cLVC.passedDocumentID = contentsArray[row].documentID
//        cLVC.passedRoomID = contentsArray[row].roomID
//        cLVC.passedUid = contentsArray[row].uid
//        cLVC.passedMediaArray = contentsArray[row].mediaArray
//
//        present(cLVC, animated: true, completion: nil)
//    }
//
//
//}



//MARK: 投稿削除時のデリゲート処理
//extension ProfileViewController:DeletePostDelegate{
//
//
//
//    func deletePostBatch(documentID:String,imageUrl:[String]){
//        let uid = Auth.auth().currentUser!.uid
//        let batch = Firestore.firestore().batch()
//        let mappedArray = contentsArray.filter { $0.documentID == documentID }
//        Firestore.decreasePostCount(roomID: passedDocumentID, batch: batch)
//        Firestore.decreaseRoomPostCount(roomID: passedDocumentID, batch: batch)
//        Firestore.deletePosts(roomID: passedDocumentID, documentID: documentID, batch: batch)
//        Firestore.deleteModeratorPosts(uid: uid, moderatorUid: passedModerator,roomID: passedDocumentID, documentID: documentID, batch: batch)
//        if mappedArray[0].mediaArray[0] != "" {
//            Firestore.deleteMediaPosts(roomID: passedDocumentID, documentID: documentID, batch: batch)
//        }
//        batch.commit { err in
//            if let err = err {
//                print("false\(err)")
//                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
//                    self.dismissIndicator()
//                }
//                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
//                return
//            }
//            self.contentsArray.removeAll {
//                $0.documentID == mappedArray[0].documentID
//            }
//            if imageUrl[0] != "" {
//                Storage.deleteStrageFile(imageUrl: imageUrl)
//            }
//            self.profileTableView.reloadData()
//        }
//    }
//}






//MARK: ルーム退出時のデリゲート処理
extension ProfileViewController:ExitRoomDelegate{
    
    func exitRoomBatch(){
        let batch = Firestore.firestore().batch()
        Firestore.exitRoom(documentID: passedDocumentID, batch: batch)
        Firestore.decreaseMemberCount(documentID: passedDocumentID, batch: batch)
        Firestore.deleteUidFromRoomMateList(documentID: passedDocumentID, batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }else{
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    
    
    
}



//MARK: ルーム削除時のデリゲート処理
extension ProfileViewController:DeleteRoomDelegate{

    func deleteRoomAtContainerView(){
        let batch = Firestore.firestore().batch()
        Firestore.deleteRoom(documentID: passedDocumentID, batch: batch)
        Firestore.deleteMyprofile(documentID: passedDocumentID, batch: batch)
        Firestore.deleteMemberCount(documentID: passedDocumentID, batch: batch)
        Firestore.deleteRoomPostCount(documentID: passedDocumentID, batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }else{
                self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    
    
    
}










