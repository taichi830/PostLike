//
//  roomDetailViewController.swift
//  postLike
//
//  Created by taichi on 2020/11/25.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import RxSwift
import FirebaseFirestore
import FirebaseAuth



final class RoomDetailViewController: UIViewController {
    
    
    
    @IBOutlet weak var roomName: UILabel! {
        didSet {
            roomName.adjustsFontSizeToFitWidth = true
            roomName.minimumScaleFactor = 0.9
        }
    }
    @IBOutlet weak var backButtonBackView: UIView! {
        didSet {
            backButtonBackView.layer.cornerRadius = 15
        }
    }
    @IBOutlet weak var dotButtonBackView: UIView! {
        didSet {
            dotButtonBackView.layer.cornerRadius = 15
        }
    }
    @IBOutlet weak var contentsTableView: UITableView!
    @IBOutlet weak var roomImageView: UIImageView!
    @IBOutlet weak var roomImageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var roomImageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topBlurEffectView: UIVisualEffectView!
    @IBOutlet weak var headerView: SearchResultHeaderView!
    @IBOutlet weak var effectViewHeight: NSLayoutConstraint!
    

    var passedDocumentID = String()
    private var mssageLabel = MessageLabel()
    private var contentsArray = [Contents]()
    private var likeContentsArray = [Contents]()
    private var joinedRoom:Contents?
    private var roomInfo:Room?
    private var lastDocument:QueryDocumentSnapshot?
    private lazy var indicator:UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.center = roomImageView.center
        indicator.style = .medium
        indicator.color = .white
        indicator.hidesWhenStopped = true
        roomImageView.addSubview(indicator)
        return indicator
    }()
    private var viewModel: FeedViewModel!
    private let disposeBag = DisposeBag()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBinds()
        self.setSwipeBackGesture()
        setupTableView()
        refreshTableView()
    }
    
    
    
    
    
    
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        effectViewHeight.constant = self.view.safeAreaInsets.top + 46
    }
    
    
    
    
    
    
    
    
    
    
    
    
    @objc private func updateContents(){
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    @IBAction private func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    
    
    
    
    
    
    @IBAction private func reportButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let modalMenuVC = storyboard.instantiateViewController(withIdentifier: "modalMenu") as! ModalMenuViewController
        modalMenuVC.modalPresentationStyle = .custom
        modalMenuVC.transitioningDelegate = self
        modalMenuVC.passedViewController = self
        modalMenuVC.passedModalType = .room
        modalMenuVC.passedRoomInfo = headerView.roomInfo ?? Room(dic: [:])
        present(modalMenuVC, animated: true, completion: nil)
    }
    
    
    
    
    
    
    
    
    
    
    @objc private func swiped(_ sender:UISwipeGestureRecognizer){
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    
    
    
    
    private func setupTableView() {
        self.contentsTableView.delegate = self
        self.contentsTableView.dataSource = self
        self.contentsTableView.register(UINib(nibName: "FeedTableViewCell", bundle: nil), forCellReuseIdentifier: "FeedTableViewCell")
        self.contentsTableView.contentInsetAdjustmentBehavior = .never
        
    }
    
    
    
    
    private func refreshTableView() {
        let refleshControl = CustomRefreshControl()
        contentsTableView.refreshControl = refleshControl
        contentsTableView.refreshControl?.rx.controlEvent(.valueChanged)
            .subscribe { [weak self] _ in
                self?.viewModel.refreshObserver.onNext(())
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    private func setupBinds() {
        viewModel = FeedViewModel(feedContentsListner: FeedContentsDefaultListner(), likeListner: LikeDefaultListner(), userListner: UserDefaultLisner(), reportListner: ReportDefaultListner(), roomID: passedDocumentID)
        headerView.setupBind(roomID: passedDocumentID, roomImageView: roomImageView, topRoomNameLabel: roomName, vc: self, tableView: contentsTableView)
        self.startIndicator()
        emptyCheck()
        fetchLatestMyContent()
        fetchLatestLikeContent()
        fetchContents()
    }
    
    
    
    
    
    private func emptyCheck() {
        viewModel.isEmpty
            .drive { [weak self] bool in
                switch bool {
                case true:
                    self?.dismissIndicator()
                    self?.contentsTableView.refreshControl?.endRefreshing()
                    self?.mssageLabel.setup(text: "投稿がありません", at: self!.contentsTableView)
                    
                case false:
                    self?.dismissIndicator()
                    self?.contentsTableView.refreshControl?.endRefreshing()
                    self?.mssageLabel.text = ""
                }
            }
            .disposed(by: disposeBag)
    }
    
    

    
    
    private func fetchContents(){
        
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
                self?.contentsArray.insert(element, at: 0)
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
                    self?.likeContentsArray.append(element)
                    self?.increaseLikeCount(element: element)
                    self?.contentsTableView.reloadData()
                }else {
                    self?.likeContentsArray.removeAll {
                        $0.documentID == element.documentID
                    }
                    self?.decreaseLikeCount(element: element)
                    self?.contentsTableView.reloadData()
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
    
    
    
    
    
    
    
    
    
}











extension RoomDetailViewController: UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = contentsTableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell", for: indexPath) as! FeedTableViewCell
        cell.setupBinds(content: contentsArray[indexPath.row], roomID: passedDocumentID, vc: self, modalType: .post)
        cell.setContent(contents: contentsArray[indexPath.row], likeContensArray: likeContentsArray)
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == self.contentsArray.count  {
            viewModel.isBottomObserver.onNext(true)
        }
    }
  
    
}




extension RoomDetailViewController:UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        return PresentModalViewController(presentedViewController: presented, presenting: presenting)
        
    }
}




extension RoomDetailViewController:UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0 {
            self.roomImageViewHeight.constant = -(scrollView.contentOffset.y - 180)
            self.roomImageViewTopConstraint.constant = 0
        }else{
            self.roomImageViewHeight.constant = 180
            self.roomImageViewTopConstraint.constant = -scrollView.contentOffset.y
        }
        
        //下にスクロールに合わせて徐々にblurをかける
        topBlurEffectView.alpha = -0.7 + (scrollView.contentOffset.y - 50)/50
        
        
    }
}



