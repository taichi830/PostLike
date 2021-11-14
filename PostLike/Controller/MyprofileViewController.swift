//
//  Myprofile2ViewController.swift
//  postLike
//
//  Created by taichi on 2020/11/04.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import Firebase


class MyprofileViewController: UIViewController{
    
    
    @IBOutlet weak var myRoomCollectionView: UICollectionView!
    
    
    
    var titleLabel3 = String()
    var profileRoomArray = [Contents]()
    var selectedImage2 = UIImage()
    var label = UILabel()
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        myRoomCollectionView.delegate = self
        myRoomCollectionView.dataSource = self
        collectionItenSize()
    }
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchProfileRoom()
        
    }
    
    
    @IBAction func menuButton(_ sender: Any) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "ログアウト", style: .default, handler: {_ in
            self.alertComfirm()
        }))
        actionSheet.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    
    
    
    func alertComfirm(){
        let alert = UIAlertController(title: "ログアウトしてよろしいでしょうか？", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "はい", style: .default, handler: { _ in
            self.logout()
        }))
        alert.addAction(UIAlertAction(title: "いいえ", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    
    func logout(){
        let auth = Auth.auth()
        do {
            try auth.signOut()
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let navigationVC = storyboard.instantiateViewController(identifier: "navigation") as! UINavigationController
            self.present(navigationVC, animated: false, completion: nil)
            print("success")
            
        } catch let sighOutErr as NSError {
            print ("Error signing out: %@", sighOutErr)
            return
        }
    }
    
    
    
    func fetchProfileRoom(){
        let uid = Auth.auth().currentUser!.uid
        profileRoomArray.removeAll()
        Firestore.firestore().collection("users").document(uid).collection("rooms").whereField("isJoined", isEqualTo: true).order(by: "createdAt",descending: true).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("情報の取得に失敗しました。\(err)")
                return
            }
            for document in querySnapshot!.documents{
                let dic = document.data()
                let profileRoom = Contents.init(dic: dic)
                self.profileRoomArray.append(profileRoom)
            }
            
            if self.profileRoomArray.isEmpty == true {
                self.label.frame = CGRect(x: 0, y: self.myRoomCollectionView.frame.height/2-15, width: self.view.frame.width, height: 30)
                self.label.text = "参加しているルームはありません"
                self.label.textAlignment = .center
                self.label.textColor = .lightGray
                self.label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
                self.myRoomCollectionView.addSubview(self.label)
            }else{
                self.label.text = ""
            }
            self.myRoomCollectionView.reloadData()
        }
    }
    
    
    
    
    
    
    
}






extension MyprofileViewController:UICollectionViewDelegate,UICollectionViewDataSource{
    
    func collectionItenSize(){
        //セルの大きさと間隔
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: ((self.view.frame.width) - 55)/2, height: 145)
        layout.minimumLineSpacing = 15
        layout.minimumInteritemSpacing = 15
        layout.sectionInset = UIEdgeInsets(top: 30, left: 20, bottom: 10, right: 20)
        myRoomCollectionView.collectionViewLayout = layout
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        profileRoomArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = myRoomCollectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.systemGray5.cgColor
        cell.layer.cornerRadius = 10
        
        
        let roomName = cell.viewWithTag(2) as! UILabel
        let roomImageView = cell.viewWithTag(5) as! UIImageView
        
//        userImage.clipsToBounds = true
//        userImage.layer.cornerRadius = userImage.frame.height/2
//        userImage.layer.borderWidth = 1
//        userImage.layer.borderColor = UIColor.systemGray5.cgColor
        
//        if profileRoomArray[indexPath.row].userImage == "" {
////            personImage.image = UIImage(systemName: "person.3.fill")
//            userImage.backgroundColor = .systemGray4
//            userImage.image = UIImage()
//        }else{
//            userImage.sd_setImage(with: URL(string: self.profileRoomArray[indexPath.row].userImage), completed: nil)
////            personImage.image = UIImage()
//        }
        
        let text:String = " \(profileRoomArray[indexPath.row].roomName)"
        let font:UIFont = .systemFont(ofSize: 17, weight: .semibold)
        let size = CGSize(width: 10, height: 10)
        
        let attachment = NSTextAttachment()
        let image = UIImage(named: "redCircle")
        attachment.image = image
        
        let y = (font.capHeight-size.height).rounded() / 2
        attachment.bounds.origin = CGPoint(x: 0, y: y)
        attachment.bounds.size = size
        
        let imageAttribute = NSAttributedString(attachment: attachment)
        let mutableString = NSMutableAttributedString(string: text)
        mutableString.insert(imageAttribute, at: 0)
        
        roomName.attributedText = mutableString
        roomName.adjustsFontSizeToFitWidth = true
        roomName.minimumScaleFactor = 0.7
        
        let uid = Auth.auth().currentUser!.uid
        if profileRoomArray[indexPath.row].moderator == uid{
            roomName.attributedText = mutableString
        }else{
            roomName.text = profileRoomArray[indexPath.row].roomName
        }
        
        
//        userName.text = profileRoomArray[indexPath.row].userName
//
        roomImageView.sd_setImage(with: URL(string: profileRoomArray[indexPath.row].roomImage), completed: nil)
        
//        backView.layer.cornerRadius = 5
//        backView.layer.borderWidth = 1
//        backView.layer.borderColor = UIColor.systemGray6.cgColor
        
        
        return cell
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let profileVC = storyboard?.instantiateViewController(identifier: "myproVC") as! ProfileViewController
        profileVC.passedDocumentID = profileRoomArray[indexPath.row].documentID
        profileVC.passedModerator = profileRoomArray[indexPath.row].moderator
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    
    
    
    
    
    
}
