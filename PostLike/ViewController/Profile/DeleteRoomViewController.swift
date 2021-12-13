//
//  RoomDeliteContainerViewController.swift
//  postLike
//
//  Created by taichi on 2021/06/09.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore

final class DeleteRoomViewController: UIViewController {

    
    var passedRoomID = String()
    weak var deleteRoomDelegate:DeleteRoomDelegate?
    
    @IBOutlet private weak var checkButton: UIButton!
    @IBOutlet private weak var deleteButton: UIButton!
    @IBOutlet private weak var clearView: UIView!
    @IBOutlet private weak var alertLabel: UILabel!
    @IBOutlet private weak var backView: UIView!
    @IBOutlet private weak var lightRedView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer.cornerRadius = 5

        checkButton.layer.borderWidth = 0.8
        checkButton.layer.borderColor = UIColor.systemGray5.cgColor
        alertLabel.text = "・削除されたルームは検索結果に反映されなくなります。\n\n・参加しているユーザーは投稿できなくなります。ルームの活動を維持したい場合は”ルームを退出する”を選んでください。\n\n・ルームを復元させることはできません。"
        clearView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tappedBackView)))
        
        backView.layer.cornerRadius = 10
        lightRedView.layer.cornerRadius = 10
        
    }
    
    
    
    @objc private func tappedBackView(_ sender:UITapGestureRecognizer){
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    
    @IBAction private func addCheck(_ sender: Any) {
        if deleteButton.isEnabled == false{
            checkButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
            deleteButton.isEnabled = true
            deleteButton.setTitleColor(.black, for: .normal)
        }else{
            checkButton.setImage(UIImage(), for: .normal)
            deleteButton.isEnabled = false
            deleteButton.setTitleColor(.lightGray, for: .normal)
        }
        
    }
    
    
    
    
    
    
    
    @IBAction private func deleteRoom(_ sender: Any) {
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: {
            self.deleteRoomDelegate?.deleteRoomAtContainerView()
        })
    }
    
    
    
    @IBAction private func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    


    
    
    

}
