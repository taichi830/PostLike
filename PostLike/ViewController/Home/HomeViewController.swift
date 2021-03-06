//
//  HomeViewController.swift
//  postLike
//
//  Created by taichi on 2020/11/20.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import RxSwift
import FirebaseFirestore
import FirebaseAuth

final class HomeViewController: UIViewController,UIGestureRecognizerDelegate{
    
    
    
    @IBOutlet private weak var roomCollectionView: UICollectionView!
    @IBOutlet private weak var timeLineTableView: UITableView!
    @IBOutlet private weak var bluredView: UIView!
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var headerSeparaterView: UIView!
    
    
    private var joinedRoomsArray = [Contents]()
    private var likeContentsArray = [Contents]()
    private var timeLineContents = [Contents]()
    private var messageLabel = MessageLabel()
    private var viewModel: HomeFeedViewModel!
    private let disposeBag = DisposeBag()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupTableView()
        refreshTableView()
        setupBinds()
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    private func setupCollectionView(){
        roomCollectionView.delegate = self
        roomCollectionView.dataSource = self
        let nib = UINib(nibName: "RoomCollectionViewCell", bundle: .main)
        roomCollectionView.register(nib, forCellWithReuseIdentifier: "myroomCell")
        roomCollectionView.frame = CGRect(x: 0, y: 5, width: self.view.frame.width, height: 130)
        headerSeparaterView.frame.size.width = self.view.frame.width
        collectionItemSize()
    }
    
    
    
    
    
    
    
    
    
    
    
    private func setupTableView(){
        timeLineTableView.delegate = self
        timeLineTableView.dataSource = self
        timeLineTableView.register(UINib(nibName: "FeedTableViewCell", bundle: nil), forCellReuseIdentifier: "FeedTableViewCell")
        timeLineTableView.showsVerticalScrollIndicator = true
        timeLineTableView.register(UINib(nibName: "NativeAdTableViewCell", bundle: nil), forCellReuseIdentifier: "nativeAdCell")
        timeLineTableView.tableHeaderView = headerView
        timeLineTableView.separatorInset = .zero
        
        
    }
    
    
    
    private func refreshTableView() {
        let refleshControl = UIRefreshControl()
        timeLineTableView.refreshControl = refleshControl
        timeLineTableView.refreshControl?.rx.controlEvent(.valueChanged)
            .subscribe { [weak self] _ in
                self?.viewModel.refreshObserver.onNext(())
            }
            .disposed(by: disposeBag)
    }
    
    
    private func setupBinds() {
        viewModel = HomeFeedViewModel(roomListner: RoomDefaultListner(), feedListner: GetDefaultPosts(), likeListner: GetDefaultLikes(), reportListner: ReportDefaultListner())
        startIndicator()
        bindRooms()
        bindFeeds()
        feedEmptyCheck()
        roomEmptyCheck()
        fetchLatestLikeContents()
    }
    
    
    private func roomEmptyCheck() {
        viewModel.isRoomEmpty
            .drive { [weak self] bool in
                switch bool {
                case true:
                    self?.dismissIndicator()
                    self?.messageLabel.setup(text: "参加中のルームはありません", at: self!.timeLineTableView)
                case false:
                    self?.messageLabel.text = ""
                }
            }
            .disposed(by: disposeBag)
    }
    
    
    private func bindRooms() {
        viewModel.rooms
            .drive { [weak self] rooms in
                self?.joinedRoomsArray.removeAll()
                self?.joinedRoomsArray.append(contentsOf: rooms)
                self?.roomCollectionView.reloadData()
            }
            .disposed(by: disposeBag)
    }
    
    
    private func feedEmptyCheck() {
        viewModel.isItemEmpty
            .drive { [weak self] bool in
                switch bool {
                case true:
                    self?.dismissIndicator()
                    self?.timeLineTableView.refreshControl?.endRefreshing()
                    self?.messageLabel.setup(text: "投稿はありません", at: self!.timeLineTableView)
                case false:
                    self?.dismissIndicator()
                    self?.timeLineTableView.refreshControl?.endRefreshing()
                    self?.messageLabel.text = ""
                }
            }
            .disposed(by: disposeBag)
    }
    
    
    private func bindFeeds() {
        viewModel.items
            .drive { [weak self] feeds in
                self?.timeLineContents.removeAll()
                self?.timeLineContents.append(contentsOf: feeds)
                self?.timeLineTableView.reloadData()
            }
            .disposed(by: disposeBag)
        
        viewModel.likes
            .drive { [weak self] likes in
                self?.likeContentsArray.removeAll()
                self?.likeContentsArray.append(contentsOf: likes)
                self?.timeLineTableView.reloadData()
            }
            .disposed(by: disposeBag)
    }
    
    
    private func fetchLatestLikeContents() {
        LatestContentsSubject.shared.latestLikeContents
            .subscribe { [weak self] contents in
                guard let element = contents.element else { return }
                if element.isLiked == true {
                    self?.likeContentsArray.append(element)
                    self?.increaseLikeCount(element: element)
                    self?.timeLineTableView.reloadData()
                }else {
                    self?.likeContentsArray.removeAll {
                        $0.documentID == element.documentID
                    }
                    self?.decreaseLikeCount(element: element)
                    self?.timeLineTableView.reloadData()
                }
            }
            .disposed(by: disposeBag)
    }
    
    
    private func increaseLikeCount(element: Contents) {
        guard let i = timeLineContents.firstIndex(where: { $0.documentID == element.documentID }) else { return }
        var count = timeLineContents[i].likeCount
        count += 1
        timeLineContents[i].likeCount = count
        timeLineContents[i].isLiked = true
        
    }
    
    
    private func decreaseLikeCount(element: Contents) {
        guard let i = timeLineContents.firstIndex(where: { $0.documentID == element.documentID }) else { return }
        var count = timeLineContents[i].likeCount
        count -= 1
        timeLineContents[i].likeCount = count
        timeLineContents[i].isLiked = true
        
    }
    
    
    @IBAction private func allViewButton(_ sender: Any) {
        let roomList = storyboard?.instantiateViewController(identifier: "roomList") as! RoomListViewController
        roomList.passedFollwedRoomArray = joinedRoomsArray
        navigationController?.pushViewController(roomList, animated: true)
    }
    
    
    
    
    
    
    
    
    
    
    
}





