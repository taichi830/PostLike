//
//  roomImageContentsViewController.swift
//  postLike
//
//  Created by taichi on 2021/02/07.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore

final class RoomImageContentsViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource {
    
    
    @IBOutlet private weak var imageCollecionView: UICollectionView!
    @IBOutlet private weak var roomName: UILabel!
    
    
    var passedRoomID = String()
    var passedRoomName = String()
    private var imagesArray = [Contents]()
    private var lastDocument:QueryDocumentSnapshot?
    private let label = MessageLabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageCollecionView.delegate = self
        imageCollecionView.dataSource = self
        
        roomName.text = passedRoomName
        roomName.adjustsFontSizeToFitWidth = true
        roomName.minimumScaleFactor = 0.9
        
        collectionSize()
        fetchImages()
        self.setSwipeBackGesture()
    }
    
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    
    
    
    
    
    
    
    
    
    @IBAction private func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    private func fetchImages(){
        self.imagesArray.removeAll()
        Firestore.fetchImageContents(roomID: passedRoomID) { querySnapshot, contents in
            if contents.isEmpty == true {
                self.label.setup(text: "投稿がありません。", at: self.imageCollecionView)
            }else{
                self.imagesArray.append(contentsOf: contents)
                self.lastDocument = querySnapshot.documents.last
                self.imageCollecionView.reloadData()
            }
        }
    }
    
    
    
    
    
    private func fetchMoreImages(){
        guard let lastDocument = self.lastDocument else {return}
        Firestore.fetchMoreImageContents(roomID: passedRoomID, lastDocument: lastDocument) { querySnapshot, contents in
            self.imagesArray.append(contentsOf: contents)
            self.lastDocument = querySnapshot.documents.last
            self.imageCollecionView.reloadData()
        }
    }
    
    
    
    
    
    private func collectionSize(){
        let layout = UICollectionViewFlowLayout()
        let width:CGFloat = (view.frame.size.width - 2)/3
        let height:CGFloat = view.frame.size.width/3
        layout.itemSize = CGSize(width: width, height: height)
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        imageCollecionView.collectionViewLayout = layout
    }
    
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesArray.count
    }
    
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = imageCollecionView.dequeueReusableCell(withReuseIdentifier: "images", for: indexPath)
        
        let image = cell.viewWithTag(1) as! UIImageView
        image.sd_setImage(with: URL(string: imagesArray[indexPath.row].mediaArray[0]), completed: nil)
        
        let doubleSquareView = cell.viewWithTag(2) as! UIImageView
        if imagesArray[indexPath.row].mediaArray.count >= 2 {
            doubleSquareView.image = UIImage(systemName: "square.fill.on.square.fill")
        }else{
            doubleSquareView.image = UIImage()
        }
        
        return cell
    }
    
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let showImageVC = storyboard?.instantiateViewController(withIdentifier: "showImage") as! ShowImageViewController
        showImageVC.passedText = imagesArray[indexPath.row].text
        showImageVC.passedMedia = imagesArray[indexPath.row].mediaArray
        showImageVC.passedUid = imagesArray[indexPath.row].uid
        showImageVC.passedRoomID = imagesArray[indexPath.row].roomID
        showImageVC.passedDocumentID = imagesArray[indexPath.row].documentID
        showImageVC.passedUserName = imagesArray[indexPath.row].userName
        showImageVC.passedUserImage = imagesArray[indexPath.row].userImage
        present(showImageVC, animated: true, completion: nil)
    }
    
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row + 1 == self.imagesArray.count{
            fetchMoreImages()
        }
    }
    
    
    
    
    
    

   

}
