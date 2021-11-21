//
//  ProfileViewController.swift
//  postLike
//
//  Created by taichi on 2021/04/10.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import Firebase


protocol DeletePostDelegate:AnyObject {
    func deletePostBatch(documentID:String,imageUrl:[String])
}
protocol ExitRoomDelegate:AnyObject {
    func exitRoomBatch()
}
protocol DeleteRoomDelegate:AnyObject {
    func deleteRoomAtContainerView()
}




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
        
        fetchPostContents {
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
        }else{
            headerView.profileEditButton.layer.cornerRadius = 2
            headerView.profileEditButton.layer.borderColor = UIColor.systemGray5.cgColor
            headerView.profileEditButton.layer.borderWidth = 1
            headerView.profileEditButton.addTarget(self, action: #selector(self.pushProfileEditButton), for: .touchUpInside)
            
            headerView.editButtonStackView.isHidden = true
            
        }
    }
    
    
    
    
    @objc func pushProfileEditButton(){
        let editVC = storyboard?.instantiateViewController(identifier: "editVC") as! ProfileEditViewController
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
        let profileModalVC = storyboard?.instantiateViewController(withIdentifier: "profileModal") as! ProfileModalViewController
        let uid = Auth.auth().currentUser!.uid
        profileModalVC.modalPresentationStyle = .custom
        profileModalVC.transitioningDelegate = self
        profileModalVC.exitRoomDelegate = self
        profileModalVC.passedModerator = passedModerator
        profileModalVC.passedRoomID = passedDocumentID
        profileModalVC.passedViewController = self
        if passedModerator == uid {
            profileModalVC.passedType = "moderator"
        }else{
            profileModalVC.passedType = "exit"
        }
        present(profileModalVC, animated: true, completion: nil)
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
        
        
        let cell = profileTableView.dequeueReusableCell(withIdentifier: "postTable")  as! PostTableViewCell
        
        cell.tableViewCellDelegate = self
        
        cell.setContent(contents: contentsArray[indexPath.row], likeContensArray: likeContentsArray)

        
        return cell
    }
    
    
 
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == contentsArray.count {
            fetchMoreContents()
        }
    }
    
    
    
    
    
    //likeBatch
    
    func createLikeContents(row:Int,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let documentID = contentsArray[row].documentID
        let roomID = passedDocumentID
        let postedAt = contentsArray[row].createdAt
        let timestamp = Timestamp()
        let docData = ["media": contentsArray[row].mediaArray,"text":contentsArray[row].text,"userImage":contentsArray[row].userImage,"userName":contentsArray[row].userName,"documentID":documentID,"roomID":roomID,"uid":uid,"postedAt":postedAt,"createdAt":timestamp,"myUid":uid] as [String:Any]
        let ref = Firestore.firestore().collection("users").document(uid).collection("likes").document(documentID)
        batch.setData(docData, forDocument: ref)
    }
    
    
    
    func updateLikeCount(row:Int,batch:WriteBatch){
        let documentID = contentsArray[row].documentID
        let roomID = passedDocumentID
        let uid = Auth.auth().currentUser!.uid
        
        let profileRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("posts").document(documentID)
        batch.setData(["likeCount": FieldValue.increment(1.0)], forDocument: profileRef, merge: true)
        
        let likeCountRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(roomID).collection("profileLikeCount").document("count")
        batch.setData(["likeCount": FieldValue.increment(1.0)], forDocument: likeCountRef, merge: true)
        
        if contentsArray[row].mediaArray[0] != "" {
            let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
            batch.updateData(["likeCount":FieldValue.increment(1.0)], forDocument: mediaPostRef)
        }
    }
    
    
    
    func likeBatch(row:Int){
        let batch = Firestore.firestore().batch()
        createLikeContents(row: row, batch: batch)
        updateLikeCount(row: row, batch: batch)
        batch.commit()
    }
    
    
    
    
    
    
    
    
    
    
    //deleteBatch
    
    func decreaseLikeCount(row: Int,batch:WriteBatch){
        let documentID = contentsArray[row].documentID
        let roomID = passedDocumentID
        let uid = Auth.auth().currentUser!.uid
        
        let profileContentRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).collection("posts").document(documentID)
        batch.setData(["likeCount": FieldValue.increment(-1.0)], forDocument: profileContentRef, merge: true)
        
        let likeCountRef = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).collection("profileLikeCount").document("count")
        batch.setData(["likeCount": FieldValue.increment(-1.0)], forDocument: likeCountRef, merge: true)
        
        if contentsArray[row].mediaArray[0] != "" {
            let mediaPostRef = Firestore.firestore().collection("rooms").document(roomID).collection("mediaPosts").document(documentID)
            batch.updateData(["likeCount":FieldValue.increment(-1.0)], forDocument: mediaPostRef)
        }
    }
    
    
    
    
    func deleteLikeContents(row:Int,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let documentID = contentsArray[row].documentID
        let ref = Firestore.firestore().collection("users").document(uid).collection("likes").document(documentID)
        batch.deleteDocument(ref)
    }
    
    
    
    
    func deleteLikeBatch(row:Int){
        let batch = Firestore.firestore().batch()
        let documentID = contentsArray[row].documentID
        decreaseLikeCount(row: row, batch: batch)
        deleteLikeContents(row: row, batch: batch)
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
    
    
    
    
    
    
    

}






