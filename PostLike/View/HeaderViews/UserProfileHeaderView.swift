//
//  userProfileHeaderView.swift
//  PostLike
//
//  Created by taichi on 2021/08/04.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import RxSwift
import FirebaseAuth

final class UserProfileHeaderView: UIView{
    
    
    @IBOutlet weak var userImageView: UIImageView!{
        didSet {
            userImageView.layer.cornerRadius = userImageView.frame.height/2
            userImageView.layer.borderColor = UIColor.systemGray5.cgColor
            userImageView.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var roomEditButton: UIButton! {
        didSet {
            roomEditButton.layer.cornerRadius = 2
            roomEditButton.layer.borderColor = UIColor.systemGray5.cgColor
            roomEditButton.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var hostProfileEditButton: UIButton! {
        didSet {
            hostProfileEditButton.layer.cornerRadius = 2
            hostProfileEditButton.layer.borderColor = UIColor.systemGray5.cgColor
            hostProfileEditButton.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var profileEditButton: UIButton! {
        didSet {
            profileEditButton.layer.cornerRadius = 2
            profileEditButton.layer.borderColor = UIColor.systemGray5.cgColor
            profileEditButton.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var postCountLabel: UILabel!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var editButtonStackView: UIStackView!
    
    private var viewModel: ProfileHeaderViewModel!
    private let disposeBag = DisposeBag()
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
//        setupHeaderView()
    }

    private func loadNib() {
        if let view = UINib(nibName: "UserProfileHeaderView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView{
            view.frame = self.bounds
            self.addSubview(view)
        }
    }
    
    func setupHeaderView(roomID: String, passedUid: String, titleName: UILabel, vc: UIViewController){
        viewModel = ProfileHeaderViewModel(userListner: UserDefaultLisner(), roomID: roomID)
        
        viewModel.userInfo
            .drive { [weak self] userInfo in
                self?.didTapProfileButton(userInfo: userInfo, vc: vc)
                self?.didTapRoomEditButton(userInfo: userInfo, vc: vc)
                
                titleName.text = userInfo.roomName
                
                guard let uid = Auth.auth().currentUser?.uid else { return }
                self?.userNameLabel.text = userInfo.userName
                self?.userImageView.setImage(imageUrl: userInfo.userImage)
                
                if passedUid == uid {
                    self?.profileEditButton.isHidden = true
                }else {
                    self?.editButtonStackView.isHidden = true
                }
                
            }
            .disposed(by: disposeBag)
        
        
        viewModel.postCount
            .drive { [weak self] postCount in
                self?.postCountLabel.text = String(Int(postCount.postCount))
            }
            .disposed(by: disposeBag)
        
        viewModel.likeCount
            .drive { [weak self] likeCount in
                self?.likeCountLabel.text = String(Int(likeCount.likeCount))
            }
            .disposed(by: disposeBag)
    }
    
    
    
    private func didTapProfileButton(userInfo: Contents ,vc: UIViewController) {
        hostProfileEditButton.rx.tap
            .subscribe { _ in
                let storyboard = UIStoryboard(name: "Profile", bundle: nil)
                let editVC = storyboard.instantiateViewController(identifier: "editVC") as! ProfileEditViewController
                editVC.passedUserInfo = userInfo
                editVC.hidesBottomBarWhenPushed = true
                vc.present(editVC, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
        
        profileEditButton.rx.tap
            .subscribe { _ in
                let storyboard = UIStoryboard(name: "Profile", bundle: nil)
                let editVC = storyboard.instantiateViewController(identifier: "editVC") as! ProfileEditViewController
                editVC.passedUserInfo = userInfo
                editVC.hidesBottomBarWhenPushed = true
                vc.present(editVC, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
        
    }
    
    private func didTapRoomEditButton(userInfo: Contents ,vc: UIViewController) {
        roomEditButton.rx.tap
            .subscribe { _ in
                let storyboard = UIStoryboard(name: "Profile", bundle: nil)
                let roomEditVC = storyboard.instantiateViewController(identifier: "editRoom") as! RoomEditViewController
                roomEditVC.passedUserInfo = userInfo
                roomEditVC.hidesBottomBarWhenPushed = true
                vc.present(roomEditVC, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    
}
