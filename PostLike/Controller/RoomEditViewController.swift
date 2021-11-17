//
//  roomEditViewController.swift
//  postLike
//
//  Created by taichi on 2021/03/25.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import Firebase
import DKImagePickerController

class RoomEditViewController: UIViewController {

    @IBOutlet weak var roomImage: UIImageView!
    @IBOutlet weak var roomTextField: UITextField!
    @IBOutlet weak var introTextView: UITextView!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var callAlubmButtonBackView: UIView!
    
    
    var passedRoomName = String()
    var passedRoomImage = String()
    var passedDocumentID = String()
    var updatedRoomImage = UIImage()
    var roomIntro:Room?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        callAlubmButtonBackView.layer.cornerRadius = 5
        
        roomTextField.delegate = self
        roomTextField.layer.cornerRadius = 5
        roomTextField.layer.borderWidth = 1
        roomTextField.layer.borderColor = UIColor.systemGray5.cgColor
        
        introTextView.layer.cornerRadius = 5
        introTextView.layer.borderColor = UIColor.systemGray5.cgColor
        introTextView.layer.borderWidth = 1.3
        introTextView.delegate = self
        
        completeButton.layer.cornerRadius = 23
        
        
        
        fetchRoomIntro()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    
    
    
    func fetchRoomIntro(){
        Firestore.firestore().collection("rooms").document(passedDocumentID).getDocument { snapShot, err in
            if let err = err {
                print("false\(err)")
                return
            }else{
                guard let snap = snapShot,let dic = snap.data() else {return}
                let roomIntro = Room(dic: dic)
                self.roomIntro = roomIntro
                self.introTextView.text = roomIntro.roomIntro
                self.roomTextField.text = roomIntro.roomName
                if roomIntro.roomImage != "" {
                    self.roomImage.sd_setImage(with: URL(string: roomIntro.roomImage), completed: nil)
                }
            }
        }
    }
    
    

    
    
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

    

    
    
    @IBAction func photoAlbumButton(_ sender: Any) {
        let pickerController = DKImagePickerController()
        pickerController.maxSelectableCount = 1
        pickerController.sourceType = .photo
        pickerController.assetType = .allPhotos
        pickerController.allowSelectAll = true
        pickerController.showsCancelButton = true
        pickerController.didSelectAssets = {(assets: [DKAsset]) in
            for asset in assets {
                asset.fetchFullScreenImage(completeBlock: { (image, info) in
                    self.roomImage.image = image
                    self.updatedRoomImage = image!
                })
            }
        }
        pickerController.modalPresentationStyle = .fullScreen
        pickerController.UIDelegate = CustomUIDelegate()
        self.present(pickerController, animated: true, completion: nil)
    }
    
    
    
    
    
    func updateRoomInfo(roomImageUrl:String,batch:WriteBatch){
        let docData = ["roomImage":roomImageUrl,"roomName":roomTextField.text!,"roomIntro":introTextView.text ?? ""] as [String:Any]
        let ref = Firestore.firestore().collection("rooms").document(passedDocumentID)
        batch.updateData(docData, forDocument: ref)
    }
    
    
    
    
    
    
    func updateMyRoomInfo(roomImageUrl:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let docData = ["roomImage":roomImageUrl,"roomName":roomTextField.text!,"roomIntro":introTextView.text ?? ""] as [String:Any]
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID)
        batch.updateData(docData, forDocument: ref)
    }
    
    
    
    
    
    func deleteStrage(){
        let storage = Storage.storage()
        let imageRef = NSString(string: roomIntro!.roomImage)
        let desertRef = storage.reference(forURL: imageRef as String)
        desertRef.delete { err in
            if err != nil {
                print("false")
                return
            }else{
                print("success")
            }
        }
    }
    
    
    
    
    
    
    func createUserStrage(){
        let fileName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("room_images").child(fileName)
        
        guard let updateImage = updatedRoomImage.jpegData(compressionQuality: 0.4) else {return}
        storageRef.putData(updateImage, metadata: nil) { (metadata, error) in
            if let error = error{
                print("Firestorageへの保存に失敗しました。\(error)")
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }else{
                print("Firestorageへの保存に成功しました。")
                storageRef.downloadURL { (url, error) in
                    if let error = error {
                        print("firestorageからのダウンロードに失敗しました。\(error)")
                        let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                            self.dismissIndicator()
                        }
                        self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                        return
                    }
                    guard let urlString = url?.absoluteString else{return}
                    let batch = Firestore.firestore().batch()
                    self.updateRoomInfo(roomImageUrl: urlString, batch: batch)
                    self.updateMyRoomInfo(roomImageUrl: urlString, batch: batch)
                    batch.commit { err in
                        if err != nil{
                            let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                                self.dismissIndicator()
                            }
                            self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                        }else{
                            self.dismiss(animated: true) {
                                if self.roomIntro!.roomImage != "" {
                                    self.deleteStrage()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    
    
    
    @IBAction func completeButton(_ sender: Any) {
        startIndicator()
        if updatedRoomImage == UIImage() {
            let batch = Firestore.firestore().batch()
            updateRoomInfo(roomImageUrl: roomIntro!.roomImage, batch: batch)
            updateMyRoomInfo(roomImageUrl: roomIntro!.roomImage, batch: batch)
            batch.commit { err in
                if err != nil{
                    let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                        self.dismissIndicator()
                    }
                    self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                }else{
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }else{
            createUserStrage()
        }
        
        
    }

}






extension RoomEditViewController:UITextFieldDelegate,UITextViewDelegate {
    
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
           if roomTextField.text?.isEmpty == true {
               completeButton.isEnabled = false
               completeButton.backgroundColor = .lightGray
           }else{
               completeButton.isEnabled = true
               completeButton.backgroundColor = .systemRed
           }
       }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        roomTextField.resignFirstResponder()
        introTextView.resignFirstResponder()
       }
    
    

    
    
    
    
    @objc func keybordWillShow(_ notification: Notification) {
    
        guard let userInfo = notification.userInfo as? [String:Any] else {
            return
        }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        guard let rect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
           return
         }
        
        let distance =  rect.origin.y - (topView.frame.origin.y + topView.frame.height + stackView.frame.origin.y + stackView.frame.height)
        
        if distance <= 0 {
            UIView.animate(withDuration: duration) {
                self.backView.frame.origin.y = 42 + distance
                
            }
        }
        
    }
    
    
    
    
    @objc func keybordWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String:Any] else {
            return
        }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        UIView.animate(withDuration: duration) {
            self.backView.frame.origin.y = self.topView.frame.origin.y + self.topView.frame.height
        }
    }
    
}
    
    
