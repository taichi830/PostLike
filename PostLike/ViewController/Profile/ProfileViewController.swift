//
//  ProfileViewController.swift
//  postLike
//
//  Created by taichi on 2021/04/10.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage


protocol DeletePostDelegate:AnyObject {
    func deletePostBatch(documentID:String,imageUrl:[String])
}
protocol ExitRoomDelegate:AnyObject {
    func exitRoomBatch()
}
protocol DeleteRoomDelegate:AnyObject {
    func deleteRoomAtContainerView()
}




final class ProfileViewController: UIViewController {
    
    
    var passedDocumentID = String()
    var passedModerator = String()
    private var contentsArray = [Contents]()
    private var userInfo:Contents?
    private var likeContentsArray = [Contents]()
    private var lastDocument:DocumentSnapshot?
    private var messageLabel = MessageLabel()
    private var viewModel: ProfileViewModel!
    private let disposeBag = DisposeBag()
    
    
    
    @IBOutlet private weak var headerView: UserProfileHeaderView!
    @IBOutlet private weak var titleName: UILabel!
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var profileTableView: UITableView!
    
    
    
    
    override func viewDidLoad(){
        super.viewDidLoad()
        self.setSwipeBackGesture()
        setupBinds()
    }
    
    

    
    
    
    
    
    
    
    @objc private func updateContents(){
    }
    
    

    
    
    
    
    @IBAction private func menuButton(_ sender: Any) {
        let uid = Auth.auth().currentUser!.uid
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let modalMenuVC = storyboard.instantiateViewController(withIdentifier: "modalMenu") as! ModalMenuViewController
        modalMenuVC.modalPresentationStyle = .custom
        modalMenuVC.transitioningDelegate = self
        modalMenuVC.passedViewController = self
        if passedModerator == uid {
            modalMenuVC.passedModalType = .moderator
        }else{
            modalMenuVC.passedModalType = .exit
            modalMenuVC.exitRoomDelegate = self
        }
        present(modalMenuVC, animated: true, completion: nil)
    }
    
    
    
    

    @IBAction private func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    private func createProfileTableView(){
        profileTableView.delegate = self
        profileTableView.dataSource = self
        profileTableView.tableHeaderView = headerView
        profileTableView.register(UINib(nibName: "FeedTableViewCell", bundle: nil), forCellReuseIdentifier: "FeedTableViewCell")
    }
    
    
    
    
    
