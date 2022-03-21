//
//  CreateProfileModalViewController.swift
//  PostLike
//
//  Created by taichi on 2021/10/24.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import DKImagePickerController
import RxSwift
import FirebaseFirestore
import Firebase

final class CreateProfileModalViewController: UIViewController {
    
    
    @IBOutlet private weak var backViewOfProfileImage: UIView!
    @IBOutlet private weak var userNameTextField: UITextField!
    @IBOutlet private weak var doneButton: UIButton!
    @IBOutlet private weak var callAlubmButton: UIButton!
    @IBOutlet private weak var profileImageView: UIImageView!
    @IBOutlet private weak var backView: UIView!
    @IBOutlet private weak var clearView: UIView!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    var passedUserInfo = Contents(dic: [:])
    var passedRoomInfo = Room(dic: [:])
    private var viewModel: CreateProfileViewModel!
    private let disposeBag = DisposeBag()
    
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        profileImageView.layer.cornerRadius = 60
        profileImageView.setImage(imageUrl: passedUserInfo.userImage)
        
        callAlubmButton.layer.cornerRadius = 20
        callAlubmButton.layer.borderWidth = 5
        callAlubmButton.layer.borderColor = UIColor.white.cgColor
        
        doneButton.layer.cornerRadius = 23
        doneButton.isEnabled = false
        
        userNameTextField.delegate = self
        userNameTextField.text = passedUserInfo.userName
        
        backView.layer.cornerRadius = 10
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        
        
        clearView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.viewDidTouch)))
        
        
        setupBinds()
    }
    
    
    
    
    private func setupBinds() {
        viewModel = CreateProfileViewModel(input: (createButtonTap: doneButton.rx.tap.asSignal(), userName: userNameTextField.rx.text.orEmpty.asDriver()), roomInfo: passedRoomInfo, createProfile: CreateProfile())
        viewModel.userImageSubject.onNext(profileImageView.image ?? UIImage())
        viewModel.isValidTap
            .drive { [weak self] bool in
                self?.doneButton.backgroundColor = bool ? .red : .systemGray5
                self?.doneButton.isEnabled = bool
            }
            .disposed(by: disposeBag)
        //完了通知を受け取る
        viewModel.isCompleted
            .drive { [weak self] bool in
                if bool == true {
                    self?.dismiss(animated: true, completion: nil)
                }
            }
            .disposed(by: disposeBag)
        //エラー通知を受け取る
        viewModel.errorDriver
            .drive { [weak self] err in
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self?.dismissIndicator()
                }
                self?.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
            }
        
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
                asset.fetchFullScreenImage(completeBlock: { [weak self] (image, info) in
                    self?.profileImageView.image = image
                    self?.viewModel.userImageSubject.onNext(image ?? UIImage())
                })
            }
        }
        imagePickerController.modalPresentationStyle = .fullScreen
        imagePickerController.UIDelegate = CustomUIDelegate()
        self.present(imagePickerController, animated: true, completion: nil)
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
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backView.endEditing(true)
    }
    
    
    
}
