//
//  EditProfileViewController.swift
//  postLike
//
//  Created by taichi on 2021/02/03.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import DKImagePickerController
import Firebase

class EditProfileViewController: UIViewController {
    
    
    @IBOutlet weak var personView: UIImageView!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userNameEditLabel: UITextField!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var completeButton: UIButton!
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    
    var updatedRoomImage = UIImage()
    var updatedUserImage = UIImage()
    var roomDetailInfo:Contents?
    var passedRoomName = String()
    var passedDocumentID = String()
    var passedUserName = String()
    var passedUserImage = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        userImage.layer.cornerRadius = 50
        
        completeButton.layer.cornerRadius = 23
        
        
        setProfile()
        
        userNameEditLabel.delegate = self
        userNameEditLabel.layer.cornerRadius = 5
        userNameEditLabel.layer.borderWidth = 1
        userNameEditLabel.layer.borderColor = UIColor.systemGray5.cgColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    
    
    func setProfile(){
        if passedUserImage != "" {
            userImage.sd_setImage(with: URL(string: passedUserImage), completed: nil)
            personView.image = UIImage()
        }
        userNameEditLabel.text = passedUserName
        
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        userNameEditLabel.resignFirstResponder()
    }
    
    
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func changeProfileImage(_ sender: Any) {
        let pickerController = DKImagePickerController()
        pickerController.maxSelectableCount = 1
        pickerController.sourceType = .photo
        pickerController.assetType = .allPhotos
        pickerController.allowSelectAll = true
        pickerController.showsCancelButton = true
        pickerController.didSelectAssets = {(assets: [DKAsset]) in
            for asset in assets {
                asset.fetchFullScreenImage(completeBlock: { (image, info) in
                    self.userImage.image = image
                    self.personView.image = UIImage()
                    self.updatedUserImage = image!
                })
            }
        }
        pickerController.modalPresentationStyle = .fullScreen
        pickerController.UIDelegate = CustomUIDelegate()
        self.present(pickerController, animated: true, completion: nil)
    }
    
    
    @IBAction func changeButton(_ sender: Any) {
        startIndicator()
        if updatedUserImage == UIImage() {
            updateProfile(userImageUrl: passedUserImage)
            
        }else{
            createUserStrage()
            
        }
    }
    
    
    
    
    
    func deleteStrage(){
        let storage = Storage.storage()
        let imageRef = NSString(string: passedUserImage)
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
    
    
    
    
    
    
    func updateProfile(userImageUrl:String){
        let docData = ["userName":userNameEditLabel.text!,"userImage":userImageUrl]
        let uid = Auth.auth().currentUser!.uid
        
        Firestore.firestore().collection("users").document(uid).collection("rooms").document(self.passedDocumentID).setData(docData, merge: true){(err) in
            
            if let err = err {
                print("firestoreへの保存に失敗しました。\(err)")
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }
            print("firestoreへの保存に成功しました。")
            self.dismiss(animated: true) {
                if self.passedUserImage != "" {
                    self.deleteStrage()
                }
            }
        }
    }
    
    
    
    func createUserStrage(){
        let fileName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_images").child(fileName)
        guard let updateImage = updatedUserImage.jpegData(compressionQuality: 0.1) else {return}
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
                    self.updateProfile(userImageUrl: urlString)
                }
            }
        }
    }
    
    
    
    
    
    
    
    
}



extension EditProfileViewController:UITextFieldDelegate{
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if userNameEditLabel.text?.isEmpty == true {
            completeButton.isEnabled = false
            completeButton.backgroundColor = .lightGray
        }else{
            completeButton.isEnabled = true
            completeButton.backgroundColor = .systemRed
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        
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
        
        
        if self.backView.frame.height - self.stackView.frame.origin.y - self.stackView.frame.height - rect.height < 30 {
            
            UIView.animate(withDuration: duration) {
                self.backView.frame.origin.y = -10
            }
        }
        
        
        
    }
    
    @objc func keybordWillHide(_ notification: Notification) {
        
    }
    
    
    
    
    
}