    private func setupBinds() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        viewModel = ProfileViewModel(profileContentsListner: ProfileContentsDefaultListner(), likeListner: LikeDefaultListner(), uid: uid, roomID: passedDocumentID)
        headerView.setupHeaderView(roomID: passedDocumentID, passedUid: passedModerator, titleName: titleName, vc: self)
        startIndicator()
        createProfileTableView()
        reflashTableView()
        emptyCheck()
        fetchContents()
    }
    
    
    
    
    private func reflashTableView() {
        let refreshControl = UIRefreshControl()
        profileTableView.refreshControl = refreshControl
        profileTableView.refreshControl?.rx.controlEvent(.valueChanged)
            .subscribe{ [weak self] _ in
                self?.viewModel.reflashObserver.onNext(())
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    private func emptyCheck(){
        viewModel.isEmpty
            .drive { [weak self] bool in
                switch bool {
                case true :
                    self?.dismissIndicator()
                    self?.profileTableView.refreshControl?.endRefreshing()
                    self?.messageLabel.setupLabel(view: self!.view, y: self!.view.center.y + 50)
                    self?.messageLabel.text = "投稿がまだありません"
                    self?.profileTableView.addSubview(self!.messageLabel)
                    
                case false:
                    self?.dismissIndicator()
                    self?.profileTableView.refreshControl?.endRefreshing()
                    self?.messageLabel.text = ""
                }
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    private func fetchContents() {
        viewModel.items.drive { [weak self] items in
            self?.contentsArray.removeAll()
            self?.contentsArray.append(contentsOf: items)
            self?.profileTableView.reloadData()
        }
        .disposed(by: disposeBag)
        
        viewModel.likes
            .drive { [weak self] likes in
                self?.likeContentsArray.removeAll()
                self?.likeContentsArray.append(contentsOf: likes)
                self?.profileTableView.reloadData()
            }
            .disposed(by: disposeBag)
    }
    
    
    //いいねした投稿をリアルタイムで取得
    private func fetchLatestLikeContent() {
        LatestContentsSubject.shared.latestLikeContents
            .subscribe { [weak self] contents in
                guard let element = contents.element else { return }
                if element.isLiked == true {
                    self?.likeContentsArray.append(element)
                    self?.increaseLikeCount(element: element)
                    self?.profileTableView.reloadData()
                }else {
                    self?.likeContentsArray.removeAll {
                        $0.documentID == element.documentID
                    }
                    self?.decreaseLikeCount(element: element)
                    self?.profileTableView.reloadData()
                }
            }
            .disposed(by: disposeBag)
    }
    
    //いいね数をリアルタイムでインクリメント
    private func increaseLikeCount(element: Contents) {
        if let i = contentsArray.firstIndex(where: {$0.documentID == element.documentID}) {
            var count = contentsArray[i].likeCount
            count += 1
            contentsArray[i].likeCount = count
            contentsArray[i].isLiked = true
        }
    }
    
    //いいね数をリアルタイムでディクリメント
    private func decreaseLikeCount(element: Contents) {
        if let i = contentsArray.firstIndex(where: {$0.documentID == element.documentID}) {
            var count = contentsArray[i].likeCount
            count -= 1
            contentsArray[i].likeCount = count
            contentsArray[i].isLiked = true
        }
    }
    
    
    //投稿後リアルタイムで自分の投稿を取得
    private func fetchLatestMyContent() {
        LatestContentsSubject.shared.latestFeedContents
            .subscribe { [weak self] content in
                guard let element = content.element else { return }
                self?.contentsArray.insert(element, at: 0)
                self?.profileTableView.reloadData()
            }
            .disposed(by: disposeBag)
    }
    
    //削除した投稿を配列からremove
    private func fetchDeletedPost() {
        LatestContentsSubject.shared.deletedContents
            .subscribe { [weak self] content in
                guard let element = content.element else { return }
                self?.contentsArray.removeAll {
                    $0.documentID == element.documentID
                }
                self?.profileTableView.reloadData()
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    
    
    
}




extension ProfileViewController:UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentModalViewController(presentedViewController: presented, presenting: presenting)
    }
}







extension ProfileViewController:UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return contentsArray.count
    }
    
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let cell = profileTableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell")  as! FeedTableViewCell
        cell.setContent(contents: contentsArray[indexPath.row], likeContensArray: likeContentsArray)
        cell.setupBinds(content: contentsArray[indexPath.row], roomID: passedDocumentID, vc: self, modalType: .delete)

        
        return cell
    }
    
    
 
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == contentsArray.count {
            viewModel.isBottomObserver.onNext(())
        }
    }
    
    
    

}



//MARK: ルーム退出時のデリゲート処理
extension ProfileViewController:ExitRoomDelegate{

    func exitRoomBatch(){
        let batch = Firestore.firestore().batch()
        Firestore.exitRoom(documentID: passedDocumentID, batch: batch)
        Firestore.decreaseMemberCount(documentID: passedDocumentID, batch: batch)
        Firestore.deleteUidFromRoomMateList(documentID: passedDocumentID, batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }else{
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    
    
    
}



//MARK: ルーム削除時のデリゲート処理
extension ProfileViewController:DeleteRoomDelegate{

    func deleteRoomAtContainerView(){
        let batch = Firestore.firestore().batch()
        Firestore.deleteRoom(documentID: passedDocumentID, batch: batch)
        Firestore.deleteMyprofile(documentID: passedDocumentID, batch: batch)
        Firestore.deleteMemberCount(documentID: passedDocumentID, batch: batch)
        Firestore.deleteRoomPostCount(documentID: passedDocumentID, batch: batch)
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }else{
                self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    
    
    
}










