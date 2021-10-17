//
//  PagingMenuViewController.swift
//  postLike
//
//  Created by taichi on 2020/11/07.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import Firebase


class PagingMenuViewController: UIViewController{
   

  
    
    var passedTitle = String()
    var passedDocumentID = String()
    var passedModerator = String()
    
    var profileTableView:UITableView!
    var likeTableView:UITableView!
    var contentsArray = [Contents]()
    var userInfo:Contents?
    var likeContensArray = [Contents]()
    
    
    
    
    
    
    @IBOutlet weak var titleName: UILabel!
    @IBOutlet weak var profileLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var personImage: UIImageView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var deleteRoomButton: UIButton!
    @IBOutlet weak var profileEditButton: UIButton!
    @IBOutlet weak var roomEditButton: UIButton!
    @IBOutlet weak var profileEditButton2: UIButton!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var activeIndicator: UIActivityIndicatorView!
    
    
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        
        
        
        
        
        profileImage.layer.cornerRadius = 50
        profileImage.layer.borderColor = UIColor.lightGray.cgColor
        profileImage.layer.borderWidth = 0.5
        
        
        
        titleName.text = passedTitle
        
        
        
        
        createProfileTableView()
        setUpEditButton()
        
        
        
        
        
        profileTableView.estimatedRowHeight = 375
        profileTableView.rowHeight = UITableView.automaticDimension
        
        menuView.layer.cornerRadius = 10
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchUserInfo()
        fetchLikeContents()
        fetchPostContents()
        
        
        
        
        
    }
    
    
    @IBAction func homeButton(_ sender: Any) {
        let homeVC = storyboard?.instantiateViewController(identifier: "MypageVC") as! HomeViewController
        navigationController?.pushViewController(homeVC, animated: false)
    }
    
    @IBAction func toSearchButton(_ sender: Any) {
        let searchVC = storyboard?.instantiateViewController(withIdentifier: "SearchVC") as! SearchViewController
        navigationController?.pushViewController(searchVC, animated: false)
    }
    
    @IBAction func toNotificationVC(_ sender: Any) {
        let notificationVC = storyboard?.instantiateViewController(identifier: "notification") as! NotificationViewController
        navigationController?.pushViewController(notificationVC, animated: false)
    }
    
    
    
    
    
    
    
    func setUpEditButton(){
        let uid = Auth.auth().currentUser!.uid
        if passedModerator == uid {
            profileEditButton.layer.cornerRadius = 3
            roomEditButton.layer.cornerRadius = 3
            profileEditButton2.isHidden = true
            roomEditButton.isHidden = false
            profileEditButton.isHidden = false
            deleteRoomButton.setTitleColor(.black, for: .normal)
            deleteRoomButton.isEnabled = true
        }else{
            profileEditButton2.isHidden = false
            roomEditButton.isHidden = true
            profileEditButton.isHidden = true
            profileEditButton2.layer.cornerRadius = 3
            deleteRoomButton.setTitleColor(.lightGray, for: .normal)
            deleteRoomButton.isEnabled = false
        }
    }
    
    
    @IBAction func EditProfile(_ sender: Any) {
        let editVC = storyboard?.instantiateViewController(identifier: "editVC") as! EditProfileViewController
        editVC.passedRoomName = titleName.text!
        editVC.passedDocumentID = passedDocumentID
        editVC.passedUserImage = self.userInfo!.userImage
        editVC.passedUserName = self.userInfo!.userName
        present(editVC, animated: true, completion: nil)
    }
    
    
    @IBAction func editRoom(_ sender: Any) {
        let roomEditVC = storyboard?.instantiateViewController(identifier: "editRoom") as! RoomEditViewController
        roomEditVC.passedRoomName = titleName.text!
        roomEditVC.passedRoomImage = self.userInfo!.roomImage
        roomEditVC.passedDocumentID = passedDocumentID
        
        present(roomEditVC, animated: true, completion: nil)
    }
    
    
    @IBAction func menuButton(_ sender: Any) {
        
        blurView.isHidden = false
        menuView.isHidden = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        blurView.addGestureRecognizer(tapGesture)
        
        
    }
    
    @objc func tapped(_ sender:UITapGestureRecognizer){
        blurView.isHidden = true
        menuView.isHidden = true
    }
    
    
    @IBAction func exitRoom(_ sender: Any) {
        
    }
    
    @IBAction func deleteRoom(_ sender: Any) {
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        blurView.isHidden = true
        menuView.isHidden = true
    }
    
    
    
    
    
    
    
    
    
    func createProfileTableView(){
        profileTableView = UITableView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.height - topView.frame.height + 49))
        profileTableView.backgroundColor = .clear
        profileTableView.separatorStyle = .none
        profileTableView.delegate = self
        profileTableView.dataSource = self
        profileTableView.tableHeaderView = headerView
        self.backView.addSubview(profileTableView)
        profileTableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: "postTable")
    }
    
    @IBAction func editButton(_ sender: Any) {
        let editVC = storyboard?.instantiateViewController(identifier: "editVC") as! EditProfileViewController
        editVC.passedRoomName = titleName.text!
        editVC.passedDocumentID = passedDocumentID
        editVC.passedUserImage = self.userInfo!.userImage
        editVC.passedUserName = self.userInfo!.userName
        present(editVC, animated: true, completion: nil)
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        dismiss(animated: false, completion: nil)
    }
    
    
    
    
    
    
    func fetchPostContents(){
        let uid = Auth.auth().currentUser!.uid
        self.contentsArray.removeAll()

        Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).collection("posts").order(by: "createdAt", descending: true).getDocuments { (querySnapshot, err) in

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
                
                let label = UILabel(frame: CGRect(x: 87.5, y: 400, width: 200, height: 30))
                label.text = "投稿がまだありません"
                label.textAlignment = .center
                label.textColor = .lightGray
                label.font = UIFont.boldSystemFont(ofSize: 17)
                self.profileTableView.addSubview(label)
                
                let button = UIButton(frame: CGRect(x: 122, y: 440, width: 130, height: 20))
                button.setTitle("投稿する", for: .normal)
                button.setTitleColor(UIColor.systemRed, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
                self.profileTableView.addSubview(button)
                
            }
            
            self.profileTableView.reloadData()
            
            
        }
        
    }
    
    
    
    
    func fetchLikeContents(){
        let uid = Auth.auth().currentUser!.uid
        self.likeContensArray.removeAll()
        
        Firestore.firestore().collection("users").document(uid).collection("likes").document(titleName.text!).collection("likes").getDocuments { (querySnapshot, err) in
            if let err = err {
                print("取得に失敗しました。\(err)")
                return
            }
            for document in querySnapshot!.documents {
                let dic = document.data()
                let content = Contents.init(dic: dic)
                self.likeContensArray.append(content)
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
            
            self.profileLabel.text = self.userInfo?.userName
            if self.userInfo?.userImage == "" {
            }else{
                self.profileImage.sd_setImage(with: URL(string: self.userInfo!.userImage), completed: nil)
                self.personImage.image = UIImage()
            }
            self.profileTableView.reloadData()
        }
    }
    
    
}




