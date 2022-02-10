//
//  Myprofile2ViewController.swift
//  postLike
//
//  Created by taichi on 2020/11/04.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth


final class JoinedRoomViewController: UIViewController{
    
    
    @IBOutlet private weak var myRoomCollectionView: UICollectionView!
    
    
    
    private var joinedRoomsArray = [Contents]()
    private var label = MessageLabel()
    
    
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
    
    
    
    
    
    @IBAction private func menuButton(_ sender: Any) {
        let accountSettingVC = storyboard?.instantiateViewController(withIdentifier: "accountSettingVC") as! AccountSettingViewController
        accountSettingVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(accountSettingVC, animated: true)
    }
    

    
    
    
    
    private func fetchProfileRoom(){
        joinedRoomsArray.removeAll()
        Firestore.fetchJoinedRooms { contents in
            if contents.isEmpty == true {
                self.label.setup(text: "参加しているルームはありません。", at: self.myRoomCollectionView)
                self.myRoomCollectionView.reloadData()
//                self.label.setupLabel(view: self.view, y: self.view.center.y - 100)
//                self.label.text = "参加しているルームはありません"
//                self.myRoomCollectionView.addSubview(self.label)
            }else {
                self.label.text = ""
                self.joinedRoomsArray.append(contentsOf: contents)
                self.myRoomCollectionView.reloadData()
            }
        }
    }
    
    
    
    
    
    
    
}






extension JoinedRoomViewController:UICollectionViewDelegate,UICollectionViewDataSource{
    
    private func collectionItenSize(){
        //セルの大きさと間隔
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (self.view.frame.width - 55)/2, height: 150)
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 15
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 10, right: 20)
        myRoomCollectionView.collectionViewLayout = layout
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        joinedRoomsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = myRoomCollectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.systemGray5.cgColor
        cell.layer.cornerRadius = 10
        
        
        let roomName = cell.viewWithTag(2) as! UILabel
        let roomImageView = cell.viewWithTag(5) as! UIImageView
        
        let text:String = " \(joinedRoomsArray[indexPath.row].roomName)"
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
        if joinedRoomsArray[indexPath.row].moderator == uid{
            roomName.attributedText = mutableString
        }else{
            roomName.text = joinedRoomsArray[indexPath.row].roomName
        }
        
        

        roomImageView.sd_setImage(with: URL(string: joinedRoomsArray[indexPath.row].roomImage), completed: nil)
        
        
        return cell
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let profileVC = storyboard?.instantiateViewController(identifier: "myproVC") as! ProfileViewController
        profileVC.passedDocumentID = joinedRoomsArray[indexPath.row].documentID
        profileVC.passedModerator = joinedRoomsArray[indexPath.row].moderator
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    
    
    
    
    
    
}
