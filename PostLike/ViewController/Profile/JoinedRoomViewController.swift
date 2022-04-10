//
//  Myprofile2ViewController.swift
//  postLike
//
//  Created by taichi on 2020/11/04.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import RxSwift
import FirebaseFirestore
import FirebaseAuth


final class JoinedRoomViewController: UIViewController, UIGestureRecognizerDelegate{
    
    
    @IBOutlet private weak var roomCollectionView: UICollectionView!
    
    @IBOutlet weak var threeLineButton: UIButton! {
        didSet {
            if #available(iOS 15, *) {
                threeLineButton.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
            }else {
                threeLineButton.setImage(UIImage(systemName: "line.horizontal.3"), for: .normal)
            }
        }
    }
    
    
    private var joinedRoomsArray = [Contents]()
    private var label = MessageLabel()
    private var viewModel: RoomViewModel!
    private let disposeBag = DisposeBag()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        fetchProfileRoom()
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    
    
    
    
    
    @IBAction private func menuButton(_ sender: Any) {
        let accountSettingVC = storyboard?.instantiateViewController(withIdentifier: "accountSettingVC") as! AccountSettingViewController
        accountSettingVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(accountSettingVC, animated: true)
    }
    

    
    private func setupCollectionView() {
        roomCollectionView.delegate = self
        roomCollectionView.dataSource = self
        let nib = UINib(nibName: "RoomCollectionViewCell", bundle: .main)
        roomCollectionView.register(nib, forCellWithReuseIdentifier: "myroomCell")
        collectionItenSize()
    }
    
    
    
    
    private func fetchProfileRoom(){
        viewModel = RoomViewModel(roomListner: RoomDefaultListner())
        viewModel.rooms
            .drive { [weak self] rooms in
                self?.joinedRoomsArray.removeAll()
                self?.joinedRoomsArray.append(contentsOf: rooms)
                self?.roomCollectionView.reloadData()
            }
            .disposed(by: disposeBag)
        viewModel.isEmpty
            .drive { [weak self] bool in
                if bool == true {
                    self?.label.setup(text: "参加しているルームはありません。", at: self!.roomCollectionView)
                }else {
                    self?.label.text = ""
                }
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    
}






extension JoinedRoomViewController:UICollectionViewDelegate,UICollectionViewDataSource{
    
    private func collectionItenSize(){
        //セルの大きさと間隔
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (self.view.frame.width - 55)/2, height: 140)
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 15
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 10, right: 20)
        roomCollectionView.collectionViewLayout = layout
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        joinedRoomsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = roomCollectionView.dequeueReusableCell(withReuseIdentifier: "myroomCell", for: indexPath) as! RoomCollectionViewCell
        cell.setupCell(item: joinedRoomsArray[indexPath.row])
        return cell
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let profileVC = storyboard?.instantiateViewController(identifier: "myproVC") as! ProfileViewController
        profileVC.passedDocumentID = joinedRoomsArray[indexPath.row].documentID
        profileVC.passedModerator = joinedRoomsArray[indexPath.row].moderator
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    
    
    
    
    
    
}
