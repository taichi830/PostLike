//
//  ContentViewController.swift
//  postLike
//
//  Created by taichi on 2021/02/06.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import Firebase

class ContentViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
   
    
    
    
    @IBOutlet weak var holeView: UIView!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var contentImage: UIImageView!
    @IBOutlet weak var contentImage2: UIImageView!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var createdTimeLabel: UILabel!
    @IBOutlet weak var writeComment: UILabel!
    @IBOutlet weak var postTableView: UITableView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var countLabel: UILabel!
    
    
    
    
    
    
    var passedUserImageUrl = String()
    var passedUserName = String()
    var passedCommentLabel = String()
    var passedImageArray = Array<Any>()
    var passedTimestamp = Timestamp()
    var passedRoomName = String()
    var passedIndex = Int()
    var passedUid = String()
    var contentsArray = [Room]()
    var profileArray = [Contents]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        postTableView.delegate = self
        postTableView.dataSource = self
        postTableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: "postTable")
        
        userImage.layer.cornerRadius = 18
        userImage.sd_setImage(with: URL(string: passedUserImageUrl), completed: nil)
        userName.text = passedUserName
        commentLabel.text = passedCommentLabel


        createContentImage()
        writeCreatedAt()
        fetchImageContents()
        fetchProfile()
        
       
       
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let  headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: holeView.frame.height))
       
        postTableView.tableHeaderView = headerView
        
        if let tableHeaderView = self.postTableView.tableHeaderView {
            tableHeaderView.addSubview(holeView)
            tableHeaderView.setNeedsLayout()
            tableHeaderView.layoutIfNeeded()
            let size = tableHeaderView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            tableHeaderView.frame = CGRect.init(x: 0, y: 0, width: 375, height: size)
            self.postTableView.tableHeaderView = tableHeaderView
        }
        
    }
    
    func createContentImage(){
        if passedImageArray.count == 1 {
            contentImage.frame = CGRect(x: 0, y: 0, width: 357, height: 231)
            contentImage.sd_setImage(with: URL(string: passedImageArray[0] as! String), completed: nil)
            contentImage.layer.cornerRadius = 5
            
            
        }else if passedImageArray.count == 2 {
            contentImage.frame = CGRect(x: 0, y: 0, width: 175, height: 231)
            contentImage.sd_setImage(with: URL(string: passedImageArray[0] as! String), completed: nil)
            contentImage2.frame = CGRect(x: 182, y: 0, width: 175, height: 231)
            contentImage2.sd_setImage(with: URL(string: passedImageArray[1] as! String), completed: nil)
            contentImage.layer.cornerRadius = 5
            contentImage2.layer.cornerRadius = 5
            
        }
       
    }
    
    func writeCreatedAt(){
     let timestamp = passedTimestamp
        let dt = timestamp.dateValue()

        let dt2 = Date()
               
        let cal = Calendar(identifier: .gregorian)
        let diff = cal.dateComponents([.day,.hour,.minute,.second], from: dt, to: dt2)
               
        let day = diff.day
        let hour = diff.hour
        let minute = diff.minute
        let second = diff.second
               
        if minute == 0 {
            createdTimeLabel.text = "\(second?.description ?? "")秒前"
        }else if hour == 0 && minute != 0{
            createdTimeLabel.text = "\(minute?.description ?? "")分前"
        }else if day == 0 && hour != 0 {
            createdTimeLabel.text = "\(hour?.description ?? "")時間前"
        }else if day != 0 {
            createdTimeLabel.text = "\(day?.description ?? "")日前"
        }
    }
    
    
    
    @IBAction func toSearchVC(_ sender: Any) {
        let searchVC = storyboard?.instantiateViewController(withIdentifier: "SearchVC") as! SearchViewController
         navigationController?.pushViewController(searchVC, animated: false)
    }
    
    
    @IBAction func toNotificationVC(_ sender: Any) {
        let notificationVC = storyboard?.instantiateViewController(identifier: "notification") as! NotificationViewController
        navigationController?.pushViewController(notificationVC, animated: false)
        
    }
    
    
    @IBAction func toProfileVC(_ sender: Any) {
        let profileVC = storyboard?.instantiateViewController(withIdentifier: "myprofile") as! MyprofileViewController
        navigationController?.pushViewController(profileVC, animated: false)
    }
    
    
    
    
    
    
    
    
    
    
    func fetchProfile(){
        Firestore.firestore().collection("users").document(passedUid).collection("roomDetail").document(passedRoomName).getDocument { (snapShot, err) in
            guard let snapShot = snapShot,let dic = snapShot.data() else {return}
            let profile = Contents(dic: dic)
            self.userImage.sd_setImage(with: URL(string: profile.userImage), completed: nil)
            
        }
    }
    
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func likeButton(_ sender: Any) {
        
        if likeButton.tintColor == .black {
            likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            likeButton.tintColor = .red
            
            var count = Int(countLabel.text!)!
            count += 1
            countLabel.text = count.description
            createLikeContents(sender: likeButton)
      
        }else{
           likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
           likeButton.tintColor = .black
           var count = Int(countLabel.text!)!
            count -= 1
            countLabel.text = count.description
            deleteLikeContents(sender:likeButton)
        }
    }
    
    
    
    func fetchImageContents(){
        self.contentsArray.removeAll()
        Firestore.firestore().collection("rooms").document(passedRoomName).collection("contents").getDocuments { (querySnapshot, err) in
            if let err = err {
                print("取得に失敗しました。\(err)")
                       
            }
            for document in querySnapshot!.documents {
                let dic = document.data()
                let content = Room.init(dic: dic)
                self.contentsArray.append(content)
            }
            print(self.passedIndex)
//            self.contentsArray.remove(at: self.passedIndex)
                
            
            
            self.postTableView.reloadData()
                   
        }
    }
    
    func createLikeContents(sender:UIButton){
        let uid = Auth.auth().currentUser!.uid
        let documentID = contentsArray[sender.tag].documentID
        
        
        let docData = ["media": contentsArray[sender.tag].mediaArray,"text":contentsArray[sender.tag].text,"profileImageUrl":contentsArray[sender.tag].userImage,"userName":contentsArray[sender.tag].userName] as [String:Any]
        
        
        Firestore.firestore().collection("users").document(uid).collection("room").document(passedRoomName).collection("likes").document(documentID).setData(docData) { (err) in
            if let err = err {
                print("保存に失敗しました\(err)")
                return
            }else{
                print("保存に成功しました")
            }
        }
        
    }
    
    func deleteLikeContents(sender:UIButton){
        let uid = Auth.auth().currentUser!.uid
        let documentID = contentsArray[sender.tag].documentID
        
        
        Firestore.firestore().collection("users").document(uid).collection("room").document(passedRoomName).collection("likes").document(documentID).delete(){ err in
            if let err = err {
                print("削除に失敗しました\(err)")
                return
            }else{
                print("削除に成功しました")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let imageContentsArray = contentsArray.filter{
            $0.mediaArray[0] != ""
        }
        return imageContentsArray.count
       }
       
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = postTableView.dequeueReusableCell(withIdentifier: "postTable", for: indexPath) as! PostTableViewCell
        let imageContentsArray = contentsArray.filter{
            $0.mediaArray[0] != ""
        }
        let userName = cell.postProfileName!
        let profileImage = cell.postProfileImage!
        profileImage.layer.cornerRadius = 18
        
        userName.text = imageContentsArray[indexPath.row].userName
        if imageContentsArray[indexPath.row].userImage != "" {
            profileImage.sd_setImage(with: URL(string: imageContentsArray[indexPath.row].userImage), completed: nil)
            cell.personImage.image = UIImage()
        }else{
            profileImage.image = UIImage()
            cell.personImage.image = UIImage(systemName: "person.fill")
        }
        
        
        
        
        
        let comment = cell.postCommentLabel!
        comment.text = contentsArray[indexPath.row].text
        
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
        
        if minute == 0 {
            createTime.text = "\(second?.description ?? "")秒前"
        }else if hour == 0 && minute != 0{
            createTime.text = "\(minute?.description ?? "")分前"
        }else if day == 0 && hour != 0 {
            createTime.text = "\(hour?.description ?? "")時間前"
        }else if day != 0 {
            createTime.text = "\(day?.description ?? "")日前"
        }
        
        cell.selectionStyle = .none
        
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
          cell.underHeight.constant = 227
        }
                    
        if self.contentsArray[indexPath.row].mediaArray.count == 1 {
                        
            singleView.isHidden = false
            postImage.isHidden = true
            postImage2.isHidden = true
                    
                    
            singleView.sd_setImage(with: URL(string: contentsArray[indexPath.row].mediaArray[0] ), completed: nil)
            cell.underView.addSubview(singleView)
            singleView.layer.cornerRadius = 5
        }else if self.contentsArray[indexPath.row].mediaArray.count == 2 {
       
            postImage.isHidden = false
            postImage2.isHidden = false
                    
                    
            postImage.sd_setImage(with: URL(string: contentsArray[indexPath.row].mediaArray[0] ), completed: nil)
            cell.underView.addSubview(postImage)
            postImage.layer.cornerRadius = 5
                    

                    
            postImage2.sd_setImage(with: URL(string: contentsArray[indexPath.row].mediaArray[1] ), completed: nil)
            cell.underView.addSubview(postImage2)
            postImage2.layer.cornerRadius = 5
        }
        
        
        cell.likeButton.addTarget(self, action: #selector(pushedLikeButton(_:)), for: .touchUpInside)
               cell.likeButton.tag = indexPath.row
               cell.likeCountLabel.tag = -1
        
        
        
        return cell
       }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let showImageVC = storyboard?.instantiateViewController(identifier: "showImage") as! ShowImageViewController
        showImageVC.passedMedia = contentsArray[indexPath.row].mediaArray
        showImageVC.passedUid = contentsArray[indexPath.row].uid
        showImageVC.passedText = contentsArray[indexPath.row].text
        showImageVC.passedUserImage = contentsArray[indexPath.row].userImage
        present(showImageVC, animated: true, completion: nil)
    }
    
   func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
          
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        postTableView.estimatedRowHeight = 375
        return UITableView.automaticDimension
    }
    
    
    
    @objc func pushedLikeButton(_ sender: UIButton){
        if sender.tintColor == .black {
            sender.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            sender.tintColor = .red
            
            
            if let countLabel = sender.superview?.viewWithTag(-1) as? UILabel {
                
                var count = Int(countLabel.text!)!
                count += 1
                countLabel.text = count.description
                createLikeContents(sender: sender)
                
            }
        }else{
           sender.setImage(UIImage(systemName: "heart"), for: .normal)
           sender.tintColor = .black
            if let countLabel = sender.superview?.viewWithTag(-1) as? UILabel {
            var count = Int(countLabel.text!)!
            count -= 1
            countLabel.text = count.description
            deleteLikeContents(sender:sender)
            
                
            }
        }
       
    }
    

   

}
