//
//  CreateHostProfileViewController.swift
//  postLike
//
//  Created by taichi on 2021/03/26.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import DKImagePickerController




final class CreateModeratorProfileViewController: UIViewController {
    
    
    @IBOutlet private weak var userImage: UIImageView!
    @IBOutlet private weak var backView: UIImageView!
    @IBOutlet private weak var completeButton: UIButton!
    @IBOutlet private weak var userNameTextField: UITextField!
    
    
    
    
    
    var passedRoomImage = UIImage()
    var passedRoomName = String()
    var passedRoomIntro = String()

   
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userImage.layer.cornerRadius = 50
        
        backView.layer.cornerRadius = 20
        backView.layer.borderWidth = 5
        backView.layer.borderColor = UIColor.white.cgColor
        
        completeButton.layer.cornerRadius = 23
        
        userNameTextField.delegate = self
        userNameTextField.layer.borderColor = UIColor.systemGray5.cgColor
        
        self.setSwipeBackGesture()
    }

    
    
    
    
    @IBAction private func plusButton(_ sender: Any) {
        let imagePickerController = DKImagePickerController()
        imagePickerController.maxSelectableCount = 1
        imagePickerController.sourceType = .photo
        imagePickerController.assetType = .allPhotos
        imagePickerController.allowSelectAll = true
        imagePickerController.showsCancelButton = true
        imagePickerController.didSelectAssets = {(assets: [DKAsset]) in
            for asset in assets {
                asset.fetchFullScreenImage(completeBlock: { (image, info) in
                    self.userImage.image = image
                })
            }
        }
        imagePickerController.modalPresentationStyle = .fullScreen
        imagePickerController.UIDelegate = CustomUIDelegate()
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    
    
    @IBAction private func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    
    
    
    
    
    
    private func createRoomDetail(documentID:String,roomImageUrl:String,userImageUrl:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let dic = [
            "createdAt":Timestamp(),
            "userImage":userImageUrl,
            "documentID":documentID,
            "roomImage":roomImageUrl,
            "moderator":uid,
            "roomName":passedRoomName,
            "userName":userNameTextField.text ?? "",
            "uid":uid,
            "isJoined":true] as [String:Any]
        Firestore.createProfile(uid: uid, documentID: documentID, dic: dic, batch: batch)
    }
    
    
    
    
    private func createRoom(documentID:String,roomImageUrl:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let dic = [
            "roomImage":roomImageUrl,
            "documentID":documentID,
            "moderator":uid,
            "roomIntro":passedRoomIntro,
            "roomName":passedRoomName,
            "createdAt":Timestamp(),
            "memberCount":1,
            "postCount":0] as [String:Any]
        Firestore.createRoom(documentID: documentID, dic: dic, batch: batch)
    }
    
    
    
    private func batchWhenNoImage(documentID:String){
        let batch = Firestore.firestore().batch()
        createRoom(documentID: documentID, roomImageUrl: "", batch: batch)
        createRoomDetail(documentID: documentID, roomImageUrl: "", userImageUrl: "", batch: batch)
        Firestore.createMemberCount(documentID: documentID, batch: batch)
        Firestore.createPostCount(documentID: documentID, batch: batch)
        Firestore.createMemberList(documentID: documentID, batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                print("scucces")
                self.dismissIndicator()
                self.navigationController?.popToViewController(self.navigationController!.viewControllers[0], animated: false)
            }
        }
    }
    
    
    
    
    private func batchWhenOnlyRoomImage(documentID:String){
        let batch = Firestore.firestore().batch()
        Storage.addRoomImageToStrage(roomImage: passedRoomImage, self: self) { roomImageUrl in
            self.createRoomDetail(documentID: documentID, roomImageUrl: roomImageUrl, userImageUrl: "", batch: batch)
            self.createRoom(documentID: documentID, roomImageUrl: roomImageUrl, batch: batch)
            Firestore.createMemberCount(documentID: documentID, batch: batch)
            Firestore.createPostCount(documentID: documentID, batch: batch)
            Firestore.createMemberList(documentID: documentID, batch: batch)
            batch.commit { err in
                if let err = err {
                    print("false\(err)")
                    return
                }else{
                    print("scucces")
                    self.dismissIndicator()
                    self.navigationController?.popToViewController(self.navigationController!.viewControllers[0], animated: false)
                }
            }
        }
    }
    
    
    
    private func batchWhenOnlyUserImage(documentID:String){
        let batch = Firestore.firestore().batch()
        Storage.addUserImageToStrage(userImage: self.userImage.image ?? UIImage(), self: self) { userImageUrl in
            self.createRoomDetail(documentID: documentID, roomImageUrl: "", userImageUrl: userImageUrl, batch: batch)
            self.createRoom(documentID: documentID, roomImageUrl: "", batch: batch)
            Firestore.createMemberCount(documentID: documentID, batch: batch)
            Firestore.createPostCount(documentID: documentID, batch: batch)
            Firestore.createMemberList(documentID: documentID, batch: batch)
            batch.commit { err in
                if let err = err {
                    print("false\(err)")
                    return
                }else{
                    print("scucces")
                    self.dismissIndicator()
                    self.navigationController?.popToViewController(self.navigationController!.viewControllers[0], animated: false)
                }
            }
        }
    }
    
    
    
    
    private func batchWhenUserImageAndRoomImage(documentID:String){
        let batch = Firestore.firestore().batch()
        Storage.addRoomImageToStrage(roomImage: passedRoomImage, self: self) { roomImageUrl in
            Storage.addUserImageToStrage(userImage: self.userImage.image ?? UIImage(), self: self) { userImageUrl in
                self.createRoomDetail(documentID: documentID, roomImageUrl: roomImageUrl, userImageUrl: userImageUrl, batch: batch)
                self.createRoom(documentID: documentID, roomImageUrl: roomImageUrl, batch: batch)
                Firestore.createMemberCount(documentID: documentID, batch: batch)
                Firestore.createPostCount(documentID: documentID, batch: batch)
                Firestore.createMemberList(documentID: documentID, batch: batch)
                batch.commit { err in
                    if let err = err {
                        print("false\(err)")
                        return
                    }else{
                        print("scucces")
                        self.dismissIndicator()
                        self.navigationController?.popToViewController(self.navigationController!.viewControllers[0], animated: false)
                    }
                }
            }
        }
    }
       
    
    
    
    
    
    
    
    
    
    @IBAction private func completeButton(_ sender: Any) {
        let documentID = Firestore.firestore().collection("rooms").document().documentID
        startIndicator()
        if passedRoomImage == UIImage() && userImage.image == nil {
            batchWhenNoImage(documentID: documentID)
            
        }else if passedRoomImage != UIImage() && userImage.image == nil {
            batchWhenOnlyRoomImage(documentID: documentID)
            
        }else if passedRoomImage == UIImage() && userImage.image != nil {
            batchWhenOnlyUserImage(documentID: documentID)
            
        }else if passedRoomImage != UIImage() && userImage.image != nil{
            batchWhenUserImageAndRoomImage(documentID: documentID)
        }
    }
    
    
    
    
    
    
    
    
}


extension CreateModeratorProfileViewController:UITextFieldDelegate{
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if userNameTextField.text?.isEmpty == true {
            completeButton.isEnabled = false
            completeButton.backgroundColor = .systemGray4
        }else{
            completeButton.isEnabled = true
            completeButton.backgroundColor = .systemRed
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
