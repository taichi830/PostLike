//
//  headerView.swift
//  postLike
//
//  Created by taichi on 2021/06/17.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import RxSwift

final class SearchResultHeaderView: UIView {
    
    @IBOutlet weak var roomImage: UIImageView!
    @IBOutlet weak var joinButton: UIButton! {
        didSet {
            joinButton.clipsToBounds = true
            joinButton.layer.cornerRadius = 18
            joinButton.layer.borderWidth = 1
            joinButton.layer.borderColor = UIColor.systemGray5.cgColor
        }
    }
    @IBOutlet weak var roomName: UILabel!
    @IBOutlet weak var roomIntro: UILabel!
    @IBOutlet weak var numberCount: UILabel!
    private var viewModel: RoomHeaderViewModel!
    private let disposeBag = DisposeBag()
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
        if let view = UINib(nibName: "SearchResultHeaderView", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? UIView{
            view.frame = self.bounds
            self.addSubview(view)
        }
    }
    
    
    func setupBind(roomID: String, roomImageView: UIImageView, topRoomNameLabel: UILabel, vc: UIViewController, tableView: UITableView) {
        viewModel = RoomHeaderViewModel(userListner: UserDefaultLisner(), roomInfoListner: RoomInfoDefaultListner(), roomID: roomID)
        
        //ユーザー情報をバインド
        viewModel.userInfo
            .drive { [weak self] userInfo in
                self?.didTapJoinButton(userInfo: userInfo, roomID: roomID, vc: vc)
            }
            .disposed(by: disposeBag)
        
        //ルームに参加しているかをチェック
        viewModel.isJoined
            .drive { [weak self] bool in
                if bool == true {
                    self?.joinButton.setTitle("ルームへ", for: .normal)
                    self?.joinButton.backgroundColor = .systemBackground
                    self?.joinButton.setTitleColor(.label, for: .normal)
                }
                else {
                    self?.joinButton.setTitle("参加する", for: .normal)
                    self?.joinButton.backgroundColor = .red
                    self?.joinButton.setTitleColor(.white, for: .normal)
                }
            }
            .disposed(by: disposeBag)
        
        //ルーム情報をバインド
        viewModel.roomInfo
            .drive { [weak self] roomInfo in
                roomImageView.sd_setImage(with: URL(string: roomInfo.roomImage), completed: nil)
                
                self?.roomInfo = roomInfo
                
                self?.roomName.text = roomInfo.roomName
                self?.roomName.adjustsFontSizeToFitWidth = true
                self?.roomName.minimumScaleFactor = 0.8
                
                self?.roomIntro.text = roomInfo.roomIntro
                self?.setupHeaderView(tableView: tableView)
                
                self?.roomImage.sd_setImage(with: URL(string: roomInfo.roomImage), completed: nil)
                
                topRoomNameLabel.text = roomInfo.roomName
                topRoomNameLabel.adjustsFontSizeToFitWidth = true
                topRoomNameLabel.minimumScaleFactor = 0.8
                
            }
            .disposed(by: disposeBag)
        
        viewModel.isDeleted
            .drive { [weak self] bool in
                if bool == true {
                    self?.joinButton.isEnabled = false
                    self?.joinButton.backgroundColor = .systemBackground
                    self?.joinButton.setTitleColor(.lightGray, for: .normal)
                    self?.roomName.text = "このルームは削除されました"
                }
            }
            .disposed(by: disposeBag)
        
        //メンバーカウントをバインド
        viewModel.memberCount
            .drive { [weak self] memberCount in
                self?.numberCount.text = "メンバー \(String(describing: memberCount.numberOfMember))人"
            }
            .disposed(by: disposeBag)
        
    }
    
    
    
    
    
    
    private func setupHeaderView(tableView: UITableView){
        let size = self.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        self.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        tableView.tableHeaderView = self
    }
    
    
    
    
    
    
    private func didTapJoinButton(userInfo: Contents, roomID: String , vc: UIViewController) {
        joinButton.rx.tap
            .subscribe { _ in
                if userInfo.isJoined == false {
                    let storyboard = UIStoryboard(name: "Search", bundle: nil)
                    let modalVC = storyboard.instantiateViewController(withIdentifier: "modal") as! CreateProfileModalViewController
                    modalVC.passedUserInfo = userInfo
                    modalVC.modalPresentationStyle = .custom
                    modalVC.transitioningDelegate = vc as? UIViewControllerTransitioningDelegate
                    vc.present(modalVC, animated: true, completion: nil)
                    
                }else if userInfo.isJoined == true {
                    let storyboard = UIStoryboard(name: "Home", bundle: nil)
                    let enteredVC = storyboard.instantiateViewController(identifier: "enteredVC") as! EnteredRoomContentViewController
                    enteredVC.passedDocumentID = roomID
                    vc.navigationController?.pushViewController(enteredVC,animated: true)
                }
            }
            .disposed(by: disposeBag)
    }
    
    
    

   

}
