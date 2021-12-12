//
//  roomDetailTableViewController.swift
//  postLike
//
//  Created by taichi on 2020/11/25.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import DKImagePickerController

final class CreateRoomViewController: UIViewController {
    
    
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var roomImage: UIImageView!
    @IBOutlet weak var roomIntroTextView: UITextView!
    @IBOutlet weak var roomNameTextField: UITextField!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var introTextView: UITextView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var selectButtonBackView: UIView!
    
    var passedRoomName = String()
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectButtonBackView.layer.cornerRadius = 5
        
        roomNameTextField.delegate = self
        roomNameTextField.layer.cornerRadius = 5
        roomNameTextField.layer.borderWidth = 1
        roomNameTextField.layer.borderColor = UIColor.systemGray5.cgColor
        
        introTextView.layer.cornerRadius = 5
        introTextView.layer.borderColor = UIColor.systemGray5.cgColor
        introTextView.layer.borderWidth = 1
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        
        
        
        
    }
    
    
    
    @IBAction private func cancelButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    @IBAction private func toNextPage(_ sender: Any) {
        let createHostVC = storyboard?.instantiateViewController(withIdentifier: "createHostProfile") as! CreateModeratorProfileViewController
        createHostVC.passedRoomImage = roomImage.image ?? UIImage()
        createHostVC.passedRoomName = roomNameTextField.text ?? ""
        createHostVC.passedRoomIntro = roomIntroTextView.text ?? ""
        
        navigationController?.pushViewController(createHostVC, animated: true)
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
                    
                    self.roomImage.image = image
                })
            }
        }
        imagePickerController.modalPresentationStyle = .fullScreen
        imagePickerController.UIDelegate = CustomUIDelegate()
        self.present(imagePickerController, animated: true, completion: nil)
    }

}



extension CreateRoomViewController:UITextFieldDelegate{
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if roomNameTextField.text?.isEmpty == true {
            createButton.isEnabled = false
            createButton.setTitleColor(.lightGray, for: .normal)
        }else{
            createButton.isEnabled = true
            createButton.setTitleColor(.systemRed, for: .normal)
        }
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
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
        let distance =  rect.origin.y - 549
        if distance < 0 {
            UIView.animate(withDuration: duration) {
                self.backView.frame.origin.y = 86 + distance
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

