//
//  ProfileModalViewController.swift
//  PostLike
//
//  Created by taichi on 2021/10/29.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import Firebase

class ProfileModalViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    
    
    
    private let element = [
        (type:"exit",text:["ルームを退出する","キャンセル"],image:["arrowshape.turn.up.right","xmark"]),
        (type:"delete",text:["投稿を削除する","キャンセル"],image:["trash","xmark"]),
        (type:"moderator",text:["ルームを退出する","ルームを削除する","キャンセル"],image:["arrowshape.turn.up.right","trash","xmark"])
    ]
    
    var passedType = String()
    var passedDocumentID = String()
    var passedRoomID = String()
    var passedImageUrl = [String]()
    weak var deletePostDelegate:DeletePostDelegate?
    weak var exitRoomDelegate:ExitRoomDelegate?
    var passedModerator = String()
    var passedViewController = UIViewController()
    private let uid = Auth.auth().currentUser!.uid
    
    
    
    @IBOutlet weak var menuTableView: UITableView!
    @IBOutlet weak var backViewHeightContraint: NSLayoutConstraint!
    @IBOutlet weak var clearView: UIView!
    @IBOutlet weak var backView: UIView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        menuTableView.delegate = self
        menuTableView.dataSource = self
        menuTableView.allowsSelection = true
        
        backView.layer.cornerRadius = 10
        if passedModerator == uid {
            backViewHeightContraint.constant = 220
        }
        clearView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tappedBackView)))
    }
    
    
    @objc func tappedBackView(_ sender:UITapGestureRecognizer){
        self.dismiss(animated: true, completion: nil)
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if passedModerator == uid {
            return 3
        }else{
            return 2
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = menuTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let imageView = cell.viewWithTag(1) as! UIImageView
        let label = cell.viewWithTag(2) as! UILabel
        
        switch passedType {
        case "exit":
            imageView.image = UIImage(systemName: element[0].image[indexPath.row])
            label.text = element[0].text[indexPath.row]
        case "delete":
            imageView.image = UIImage(systemName: element[1].image[indexPath.row])
            label.text = element[1].text[indexPath.row]
        case "moderator":
            imageView.image = UIImage(systemName: element[2].image[indexPath.row])
            label.text = element[2].text[indexPath.row]
        default:
            break
        }
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch passedType {
        case "exit":
            if indexPath.row == 0 {
                exitRoomDelegate?.exitRoomBatch()
                dismiss(animated: true, completion: nil)
            }else if indexPath.row == 1 {
                dismiss(animated: true, completion: nil)
            }
        case "delete":
            if indexPath.row == 0 {
                dismiss(animated: true) {
                    self.deletePostDelegate!.deletePostBatch(documentID: self.passedDocumentID, imageUrl: self.passedImageUrl)
                }
            }else if indexPath.row == 1 {
                dismiss(animated: true, completion: nil)
            }
        case "moderator":
            if indexPath.row == 0 {
                exitRoomDelegate?.exitRoomBatch()
                dismiss(animated: true, completion: nil)
            }else if indexPath.row == 1 {
                let deleteAlertVC = storyboard?.instantiateViewController(withIdentifier: "deleteAlert") as! DeleteRoomViewController
                deleteAlertVC.modalPresentationStyle = .custom
                deleteAlertVC.transitioningDelegate = passedViewController as? UIViewControllerTransitioningDelegate
                deleteAlertVC.passedRoomID = passedRoomID
                deleteAlertVC.deleteRoomDelegate = passedViewController as? DeleteRoomDelegate
                present(deleteAlertVC, animated: true, completion: nil)
            }else {
                dismiss(animated: true,completion: nil)
            }
        default:
            break
        }
    }
    
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
}


