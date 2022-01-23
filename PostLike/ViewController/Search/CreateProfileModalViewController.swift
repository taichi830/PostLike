//
//  CreateProfileModalViewController.swift
//  PostLike
//
//  Created by taichi on 2021/10/24.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import DKImagePickerController
import FirebaseFirestore

final class CreateProfileModalViewController: UIViewController {
    
    
    @IBOutlet private weak var backViewOfProfileImage: UIView!
    @IBOutlet private weak var userNameTextField: UITextField!
    @IBOutlet private weak var doneButton: UIButton!
    @IBOutlet private weak var callAlubmButton: UIButton!
    @IBOutlet private weak var profileImageView: UIImageView!
    @IBOutlet private weak var personImageView: UIImageView!
    @IBOutlet private weak var backView: UIView!
    @IBOutlet private weak var clearView: UIView!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    
    
    
    weak var createProfileDelegate: CreateProfileDelegate?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        profileImageView.layer.cornerRadius = 60
        callAlubmButton.layer.cornerRadius = 20
        callAlubmButton.layer.borderWidth = 5
        callAlubmButton.layer.borderColor = UIColor.white.cgColor
        
        doneButton.layer.cornerRadius = 23
        doneButton.isEnabled = false
        
        userNameTextField.delegate = self
        
        backView.layer.cornerRadius = 10
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        
        
        clearView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.viewDidTouch)))
    }
    
    
    
    @IBAction private func callAlubm(_ sender: Any) {
        let imagePickerController = DKImagePickerController()
        imagePickerController.maxSelectableCount = 1
        imagePickerController.sourceType = .photo
        imagePickerController.assetType = .allPhotos
        imagePickerController.allowSelectAll = true
        imagePickerController.showsCancelButton = true
        imagePickerController.didSelectAssets = {(assets: [DKAsset]) in
            for asset in assets {
                asset.fetchFullScreenImage(completeBlock: { (image, info) in
                    self.profileImageView.image = image
                    self.personImageView.image = UIImage()
                })
            }
        }
        imagePickerController.modalPresentationStyle = .fullScreen
        imagePickerController.UIDelegate = CustomUIDelegate()
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    
    
    
    
    @IBAction private func done(_ sender: Any) {
        modalIndicator(view: self.view)
        if profileImageView.image == nil {
            createProfileDelegate?.joinRoomBatch({
                self.dismiss(animated: true, completion: nil)
            }, userName: userNameTextField.text!)
        }else{
            createProfileDelegate?.createStrageWithBatch({
                self.dismiss(animated: true, completion: nil)
            }, userName: userNameTextField.text!, profileImageView: profileImageView)
        }
    }
    
    
    @objc private func viewDidTouch(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    
    

}




extension CreateProfileModalViewController:UITextFieldDelegate{
    
    
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
        
        
        UIView.animate(withDuration: duration) {
            self.bottomConstraint.constant = rect.height - 50
            self.view.layoutIfNeeded()
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
            self.bottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    
    
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if userNameTextField.text?.isEmpty == true {
            doneButton.isEnabled = false
            doneButton.backgroundColor = .systemGray5
        }else{
            doneButton.isEnabled = true
            doneButton.backgroundColor = .systemRed
        }
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backView.endEditing(true)
    }
    
    
    
}
