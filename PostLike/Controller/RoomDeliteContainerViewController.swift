//
//  RoomDeliteContainerViewController.swift
//  postLike
//
//  Created by taichi on 2021/06/09.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

class RoomDeliteContainerViewController: UIViewController {

    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer.cornerRadius = 5

        checkButton.layer.borderWidth = 0.8
        checkButton.layer.borderColor = UIColor.systemGray5.cgColor
        
    }
    
    @IBAction func addCheck(_ sender: Any) {
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
    
    
    @IBAction func deleteRoom(_ sender: Any) {
        let parentVC = self.parent as! ProfileViewController
        parentVC.deleteRoomAtContainerView()
    }
    
    
    
    @IBAction func cancelButton(_ sender: Any) {
        let parentVC = self.parent as! ProfileViewController
        parentVC.callAtDeleteContainerView()
    }
    
    

}
