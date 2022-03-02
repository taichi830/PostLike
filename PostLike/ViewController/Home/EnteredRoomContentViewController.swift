//
//  enteredRoomContentViewController.swift
//  postLike
//
//  Created by taichi on 2020/12/23.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseFirestore
import FirebaseAuth

final class EnteredRoomContentViewController: UIViewController{
    
    
    
    @IBOutlet private weak var contentsTableView: UITableView!
    @IBOutlet private weak var backButtonBackButton: UIView! {
        didSet {
            backButtonBackButton.clipsToBounds = true
            backButtonBackButton.layer.cornerRadius = backButtonBackButton.frame.height/2
        }
    }
    @IBOutlet private weak var dotsButtonBackView: UIView! {
        didSet {
            dotsButtonBackView.clipsToBounds = true
            dotsButtonBackView.layer.cornerRadius = dotsButtonBackView.frame.height/2
        }
    }
    @IBOutlet private weak var headerView: RoomHeaderView!
    @IBOutlet private weak var headerViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var headerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var roomImageView: UIImageView!
    @IBOutlet private weak var topBlurEffect: UIVisualEffectView!
    @IBOutlet private weak var topRoomNameLabel: UILabel!
    @IBOutlet private weak var effectViewHeight: NSLayoutConstraint!
    
    
    var passedDocumentID = String()
    private var messageLabel = MessageLabel()
    private var roomInfo:Room?
    private var contentsArray = [Contents]()
    private var likeContentsArray = [Contents]()
    private var joinedRoom:Contents?
    private var lastDocument:QueryDocumentSnapshot?
    private var lastLikeDocument:QueryDocumentSnapshot?
    private lazy var indicator:UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.center = roomImageView.center
        indicator.style = .medium
        indicator.color = .white
        indicator.hidesWhenStopped = true
        roomImageView.addSubview(indicator)
        return indicator
    }()
    private let disposeBag = DisposeBag()
    var viewModel: FeedViewModel!
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = FeedViewModel(feedContentsListner: FeedContentsDefaultListner(), likeListner: LikeDefaultListner(), userListner: UserDefaultLisner(), reportListner: ReportDefaultListner(), roomID: passedDocumentID)
        headerView.setupBind(roomID: passedDocumentID, roomImageView: roomImageView, topRoomNameLabel: topRoomNameLabel, vc: self)
        self.setSwipeBackGesture()
        setupTableView()
        emptyCheck()
        tableViewDidScroll()
        
    }
    
    
    
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewWillLayoutSubviews()
        effectViewHeight.constant = self.view.safeAreaInsets.top + 46
    }
    
    
    
    
    
    
    
    
    private func setupTableView(){
        contentsTableView.delegate = self
        contentsTableView.dataSource = self
        contentsTableView.tableHeaderView =  headerView
        contentsTableView.register(UINib(nibName: "FeedTableViewCell", bundle: nil), forCellReuseIdentifier: "FeedTableViewCell")
        contentsTableView.contentInsetAdjustmentBehavior = .never
        let refleshControl = CustomRefreshControl()
        contentsTableView.refreshControl = refleshControl
        contentsTableView.refreshControl?.addTarget(self, action: #selector(updateContents), for: .valueChanged)
        
    }
    
    
    
    
    
    
    
    
    
    @objc private func updateContents(){
        indicator.startAnimating()
        self.contentsArray.removeAll()
        self.likeContentsArray.removeAll()
    }
    
    
    
    
    
    
    @IBAction private func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    
    @IBAction private func menuButton(_ sender: Any) {
        let modalMenuVC = storyboard?.instantiateViewController(withIdentifier: "modalMenu") as! ModalMenuViewController
        modalMenuVC.modalPresentationStyle = .custom
        modalMenuVC.transitioningDelegate = self
        modalMenuVC.passedModalType = .room
        modalMenuVC.passedViewController = self
        modalMenuVC.passedRoomInfo = headerView.roomInfo ?? Room(dic: [:])
        modalMenuVC.passedRoomImage = roomImageView.image ?? UIImage()
        present(modalMenuVC, animated: true, completion: nil)
    }
    
    
    
    
    private func emptyCheck() {
        viewModel.isEmpty
            .drive { [weak self] bool in
                if bool == true {
                    self?.messageLabel.setup(text: "投稿がありません", at: self!.contentsTableView)
                }else {
                    self?.messageLabel.text = ""
                    self?.fetchFeedContents()
                }
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    private func fetchFeedContents() {
        viewModel.items.drive { [weak self] contents in
            self?.contentsArray.removeAll()
            self?.contentsArray.append(contentsOf: contents)
            self?.contentsTableView.reloadData()
        }
        .disposed(by: disposeBag)
        
        viewModel.likes.drive { [weak self] likes in
            self?.likeContentsArray.removeAll()
            self?.likeContentsArray.append(contentsOf: likes)
            self?.contentsTableView.reloadData()
        }
        .disposed(by: disposeBag)

        
        
    }
    
    
    
    
    private func tableViewDidScroll() {
        contentsTableView.rx.didScroll
            .withLatestFrom(contentsTableView.rx.contentOffset)
            .map { [weak self] point in
                if point.y <= 0 {
                    self?.headerViewHeight.constant = -(point.y - 180)
                    self?.headerViewTopConstraint.constant = 0
                }else{
                    self?.headerViewHeight.constant = 180
                    self?.headerViewTopConstraint.constant = -point.y
                }
                //下にスクロールに合わせて徐々にblurをかける
                self?.topBlurEffect.alpha = -0.7 + (point.y - 50) / 50
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        
    }
    
    
    
    
    
}





extension EnteredRoomContentViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell") as! FeedTableViewCell
        cell.setupBinds(content: contentsArray[indexPath.row], roomID: passedDocumentID, vc: self, modalType: .post)
        cell.setContent(contents: contentsArray[indexPath.row], likeContensArray: likeContentsArray)
        return cell
    }
}





extension EnteredRoomContentViewController:TableViewCellDelegate {
    func pushedCommentButton(row: Int) {
        
    }
    
    func reportButton(row: Int) {
//        let modalMenuVC = storyboard!.instantiateViewController(withIdentifier: "modalMenu") as! ModalMenuViewController
//        modalMenuVC.modalPresentationStyle = .custom
//        modalMenuVC.transitioningDelegate = self
//        modalMenuVC.passedDocumentID = contentsArray[row].documentID
//        modalMenuVC.passedRoomID = contentsArray[row].roomID
//        modalMenuVC.passedUid = contentsArray[row].uid
//        modalMenuVC.passedViewController = self
//        modalMenuVC.passedType = "post"
//        present(modalMenuVC, animated: true, completion: nil)
    }
    
    func tappedPostImageView(row: Int) {
//        let showImageVC = storyboard?.instantiateViewController(identifier: "showImage") as! ShowImageViewController
//        showImageVC.passedMedia = contentsArray[row].mediaArray
//        showImageVC.passedUid = contentsArray[row].uid
//        showImageVC.passedText = contentsArray[row].text
//        showImageVC.passedRoomID = contentsArray[row].roomID
//        showImageVC.passedDocumentID = contentsArray[row].documentID
//        showImageVC.passedUserName = contentsArray[row].userName
//        showImageVC.passedUserImage = contentsArray[row].userImage
//        present(showImageVC, animated: true, completion: nil)
    }
    
    func pushLikeButton(row: Int, sender: UIButton, countLabel: UILabel) {
//        if sender.tintColor == UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)  {
//            sender.setImage(UIImage(systemName: "heart.fill"), for: .normal)
//            sender.tintColor = .red
//            likeBatch(row:row)
//            var count = Int(contentsArray[row].likeCount)
//            count += 1
//            countLabel.text = count.description
//            contentsArray[row].likeCount = count
//
//        }else if sender.tintColor == .red {
//            sender.setImage(UIImage(systemName: "heart"), for: .normal)
//            sender.tintColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)
//            deleteLikeBatch(row: row)
//            self.likeContentsArray.removeAll(where: {$0.documentID == contentsArray[row].documentID})
//            var count = Int(countLabel.text!)!
//            if count >= 1{
//                count -= 1
//                countLabel.text = count.description
//                contentsArray[row].likeCount = count
//            }
//        }
    }
    
}







extension EnteredRoomContentViewController:RemoveContentsDelegate{
    func removeMutedContent(documentID:String) {
//        self.contentsArray.removeAll { content in
//            return content.documentID == documentID
//        }
//        self.contentsTableView.reloadData()
    }
    
    
    func removeBlockedUserContents(uid:String,roomID:String){
//        self.contentsArray.removeAll { content in
//            return content.uid == uid && content.roomID == roomID
//        }
//        self.contentsTableView.reloadData()
    }
}



extension EnteredRoomContentViewController:UIViewControllerTransitioningDelegate{
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentModalViewController(presentedViewController: presented, presenting: presenting)
    }
}










