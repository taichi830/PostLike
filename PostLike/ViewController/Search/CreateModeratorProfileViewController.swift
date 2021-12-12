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
    
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var personImage: UIImageView!
    @IBOutlet weak var backView: UIImageView!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var userNameTextField: UITextField!
    
    
    
    
    
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
                    self.personImage.image = UIImage()
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
    
    
    
    
    private func createRoomImageToStrage(_ completed: @escaping(_ url:String) -> Void){
        guard let profileImage = passedRoomImage.jpegData(compressionQuality: 0.4) else {return}
        let fileName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("room_images").child(fileName)
        
        storageRef.putData(profileImage, metadata: nil) { (metadata, err) in
            
            if let err = err{
                print("Firestorageへの保存に失敗しました。\(err)")
                return
            }else{
                print("Firestorageへの保存に成功しました。")
                storageRef.downloadURL { (url, err) in
                    if let err = err {
                        print("firestorageからのダウンロードに失敗しました。\(err)")
                        return
                    }
                    guard let urlString = url?.absoluteString else{return}
                    completed(urlString)
                }
            }
        }
    }
    
    
    
    
    private func createUserImageToStrage(_ completed: @escaping(_ url:String) -> Void){
        guard let profileImage = userImage.image!.jpegData(compressionQuality: 0.1) else {return}
        let fileName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_images").child(fileName)
        
        storageRef.putData(profileImage, metadata: nil) { (metadata, err) in
            
            if let err = err{
                print("Firestorageへの保存に失敗しました。\(err)")
                return
            }else{
                print("Firestorageへの保存に成功しました。")
                storageRef.downloadURL { (url, err) in
                    if let err = err {
                        print("firestorageからのダウンロードに失敗しました。\(err)")
                        return
                    }
                    guard let urlString = url?.absoluteString else{return}
                    completed(urlString)
                }
            }
        }
        
    }
    
    
    
    
    
    
    private func createRoomDetail(documentID:String,roomImageUrl:String,userImageUrl:String,batch:WriteBatch){
        
        let uid = Auth.auth().currentUser!.uid
        let timestamp = Timestamp()
        let docData = ["createdAt":timestamp,"userImage":userImageUrl,"documentID":documentID,"roomImage":roomImageUrl,"moderator":uid,"roomName":passedRoomName,"userName":userNameTextField.text!,"uid":uid,"isJoined":true] as [String:Any]
        let ref =  Firestore.firestore().collection("users").document(uid).collection("rooms").document(documentID)

        batch.setData(docData, forDocument: ref)
    }
    
    
    
    
    private func createRoom(documentID:String,roomImageUrl:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let createdAt = Timestamp()
        let docData = ["roomImage":roomImageUrl,"documentID":documentID,"moderator":uid,"roomIntro":passedRoomIntro,"roomName":passedRoomName,"createdAt":createdAt,"memberCount":1,"postCount":0] as [String:Any]
        let ref = Firestore.firestore().collection("rooms").document(documentID)
        batch.setData(docData, forDocument: ref)
    }
    
    

    private func createMemberCount(documentID:String,batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(documentID).collection("memberCount").document("count")
        batch.setData(["roomID":documentID,"memberCount": 1], forDocument: ref)
    }

    
    
    private func createPostCount(documentID:String,batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(documentID).collection("roomPostCount").document("count")
        batch.setData(["roomID":documentID,"postCount": 0], forDocument: ref)
    }
    
    
    private func createMemberList(documentID:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let docData = ["uid":uid]
        let ref = Firestore.firestore().collection("rooms").document(documentID).collection("members").document(uid)
        batch.setData(docData, forDocument: ref)
    }
    
    
    private func batchWhenNoImage(documentID:String){
        let batch = Firestore.firestore().batch()
        createRoom(documentID: documentID, roomImageUrl: "", batch: batch)
        createRoomDetail(documentID: documentID, roomImageUrl: "", userImageUrl: "", batch: batch)
        createMemberCount(documentID: documentID, batch: batch)
        createMemberList(documentID: documentID, batch: batch)
        createPostCount(documentID: documentID, batch: batch)
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
        createRoomImageToStrage { roomImageUrl in
            self.createRoomDetail(documentID: documentID, roomImageUrl: roomImageUrl, userImageUrl: "", batch: batch)
            self.createRoom(documentID: documentID, roomImageUrl: roomImageUrl, batch: batch)
            self.createMemberCount(documentID: documentID, batch: batch)
            self.createMemberList(documentID: documentID, batch: batch)
            self.createPostCount(documentID: documentID, batch: batch)
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
        createUserImageToStrage { userImageUrl in
            self.createRoomDetail(documentID: documentID, roomImageUrl: "", userImageUrl: userImageUrl, batch: batch)
            self.createRoom(documentID: documentID, roomImageUrl: "", batch: batch)
            self.createMemberCount(documentID: documentID, batch: batch)
            self.createMemberList(documentID: documentID, batch: batch)
            self.createPostCount(documentID: documentID, batch: batch)
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
        createRoomImageToStrage({ roomImageUrl in
            self.createUserImageToStrage({ userImageUrl in
                self.createRoomDetail(documentID: documentID, roomImageUrl: roomImageUrl, userImageUrl: userImageUrl, batch: batch)
                self.createRoom(documentID: documentID, roomImageUrl: roomImageUrl, batch: batch)
                self.createMemberCount(documentID: documentID, batch: batch)
                self.createMemberList(documentID: documentID, batch: batch)
                self.createPostCount(documentID: documentID, batch: batch)
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
            })
        })
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
