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
import FirebaseStorage
import DKImagePickerController


protocol CreateProfileDelegate:AnyObject {
    func joinRoomBatch(_ completed: @escaping() -> Void,userName:String)
    func createStrageWithBatch(_ completed: @escaping() -> Void,userName:String,profileImageView:UIImageView)
}

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
    private var label = MessageLabel()
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
        
        self.setSwipeBackGesture()
        setupTableView()
        fetchContents()
        headerView.setupBind(roomID: passedDocumentID, roomImageView: roomImageView, topRoomNameLabel: roomName, vc: self, tableView: contentsTableView)
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
        let refleshControl = CustomRefreshControl()
        self.contentsTableView.refreshControl = refleshControl
        self.contentsTableView.refreshControl?.addTarget(self, action: #selector(updateContents), for: .valueChanged)
    }
    
    
    
    
    

    
    
    
    private func fetchContents(){
        viewModel = FeedViewModel(feedContentsListner: FeedContentsDefaultListner(), likeListner: LikeDefaultListner(), userListner: UserDefaultLisner(), reportListner: ReportDefaultListner(), roomID: passedDocumentID)
        
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
    
}












extension RoomDetailViewController: UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = contentsTableView.dequeueReusableCell(withIdentifier: "FeedTableViewCell", for: indexPath) as! FeedTableViewCell
        cell.setupBinds(content: contentsArray[indexPath.row], roomID: passedDocumentID, vc: self)
        cell.setContent(contents: contentsArray[indexPath.row], likeContensArray: likeContentsArray)
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == self.contentsArray.count  {
        }
    }
  
    
}








extension RoomDetailViewController:UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        return PresentModalViewController(presentedViewController: presented, presenting: presenting)
        
    }
}


extension RoomDetailViewController:CreateProfileDelegate {
    
    private func createMemberList(batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let docData = ["uid":uid]
        let ref =  Firestore.firestore().collection("rooms").document(passedDocumentID).collection("members").document(uid)
        batch.setData(docData, forDocument: ref)
    }
    
    
    
    private func increaseMemberCount(batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(passedDocumentID).collection("memberCount").document("count")
        batch.setData(["memberCount": FieldValue.increment(1.0)], forDocument: ref, merge: true)
    }
    
    
    
    
    private func creatProfileWhenHaveCreated(){
        let batch = Firestore.firestore().batch()
        let uid = Auth.auth().currentUser!.uid
        let timestamp = Timestamp()
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID)
        
        batch.updateData(["isJoined":true,"createdAt":timestamp,"roomName":self.roomInfo!.roomName,"roomImage":self.roomInfo!.roomImage], forDocument: ref)
        increaseMemberCount(batch: batch)
        createMemberList(batch: batch)
        batch.commit { err in
            if let err = err{
                print("false\(err)")
                return
            }else{
                print("scucces")
                self.headerView.joinButton.setTitle("ルームへ", for: .normal)
                self.headerView.joinButton.setTitleColor(.black, for: .normal)
                self.headerView.joinButton.backgroundColor = .systemBackground
            }
        }
    }
    
    
    
    
    
    private func createRoomDetail(userName:String,userImageUrl:String,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let timestamp = Timestamp()
        let docData = ["createdAt":timestamp,"userName":userName,"userImage":userImageUrl,"documentID":passedDocumentID,"roomName":self.roomInfo!.roomName,"roomImage":self.roomInfo!.roomImage,"uid":uid,"moderator":self.roomInfo!.moderator,"isJoined":true] as [String:Any]
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID)
        
        batch.setData(docData, forDocument: ref)
        
    }
    
    
    
    func joinRoomBatch(_ completed: @escaping() -> Void,userName:String){
        let batch = Firestore.firestore().batch()
        createRoomDetail(userName: userName, userImageUrl: "", batch: batch)
        increaseMemberCount(batch: batch)
        createMemberList(batch: batch)
        batch.commit { err in
            if let err = err{
                print("false\(err)")
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }else{
                print("scucces")
                self.headerView.joinButton.setTitle("ルームへ", for: .normal)
                self.headerView.joinButton.setTitleColor(.black, for: .normal)
                self.headerView.joinButton.backgroundColor = .systemBackground
                self.dismissIndicator()
                completed()
            }
        }
    }
    
    
    func createStrageWithBatch(_ completed: @escaping() -> Void,userName:String,profileImageView:UIImageView){
        guard let profileImage = profileImageView.image?.jpegData(compressionQuality: 0.1) else {return}
        let fileName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_images").child(fileName)
        storageRef.putData(profileImage, metadata: nil) { (metadata, err) in
            
            if let err = err{
                print("Firestorageへの保存に失敗しました。\(err)")
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }else{
                print("Firestorageへの保存に成功しました。")
                storageRef.downloadURL { (url, err) in
                    if let err = err {
                        print("firestorageからのダウンロードに失敗しました。\(err)")
                        let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                            self.dismissIndicator()
                        }
                        self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                        return
                    }
                    guard let urlString = url?.absoluteString else{return}
                    let batch = Firestore.firestore().batch()
                    self.createRoomDetail(userName: userName, userImageUrl: urlString, batch: batch)
                    self.increaseMemberCount(batch: batch)
                    self.createMemberList(batch: batch)
                    batch.commit { err in
                        if let err = err{
                            print("false\(err)")
                            let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                                self.dismissIndicator()
                            }
                            self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                            return
                        }else{
                            print("scucces")
                            self.headerView.joinButton.setTitle("ルームへ", for: .normal)
                            self.headerView.joinButton.setTitleColor(.black, for: .normal)
                            self.headerView.joinButton.backgroundColor = .systemBackground
                            self.dismissIndicator()
                            completed()
                        }
                    }
                }
            }
        }
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



