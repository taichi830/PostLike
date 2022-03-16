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
    private var contentsArray = [Contents]()
    private var likeContentsArray = [Contents]()
    private let disposeBag = DisposeBag()
    var viewModel: FeedViewModel!
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setSwipeBackGesture()
        setupTableView()
        refrashTableView()
        setupBinds()
        
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
        
        
    }
    
    
    
    private func refrashTableView() {
        let refreshControl = CustomRefreshControl()
        contentsTableView.refreshControl = refreshControl
        contentsTableView.refreshControl?.rx.controlEvent(.valueChanged)
            .subscribe{ [weak self] _ in
                self?.viewModel.refreshObserver.onNext(())
            }
            .disposed(by: disposeBag)
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
    
    
    
    
    
    private func setupBinds() {
        viewModel = FeedViewModel(feedContentsListner: FeedContentsDefaultListner(), likeListner: GetDefaultLikes(), userListner: UserDefaultLisner(), reportListner: ReportDefaultListner(), roomID: passedDocumentID)
        headerView.setupBind(roomID: passedDocumentID, roomImageView: roomImageView, topRoomNameLabel: topRoomNameLabel, vc: self)
        self.startIndicator()
        emptyCheck()
        fetchFeedContents()
        fetchLatestMyContent()
        fetchLatestLikeContent()
        fetchDeletedPost()
        tableViewDidScroll()
    }
    
    
    
    
    
    
    
    private func emptyCheck() {
        viewModel.isEmpty
            .drive { [weak self] bool in
                switch bool {
                case true:
                    self?.dismissIndicator()
                    self?.contentsTableView.refreshControl?.endRefreshing()
                    self?.messageLabel.setup(text: "投稿がありません", at: self!.contentsTableView)
                    
                case false:
                    self?.dismissIndicator()
                    self?.contentsTableView.refreshControl?.endRefreshing()
                    self?.messageLabel.text = ""
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
    
    
    
    
    
    //投稿後リアルタイムで自分の投稿を取得
    private func fetchLatestMyContent() {
        LatestContentsSubject.shared.latestFeedContents
            .subscribe { [weak self] content in
                guard let element = content.element else { return }
                self?.viewModel.insertLatestItem(item: [element])
                self?.contentsTableView.reloadData()
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    //他画面でいいねした投稿をリアルタイムで取得
    private func fetchLatestLikeContent() {
        LatestContentsSubject.shared.latestLikeContents
            .subscribe { [weak self] contents in
                guard let element = contents.element else { return }
                if element.isLiked == true {
                    self?.viewModel.appendLatestLikeContent(content: [element])
                    self?.contentsTableView.reloadData()
                }else {
                    self?.viewModel.removeLikeContent(content: element)
                    self?.contentsTableView.reloadData()
                }
            }
            .disposed(by: disposeBag)
    }
    
    
    
    //削除した投稿を配列からremove
    private func fetchDeletedPost() {
        LatestContentsSubject.shared.deletedContents
            .subscribe { [weak self] content in
                guard let element = content.element else { return }
                self?.viewModel.removeDeletedItem(item: element)
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




// MARK: - UITabelView Delegate,DataSource Method
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
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath.row + 1 == self.contentsArray.count)  {
            viewModel.isBottomObserver.onNext(true)
        }
    }
    
}


// MARK: - UIViewControllerTransitioningDelegate
extension EnteredRoomContentViewController:UIViewControllerTransitioningDelegate{
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentModalViewController(presentedViewController: presented, presenting: presenting)
    }
}