extension ProfileViewController:TableViewCellDelegate{
    func reportButton(row: Int) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let modalMenuVC = storyboard.instantiateViewController(withIdentifier: "modalMenu") as! ModalMenuViewController
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




extension ProfileViewController:DeletePostDelegate{
    
    
    func deleteMediaPosts(batch:WriteBatch,documentID:String){
        let documentID = contentsArray[row].documentID
        let ref =  Firestore.firestore().collection("rooms").document(passedDocumentID).collection("mediaPosts").document(documentID)
        batch.deleteDocument(ref)
    }
    
    
    func deletePosts(batch:WriteBatch,documentID:String){
        let uid = Auth.auth().currentUser!.uid
        let documentID = contentsArray[row].documentID
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).collection("posts").document(documentID)
        batch.deleteDocument(ref)
    }
    
    
    func deleteModeratorPosts(batch:WriteBatch,documentID:String){
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

    
    func deleteStrageFile(imageUrl:Array<String>){
        let storage = Storage.storage()
        if imageUrl.count == 1{
            let imageRef = NSString(string: imageUrl[0])
            let desertRef = storage.reference(forURL: imageRef as String)
            desertRef.delete { err in
                if err != nil {
                    print("false")
                    return
                }else{
                    print("success")
                }
            }
        }else if imageUrl.count == 2 {
            let imageRef = NSString(string: imageUrl[0])
            let desertRef = storage.reference(forURL: imageRef as String)
            desertRef.delete { err in
                if err != nil {
                    print("false")
                    return
                }else{
                    print("success")
                }
            }
            let imageRef2 = NSString(string: imageUrl[1])
            let desertRef2 = storage.reference(forURL: imageRef2 as String)
            desertRef2.delete { err in
                if err != nil {
                    print("false")
                    return
                }else{
                    print("success")
                }
            }
        }
        
        
    }
    
    
    
    func deletePostBatch(documentID:String,imageUrl:[String]){
        let uid = Auth.auth().currentUser?.uid
        let batch = Firestore.firestore().batch()
        let mappedArray = contentsArray.filter {
            $0.documentID == documentID
        }
        deletePosts(batch: batch,documentID:documentID)
        decreasePostCount(batch: batch)
        decreaseRoomPostCount(batch: batch)
        if passedModerator == uid {
            deleteModeratorPosts(batch: batch,documentID:documentID)
        }
        if mappedArray[0].mediaArray[0] != "" {
            deleteMediaPosts(batch: batch,documentID:documentID)
        }
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                self.contentsArray.removeAll {
                    $0.documentID == mappedArray[0].documentID
                }
                self.profileTableView.reloadData()
                if imageUrl[0] != "" {
                    self.deleteStrageFile(imageUrl: imageUrl)
                }
                
            }
        }
    }
}







extension ProfileViewController:ExitRoomDelegate{
    
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
    
    func exitRoomBatch(){
        let batch = Firestore.firestore().batch()
        exitRoom(batch: batch)
        decreaseMemberCount(batch: batch)
        deleteUidFromRoomMateList(batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    
    
    
}


extension ProfileViewController:DeleteRoomDelegate{
    
    func deleteRoom(batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(passedDocumentID)
        batch.deleteDocument(ref)
    }
    
    func deleteMemberCount(batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(passedDocumentID).collection("memberCount").document("count")
        batch.deleteDocument(ref)
    }
    
    func deleteRoomPostCount(batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(passedDocumentID).collection("roomPostCount").document("count")
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
        deleteMemberCount(batch: batch)
        deleteRoomPostCount(batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    
    
    
}










