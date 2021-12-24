//
//  roomEditViewController.swift
//  postLike
//
//  Created by taichi on 2021/03/25.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import DKImagePickerController

final class RoomEditViewController: UIViewController {

    @IBOutlet private weak var roomImage: UIImageView!
    @IBOutlet private weak var roomTextField: UITextField!
    @IBOutlet private weak var introTextView: UITextView!
    @IBOutlet private weak var completeButton: UIButton!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var backView: UIView!
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var callAlubmButtonBackView: UIView!
    
    
    var passedRoomName = String()
    var passedRoomImage = String()
    var passedDocumentID = String()
    var updatedRoomImage = UIImage()
    var roomInfo:Room?
    
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
    
    
    
    
    
    private func fetchRoomIntro(){
        Firestore.fetchRoomInfo(roomID: passedDocumentID) { roomInfo in
            self.roomInfo = roomInfo
            self.introTextView.text = roomInfo?.roomIntro
            self.roomTextField.text = roomInfo?.roomName
            if roomInfo?.roomImage != "" {
                self.roomImage.sd_setImage(with: URL(string: roomInfo?.roomImage ?? ""), completed: nil)
            }
        }
    }
    
    

    
    
    
    @IBAction private func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

    

    
    
    @IBAction private func photoAlbumButton(_ sender: Any) {
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

    
    
    private func createUserStrage(){
        Storage.addRoomImageToStrage(roomImage: updatedRoomImage, self: self) { urlString in
            let dic = ["roomImage":urlString,"roomName":self.roomTextField.text ?? "","roomIntro":self.introTextView.text ?? ""] as [String:Any]
            let batch = Firestore.firestore().batch()
            Firestore.updateRoomInfo(dic: dic, roomID: self.passedDocumentID, batch: batch)
            batch.commit { err in
                if let err = err {
                    print("err:",err)
                    let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                        self.dismissIndicator()
                    }
                    self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                    return
                }else{
                    self.dismiss(animated: true) {
                        if urlString != "" {
                            Storage.deleteStrage(roomImageUrl: self.roomInfo?.roomImage ?? "")
                        }
                    }
                }
            }
        }

    }
    
    
    
    
    
    @IBAction private func completeButton(_ sender: Any) {
        startIndicator()
        if updatedRoomImage == UIImage() {
            let batch = Firestore.firestore().batch()
            let dic = ["roomImage":roomInfo?.roomImage ?? "","roomName":self.roomTextField.text ?? "","roomIntro":self.introTextView.text ?? ""] as [String:Any]
            Firestore.updateRoomInfo(dic: dic, roomID: passedDocumentID, batch: batch)
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
    
    

    
    
    
    
    @objc private func keybordWillShow(_ notification: Notification) {
    
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
    
    
    
    
    @objc private func keybordWillHide(_ notification: Notification) {
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
    
    
