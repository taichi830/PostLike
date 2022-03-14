//
//  EditProfileViewController.swift
//  postLike
//
//  Created by taichi on 2021/02/03.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import DKImagePickerController
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth


final class ProfileEditViewController: UIViewController {
    
    
    @IBOutlet private weak var userImageView: UIImageView!
    @IBOutlet private weak var userNameEditLabel: UITextField!
    @IBOutlet private weak var topLabel: UILabel!
    @IBOutlet private weak var completeButton: UIButton!
    
    @IBOutlet private weak var backView: UIView!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    
    
    private var updatedUserImage = UIImage()
    var passedUserInfo = Contents(dic: [:])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        userImageView.layer.cornerRadius = 50
        completeButton.layer.cornerRadius = 23
        
        setProfile()
        
        userNameEditLabel.delegate = self
        userNameEditLabel.layer.cornerRadius = 5
        userNameEditLabel.layer.borderWidth = 1
        userNameEditLabel.layer.borderColor = UIColor.systemGray5.cgColor
        
    }
    
    
    
    private func setProfile(){
        userImageView.setImage(imageUrl: passedUserInfo.userImage)
        userNameEditLabel.text = passedUserInfo.userName
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        userNameEditLabel.resignFirstResponder()
    }
    
    
    @IBAction private func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction private func changeProfileImage(_ sender: Any) {
        let pickerController = DKImagePickerController()
        pickerController.maxSelectableCount = 1
        pickerController.sourceType = .photo
        pickerController.assetType = .allPhotos
        pickerController.allowSelectAll = true
        pickerController.showsCancelButton = true
        pickerController.didSelectAssets = {(assets: [DKAsset]) in
            for asset in assets {
                asset.fetchFullScreenImage(completeBlock: { (image, info) in
                    self.userImageView.image = image
                    self.updatedUserImage = image!
                })
            }
        }
        pickerController.modalPresentationStyle = .fullScreen
        pickerController.UIDelegate = CustomUIDelegate()
        self.present(pickerController, animated: true, completion: nil)
    }
    
    
    
    @IBAction private func changeButton(_ sender: Any) {
        startIndicator()
        if updatedUserImage == UIImage() {
            updateProfile(userImageUrl: self.passedUserInfo.userImage)
        }else{
            createUserStrage()
        }
    }
    
    
    
    private func updateProfile(userImageUrl:String){
        let dic = ["userName":userNameEditLabel.text!,"userImage":userImageUrl]
        Firestore.updateProfileInfo(dic: dic, roomID: passedUserInfo.documentID) { bool in
            if bool == false {
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }else{
                print("firestoreへの保存に成功しました。")
                self.dismiss(animated: true) {
                    if self.passedUserInfo.userImage != "" {
                        Storage.deleteStrage(roomImageUrl: self.passedUserInfo.userImage)
                    }
                }
            }
        }
    }
    
    
    
    private func createUserStrage(){
        Storage.addUserImageToStrage(userImage: self.updatedUserImage, self: self) { urlString in
            self.updateProfile(userImageUrl: urlString)
        }
    }
    
    
    
    
    
    
    
    
}



extension ProfileEditViewController:UITextFieldDelegate{
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if userNameEditLabel.text?.isEmpty == true {
            completeButton.isEnabled = false
            completeButton.backgroundColor = .lightGray
        }else{
            completeButton.isEnabled = true
            completeButton.backgroundColor = .systemRed
        }
    }
    
    
    
    
    
    
    
}

