//
//  CreateProfileModalViewController.swift
//  PostLike
//
//  Created by taichi on 2021/10/24.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import DKImagePickerController
import Firebase

class CreateProfileModalViewController: UIViewController {
    
    
    @IBOutlet weak var backViewOfProfileImage: UIView!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var callAlubmButton: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var personImageView: UIImageView!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var clearView: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    
    
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
    
    
    
    @IBAction func callAlubm(_ sender: Any) {
        let pickerController = DKImagePickerController()
        pickerController.maxSelectableCount = 1
        pickerController.sourceType = .photo
        pickerController.assetType = .allPhotos
        pickerController.allowSelectAll = true
        pickerController.showsCancelButton = true
        pickerController.didSelectAssets = {(assets: [DKAsset]) in
            for asset in assets {
                asset.fetchFullScreenImage(completeBlock: { (image, info) in
                    self.profileImageView.image = image
                    self.personImageView.image = UIImage()
                })
            }
        }
        pickerController.modalPresentationStyle = .fullScreen
        pickerController.UIDelegate = CustomUIDelegate()
        self.present(pickerController, animated: true, completion: nil)
    }
    
    
    
    
    
    @IBAction func done(_ sender: Any) {
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
    
    
    @objc func viewDidTouch(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    
    

}




extension CreateProfileModalViewController:UITextFieldDelegate{
    
    
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
        
        
        UIView.animate(withDuration: duration) {
            let y = self.backView.frame.origin.y
            self.backView.frame.origin.y = y - (rect.height-50)
            self.bottomConstraint.constant = rect.height - 50
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
            self.backView.frame.origin.y = 369
            self.bottomConstraint.constant = 0
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