extension HomeViewController: UICollectionViewDelegate,UICollectionViewDataSource{
    
    func collectionItemSize(){
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width:130, height: 120)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        roomCollectionView.collectionViewLayout = layout
        layout.scrollDirection = .horizontal
        roomCollectionView.isPagingEnabled = false
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.joinedRoomsArray.isEmpty == true {
            return 5
        }else{
            return joinedRoomsArray.count
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        let cell = roomCollectionView.dequeueReusableCell(withReuseIdentifier: "myroomCell", for: indexPath) as! RoomCollectionViewCell
        if !joinedRoomsArray.isEmpty {
            cell.setupCell(item: joinedRoomsArray[indexPath.row])
        }
        return cell
    }
    
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.joinedRoomsArray.count != 0 {
            let enteredVC = storyboard?.instantiateViewController(withIdentifier: "enteredVC") as! EnteredRoomContentViewController
            enteredVC.passedDocumentID = joinedRoomsArray[indexPath.row].documentID
            navigationController?.pushViewController(enteredVC, animated: true)
        }
    }
    
}






extension HomeViewController: UITableViewDelegate,UITableViewDataSource{
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeLineContents.count
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = timeLineTableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell", for: indexPath) as! FeedTableViewCell
        
        cell.setContent(contents: timeLineContents[indexPath.row], likeContensArray: likeContentsArray)
        cell.setupBinds(content: timeLineContents[indexPath.row], roomID: timeLineContents[indexPath.row].roomID, vc: self, modalType: .post)
        
        let roomNameArray = joinedRoomsArray.filter {
            $0.documentID == timeLineContents[indexPath.row].roomID
        }
        let roomNameLabel = cell.roomNameLabel
        if roomNameArray.isEmpty != true {
            roomNameLabel?.text = ("\(roomNameArray[0].roomName)")
            roomNameLabel?.adjustsFontSizeToFitWidth = true
            roomNameLabel?.minimumScaleFactor = 0.8
        }
        let tapRoomLabel = UITapGestureRecognizer(target: self, action: #selector(tappedRoomNameLabel(_:)))
        roomNameLabel?.addGestureRecognizer(tapRoomLabel)
        
        
        
        
        return cell
        
    }
    
    
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath.row + 1 == self.timeLineContents.count)  {
            viewModel.isBottomObserver.onNext(true)
        }
    }
    
    
    
    @objc private func tappedRoomNameLabel(_ sender:UITapGestureRecognizer){
        let tappedLocation = sender.location(in: timeLineTableView)
        let tappedIndexPath = timeLineTableView.indexPathForRow(at: tappedLocation)
        let tappedRow = tappedIndexPath!.row
        let enteredVC = storyboard?.instantiateViewController(withIdentifier: "enteredVC") as! EnteredRoomContentViewController
        let roomInfo = joinedRoomsArray.filter {
            $0.documentID == timeLineContents[tappedRow].roomID
        }
        enteredVC.passedDocumentID = roomInfo[0].documentID
        navigationController?.pushViewController(enteredVC, animated: true)
    }
    
    
    
    
    
}








extension HomeViewController:UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentModalViewController(presentedViewController: presented, presenting: presenting)
    }
}





