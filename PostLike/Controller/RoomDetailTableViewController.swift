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
    @IBOutlet weak var personImage: UIImageView!
    @IBOutlet weak var plusButton: UIImageView!
    @IBOutlet weak var roomIntroTextView: UITextView!
    @IBOutlet weak var roomNameTextField: UITextField!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var introTextView: PlaceHolderTextView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var notesTextView: UITextView!
    
    var passedRoomName = String()
    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
    
        roomImage.layer.cornerRadius = self.roomImage.frame.height/2
//        roomImage.layer.borderWidth = 10
//        roomImage.layer.borderColor = UIColor.systemGray6.cgColor
        
        plusButton.layer.cornerRadius = plusButton.frame.height/2
        plusButton.layer.borderWidth = 5
        plusButton.layer.borderColor = UIColor.white.cgColor
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(callAlbum(_:)))
        plusButton.addGestureRecognizer(tapGesture)
        plusButton.isUserInteractionEnabled = true
        
        roomNameTextField.delegate = self
        roomNameTextField.layer.cornerRadius = 5
        roomNameTextField.layer.borderWidth = 1
        roomNameTextField.layer.borderColor = UIColor.systemGray5.cgColor
        
        introTextView.layer.cornerRadius = 5
        introTextView.layer.borderColor = UIColor.systemGray5.cgColor
        introTextView.layer.borderWidth = 1
        
        notesTextView.layer.cornerRadius = 5
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.borderColor = UIColor.systemGray5.cgColor
        notesTextView.text = " 以下のルールを破った場合、法的処置、ルームの削除、アカウントの停止や削除など然るべき対応をさせていただきます。\n\n 1. 法令、公序良俗又に反する行為\n 2. 犯罪行為、又は犯罪を助長する行為\n 3. 他人に自傷、自殺を推奨、促す行為\n 4. 児童ポルノ、性交、わいせつ等、その他性的コンテンツの作成\n 5. わいせつ行為、性行等を目的とする一切の行為\n 6. 麻薬、覚醒剤など禁止されている薬物に関するコンテンツの作成\n 7. 反社会勢力に関するコンテンツの作成\n 8. 提供者又は第三者に対する脅迫やヘイトスピーチ、その他誹謗中傷、名誉毀損、信用を傷つける行為\n 9. 人種、民族、性別、信条、社会的身分、心身等に関するあらゆる差別的行為\n 10. 虚偽の情報、他人の情報を利用してアカウント作成をする行為\n 11. 他のユーザーの個人情報を不当に収集して利用する行為\n 12. 提供者又は第三者の知的財産権を侵害する行為\n 13. 本サービスの運営に支障を来すあらゆる行為\n 14. その他、提供者が不適切と判断する行為"
        
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        

        
        
    }
    
    
    
    @IBAction func cancelButton(_ sender: Any) {
        navigationController?.popViewController(animated: false)
    }
    
    @IBAction func toNextPage(_ sender: Any) {
        let createHostVC = storyboard?.instantiateViewController(withIdentifier: "createHostProfile") as! CreateHostProfileViewController
        
            createHostVC.passedRoomImage = roomImage.image ?? UIImage()
            createHostVC.passedRoomName = roomNameTextField.text ?? ""
            createHostVC.passedRoomIntro = roomIntroTextView.text ?? ""
        
        navigationController?.pushViewController(createHostVC, animated: true)
       
    }
    
    
    
    
    @objc func callAlbum(_: UITapGestureRecognizer){
        
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
                self.personImage.image = UIImage()
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
        
        let distance =  rect.origin.y - 446
        
        
        
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

