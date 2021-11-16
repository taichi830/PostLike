//
//  roomDetailTableViewController.swift
//  postLike
//
//  Created by taichi on 2020/11/25.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import Firebase
import DKImagePickerController

class RoomDetailTableViewController: UIViewController {
    
    
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var roomImage: UIImageView!
    @IBOutlet weak var roomIntroTextView: UITextView!
    @IBOutlet weak var roomNameTextField: UITextField!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var introTextView: PlaceHolderTextView!
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
    
    
    
    @IBAction func cancelButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func toNextPage(_ sender: Any) {
        let createHostVC = storyboard?.instantiateViewController(withIdentifier: "createHostProfile") as! CreateHostProfileViewController
        
        createHostVC.passedRoomImage = roomImage.image ?? UIImage()
        createHostVC.passedRoomName = roomNameTextField.text ?? ""
        createHostVC.passedRoomIntro = roomIntroTextView.text ?? ""
        
        navigationController?.pushViewController(createHostVC, animated: true)
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
                    
                    self.roomImage.image = image
                })
            }
        }
        
        
        pickerController.modalPresentationStyle = .fullScreen
        pickerController.UIDelegate = CustomUIDelegate()
        self.present(pickerController, animated: true, completion: nil)
    }

}



extension RoomDetailTableViewController:UITextFieldDelegate{
    
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
        
        let distance =  rect.origin.y - 549
        
        
        
        if distance < 0 {
            UIView.animate(withDuration: duration) {
                self.backView.frame.origin.y = 86 + distance
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

