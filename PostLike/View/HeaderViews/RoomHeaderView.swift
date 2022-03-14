//
//  RoomHeaderView.swift
//  PostLike
//
//  Created by taichi on 2021/11/11.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class RoomHeaderView: UIView {
    
    @IBOutlet private weak var bluredImageView: UIImageView!
    @IBOutlet private weak var roomNameLabel: UILabel!
    @IBOutlet private weak var memberLabel: UILabel!
    @IBOutlet private weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.cornerRadius = profileImageView.frame.height/2
        }
    }
    @IBOutlet private weak var imageCollectionButton: UIButton!
    @IBOutlet private weak var postButton: UIButton!
    
    private let disposeBag = DisposeBag()
    private var viewModel: RoomHeaderViewModel!
    var roomInfo: Room?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }

    private func loadNib() {
        if let view = UINib(nibName: "RoomHeaderView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView{
            view.frame = self.bounds
            self.addSubview(view)
        }
    }
    
    func setupBind(roomID: String, roomImageView: UIImageView, topRoomNameLabel: UILabel, vc: UIViewController) {
        viewModel = RoomHeaderViewModel(userListner: UserDefaultLisner(), roomInfoListner: RoomInfoDefaultListner(), roomID: roomID)
        didTapCollectionButton(roomID: roomID, vc: vc)
        
        //ユーザー情報をバインド
        viewModel.userInfo
            .drive { [weak self] userInfo in
                self?.didTapProfileImage(roomID: roomID, userInfo: userInfo, vc: vc)
                self?.didTapPostButton(userInfo: userInfo, vc: vc)
                self?.profileImageView.setImage(imageUrl: userInfo.userImage)
            }
            .disposed(by: disposeBag)
        
        //ルームに参加しているかをチェック
        viewModel.isJoined
            .drive { [weak self] bool in
                self?.postButton.isEnabled = bool
                self?.postButton.tintColor = bool ? .label : .lightGray
                self?.profileImageView.isUserInteractionEnabled = bool
                self?.memberLabel.text = bool ? "" : "このルームから退出しました"
            }
            .disposed(by: disposeBag)
        
        //ルーム情報をバインド
        viewModel.roomInfo
            .drive { [weak self] roomInfo in
                roomImageView.sd_setImage(with: URL(string: roomInfo.roomImage), completed: nil)
                
                self?.roomInfo = roomInfo
                
                self?.bluredImageView.sd_setImage(with: URL(string: roomInfo.roomImage), completed: nil)
                
                self?.roomNameLabel.text = roomInfo.roomName
                self?.roomNameLabel.adjustsFontSizeToFitWidth = true
                self?.roomNameLabel.minimumScaleFactor = 0.8
                
                topRoomNameLabel.text = roomInfo.roomName
                topRoomNameLabel.adjustsFontSizeToFitWidth = true
                topRoomNameLabel.minimumScaleFactor = 0.8
            }
            .disposed(by: disposeBag)
        
        //メンバーカウントをバインド
        viewModel.memberCount
            .drive { [weak self] memberCount in
                self?.memberLabel.text = "メンバー \(String(describing: memberCount.numberOfMember))人"
            }
            .disposed(by: disposeBag)
    }
    
    
    //コレクションボタンをタップ
    private func didTapCollectionButton(roomID: String, vc: UIViewController) {
        imageCollectionButton.rx.tap
            .subscribe { [weak self] _ in
                let storyboard = UIStoryboard(name: "Home", bundle: nil)
                let imageVC = storyboard.instantiateViewController(withIdentifier: "images") as! RoomImageContentsViewController
                imageVC.passedRoomID = roomID
                imageVC.passedRoomName = self?.roomNameLabel.text ?? ""
                vc.navigationController?.pushViewController(imageVC, animated: true)
            }
            .disposed(by: disposeBag)
        
    }
    
    //投稿ボタンをタップ
    private func didTapPostButton(userInfo: Contents, vc: UIViewController) {
        postButton.rx.tap
            .subscribe { [weak self] _ in
                let storyboard = UIStoryboard(name: "Home", bundle: nil)
                let postVC = storyboard.instantiateViewController(withIdentifier: "postVC") as! PostViewController
                postVC.passedRoomTitle = self?.roomNameLabel.text ?? ""
                postVC.passedDocumentID = userInfo.documentID
                postVC.passedHostUid = userInfo.moderator
                postVC.passedUserImageUrl = userInfo.userImage
                postVC.passedUserName = userInfo.userName
                vc.present(postVC, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
        
    }
    
    //プロフィールボタンをタップ
    private func didTapProfileImage(roomID: String, userInfo: Contents, vc: UIViewController) {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.rx.event.subscribe { _ in
            let storyboard = UIStoryboard(name: "Profile", bundle: nil)
            let myproVC = storyboard.instantiateViewController(withIdentifier: "myproVC") as! ProfileViewController
            myproVC.passedDocumentID = roomID
            myproVC.passedModerator = userInfo.moderator
            vc.navigationController?.pushViewController(myproVC, animated: true)
        }
        .disposed(by: disposeBag)
        
        profileImageView.addGestureRecognizer(tapGesture)
    }


}