extension PagingMenuViewController:UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return contentsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let cell = profileTableView.dequeueReusableCell(withIdentifier: "postTable")  as! PostTableViewCell
        cell.selectionStyle = .none
        
        let userName = cell.postProfileName!
        userName.text = userInfo?.userName
        
        let profileImage = cell.postProfileImage!
        profileImage.layer.cornerRadius = 18
        
        
        if self.userInfo?.userImage == "" {
            
        }else{
            profileImage.sd_setImage(with: URL(string: userInfo?.userImage ?? ""), completed: nil)
            cell.personImage.image = UIImage()
            
        }
        
        let comment = cell.postCommentLabel!
        comment.text = contentsArray[indexPath.row].text
        
        let postImage = cell.MyPostImage!
        let postImage2 = cell.myPostImage2!
        let underView = cell.underView!
        let singleView = cell.singlePostImage!
        
        if self.contentsArray[indexPath.row].mediaArray[0]  == "" {
            
            
            cell.underHeight.constant = 0
            
        }else {
            cell.underHeight.constant = 227
        }
        
        
        
        if self.contentsArray[indexPath.row].mediaArray.count == 1 {
            
            singleView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width-14, height: 227)
            singleView.sd_setImage(with: URL(string: contentsArray[indexPath.row].mediaArray[0]), completed: nil)
            underView.addSubview(singleView)
            singleView.layer.cornerRadius = 5
            
        }
        
        if self.contentsArray[indexPath.row].mediaArray.count == 2 {
            
            postImage.frame = CGRect(x: 0, y: 0, width: 177, height: 227)
            postImage.sd_setImage(with: URL(string: contentsArray[indexPath.row].mediaArray[0]), completed: nil)
            underView.addSubview(postImage)
            postImage.layer.cornerRadius = 5
            
            
            postImage2.frame = CGRect(x: 183, y: 0, width: 178, height: 227)
            postImage2.sd_setImage(with: URL(string: contentsArray[indexPath.row].mediaArray[1]), completed: nil)
            underView.addSubview(postImage2)
            postImage2.layer.cornerRadius = 5
            
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
        
        
        if minute == 0 {
            createTime.text = "\(second?.description ?? "")秒前"
        }else if hour == 0 && minute != 0{
            createTime.text = "\(minute?.description ?? "")分前"
        }else if day == 0 && hour != 0 {
            createTime.text = "\(hour?.description ?? "")時間前"
        }else if day != 0 {
            createTime.text = "\(day?.description ?? "")日前"
        }
        
        
        
        return cell
        
        
        
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        profileTableView.estimatedRowHeight = 375
        return UITableView.automaticDimension
    }
    
}

extension PagingMenuViewController:UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if profileTableView.contentOffset.y <= -40 {
            
            self.activeIndicator.startAnimating()
            profileTableView.frame.origin.y = 135
            
            DispatchQueue.global(qos: .default).async {
                // 非同期処理などを実行
                Thread.sleep(forTimeInterval: 2)
                
                
                
                
                // 非同期処理などが終了したらメインスレッドでアニメーション終了
                DispatchQueue.main.async {
                    // アニメーション終了
                    self.activeIndicator.stopAnimating()
                    self.profileTableView.frame.origin.y = 95
                }
            }
        }
    }
        
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if profileTableView.contentOffset.y <= -40 {
            
            self.fetchPostContents()
        }
    }
}







