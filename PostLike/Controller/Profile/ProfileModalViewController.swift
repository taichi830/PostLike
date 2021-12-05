////
////  ProfileModalViewController.swift
////  PostLike
////
////  Created by taichi on 2021/10/29.
////  Copyright © 2021 taichi. All rights reserved.
////
//
//import UIKit
//import FirebaseFirestore
//import FirebaseAuth
//
//class ProfileModalViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
//    
//    enum ModalType:String {
//        case exit
//        case delete
//        case moderator
//    }
//    
//    var passedType = String()
//    var passedDocumentID = String()
//    var passedRoomID = String()
//    var passedImageUrl = [String]()
//    weak var deletePostDelegate:DeletePostDelegate?
//    weak var exitRoomDelegate:ExitRoomDelegate?
//    var passedModerator = String()
//    var passedViewController = UIViewController()
//    private let uid = Auth.auth().currentUser!.uid
//    
//    
//    
//    @IBOutlet weak var menuTableView: UITableView!
//    @IBOutlet weak var backViewHeightContraint: NSLayoutConstraint!
//    @IBOutlet weak var clearView: UIView!
//    @IBOutlet weak var backView: UIView!
//    
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        menuTableView.delegate = self
//        menuTableView.dataSource = self
//        menuTableView.allowsSelection = true
//        
//        backView.layer.cornerRadius = 10
//        if passedModerator == uid {
//            backViewHeightContraint.constant = 220
//        }
//        clearView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tappedBackView)))
//    }
//    
//    
//    @objc func tappedBackView(_ sender:UITapGestureRecognizer){
//        self.dismiss(animated: true, completion: nil)
//    }
//    
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if passedModerator == uid {
//            return 3
//        }else{
//            return 2
//        }
//        
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = menuTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
//        let imageView = cell.viewWithTag(1) as! UIImageView
//        let label = cell.viewWithTag(2) as! UILabel
//        
//        switch passedType {
//        case ModalType.exit.rawValue:
//            CommonModal.shared.items(type: .exit, label: label, imageView: imageView, row: indexPath.row)
//            
//        case ModalType.delete.rawValue:
//            CommonModal.shared.items(type: .delete, label: label, imageView: imageView, row: indexPath.row)
//            
//        case ModalType.moderator.rawValue:
//            CommonModal.shared.items(type: .moderator, label: label, imageView: imageView, row: indexPath.row)
//        default:
//            break
//        }
//        return cell
//    }
//    
//    
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        switch passedType {
//        case ModalType.exit.rawValue:
//            if indexPath.row == 0 {
//                exitRoomDelegate?.exitRoomBatch()
//                dismiss(animated: true, completion: nil)
//            }else if indexPath.row == 1 {
//                dismiss(animated: true, completion: nil)
//            }
//            
//        case ModalType.delete.rawValue:
//            if indexPath.row == 0 {
//                self.deletePostDelegate!.deletePostBatch(documentID: self.passedDocumentID, imageUrl: self.passedImageUrl)
//                dismiss(animated: true,completion: nil)
//            }else if indexPath.row == 1 {
//                dismiss(animated: true, completion: nil)
//            }
//            
//        case ModalType.moderator.rawValue:
//            if indexPath.row == 0 {
//                exitRoomDelegate?.exitRoomBatch()
//                dismiss(animated: true, completion: nil)
//            }else if indexPath.row == 1 {
//                let deleteAlertVC = storyboard?.instantiateViewController(withIdentifier: "deleteAlert") as! DeleteRoomViewController
//                deleteAlertVC.modalPresentationStyle = .custom
//                deleteAlertVC.transitioningDelegate = passedViewController as? UIViewControllerTransitioningDelegate
//                deleteAlertVC.passedRoomID = passedRoomID
//                deleteAlertVC.deleteRoomDelegate = passedViewController as? DeleteRoomDelegate
//                present(deleteAlertVC, animated: true, completion: nil)
//            }else {
//                dismiss(animated: true,completion: nil)
//            }
//        default:
//            break
//        }
//    }
//    
//    
//    
//    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 60
//    }
//    
//}
//
//
