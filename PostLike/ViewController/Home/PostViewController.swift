//
//  PostViewController.swift
//  postLike
//
//  Created by taichi on 2020/12/27.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import DKImagePickerController
import Firebase
import RxSwift
import RxCocoa
//import FirebaseFirestore
//import FirebaseAuth
//import FirebaseStorage

final class PostViewController: UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    
    
    @IBOutlet private weak var textView: LinkTextView!
    @IBOutlet private weak var photoTableView: UITableView!
    @IBOutlet private weak var buttonView: UIView!
    @IBOutlet private weak var postButton: UIButton!
    @IBOutlet private weak var postTitleLabel: UILabel!
    @IBOutlet private weak var profileImage: UIImageView!
    @IBOutlet private weak var profileName: UILabel!
    @IBOutlet private weak var postContentView: UIView!
    @IBOutlet private weak var personImage: UIImageView!
    
    
    private var photoArray:[UIImage] = []
    private var photoUrl :[String] = []
    private let postViewModel = PostViewModel()
    private let disposeBag = DisposeBag()
    var passedRoomTitle = String()
    var passedDocumentID = String()
    var passedUserImageUrl = String()
    var passedUserName = String()
    var passedHostUid = String()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoTableView.delegate = self
        photoTableView.dataSource = self
        
        textView.delegate = self
        textView.becomeFirstResponder()
        
        buttonView.frame.size.width = self.view.frame.size.width
        
        postButton.layer.cornerRadius = 20
        postButton.backgroundColor = .systemGray4
        
        profileImage.layer.cornerRadius = 18
        if passedUserImageUrl != "" {
            profileImage.sd_setImage(with: URL(string: passedUserImageUrl), completed: nil)
            personImage.image = UIImage()
        }
        
        profileName.text = passedUserName
        
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        setupBind()
        
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    
    
    
    @IBAction private func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    private func setupBind() {
        
        textView.rx.text
            .asDriver()
            .drive { [weak self] text in
                self?.postViewModel.postTextInPut.onNext(text ?? "")
            }
            .disposed(by: disposeBag)
        
        postViewModel.validPostDriver
            .drive { [weak self] bool in
                self?.postButton.isEnabled = bool
                self?.postButton.backgroundColor = bool ? .red : .systemGray4
            }
            .disposed(by: disposeBag)
 
    }
    
    
    
    
    func showAlbum(){
        let pickerController = DKImagePickerController()
        pickerController.maxSelectableCount = 2
        pickerController.sourceType = .photo
        pickerController.assetType = .allPhotos
        pickerController.allowSelectAll = true
        pickerController.showsCancelButton = true
        pickerController.didSelectAssets = {(assets: [DKAsset]) in
            for asset in assets {
                self.postViewModel.photoArrayInPut.onNext(assets)
                asset.fetchFullScreenImage(completeBlock: { (image, info) in
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                        self.photoArray.append(image!)
                        self.photoTableView.reloadData()
                    }
                    self.textView.resignFirstResponder()
                })
            }
        }
        pickerController.modalPresentationStyle = .fullScreen
        pickerController.UIDelegate = CustomUIDelegate()
        self.present(pickerController, animated: true, completion: nil)
    }
    
    
    
    
    @IBAction private func albumButton(_ sender: Any) {
        showAlbum()
    }
    
    @IBAction private func albumButton2(_ sender: Any) {
        showAlbum()
    }
    
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photoArray.count
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = photoTableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let contentImageView = cell.viewWithTag(1) as! UIImageView
        contentImageView.image = photoArray[indexPath.row]
        contentImageView.layer.cornerRadius = 10
        
        let deleteButton = UIButton()
        deleteButton.frame = CGRect(x: 5, y: 5, width: 30, height: 30)
        deleteButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        deleteButton.tintColor = .white
        deleteButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        deleteButton.layer.cornerRadius = 15
        contentImageView.addSubview(deleteButton)
        deleteButton.tag = -indexPath.row
        deleteButton.addTarget(self, action: #selector(deleteImage(_:)), for: .touchUpInside)
        
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 237
    }
    
    @objc func deleteImage(_ sender:UIButton){
        self.postViewModel.photoArrayInPut.onNext([])
        self.photoArray.remove(at: -sender.tag)
        photoTableView.reloadData()
    }
    
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if photoTableView.isDragging == true {
            textView.resignFirstResponder()
        }
    }
    
    
    
    
    
    
    
    func createPosts(uid:String,documentID:String,media:Array<Any>,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let dic = [
            "userName":passedUserName,
            "userImage":passedUserImageUrl,
            "media": media,
            "text":textView.text!,
            "createdAt":Timestamp(),
            "uid":uid,
            "documentID":documentID,
            "roomID":passedDocumentID,
            "likeCount":0,
            "commentCount":0
        ]
        as [String: Any]
        Firestore.createPost(roomID: passedDocumentID, documentID: documentID, media: media, dic: dic, batch: batch)
    }
    
    
    //cloud functionのトリガー用
    func createModeratorPosts(uid:String,documentID:String,media:Array<Any>,batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let dic = [
            "createdAt":Timestamp(),
            "uid":uid,
            "roomID":passedDocumentID,
            "documentID":documentID
        ] as [String : Any]
        Firestore.createModeratorPost(roomID: passedDocumentID, documentID: documentID, dic: dic, batch: batch)
    }
    
    
    //クエリの制限で写真のみを作成順で取得できないため写真を別コレクションで保存
    func createMediaPosts(uid:String,documentID:String,media:Array<String>,batch:WriteBatch){
        let dic = [
            "media":media,
            "createdAt":Timestamp(),
            "uid":uid,
            "roomID":passedDocumentID,
            "documentID":documentID,
            "userName":passedUserName,
            "userImage":passedUserImageUrl,
            "likeCount":0,
            "commentCount":0,
            "text":textView.text ?? ""] as [String : Any]
        Firestore.createcreateMediaPost(roomID: passedDocumentID, documentID: documentID, dic: dic, batch: batch)
    }
    
    

    
    
    func postBatch(uid:String,documentID:String,batch:WriteBatch){
        
        if passedHostUid == uid {
            createPosts(uid: uid, documentID: documentID, media: [""], batch: batch)
            createModeratorPosts(uid: uid, documentID: documentID, media: [""], batch: batch)
            Firestore.increaseRoomPostCount(uid: uid, roomID: passedDocumentID, batch: batch)
            Firestore.increaseProfilePostCount(uid: uid, roomID: passedDocumentID, batch: batch)
        }else{
            createPosts(uid: uid, documentID: documentID, media: [""], batch: batch)
            Firestore.increaseRoomPostCount(uid: uid, roomID: passedDocumentID, batch: batch)
            Firestore.increaseProfilePostCount(uid: uid, roomID: passedDocumentID, batch: batch)
        }
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                    self.dismiss(animated: true, completion: nil)
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }else{
                print("success")
                self.dismissIndicator()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
    
    
    func creatFireStorage(uid:String,documentID:String,batch:WriteBatch){
        Storage.addPostImagesToStrage(imagesArray: self.photoArray) { bool, urlStringArray in
            switch bool {
            case false:
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                    self.dismiss(animated: true, completion: nil)
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
            case true:
                if self.passedHostUid == uid {
                    self.createPosts(uid: uid, documentID: documentID, media: urlStringArray, batch: batch)
                    self.createModeratorPosts(uid: uid, documentID: documentID, media: urlStringArray, batch: batch)
                    self.createMediaPosts(uid: uid, documentID: documentID, media: urlStringArray, batch: batch)
                    Firestore.increaseRoomPostCount(uid: uid, roomID: self.passedDocumentID, batch: batch)
                    Firestore.increaseProfilePostCount(uid: uid, roomID: self.passedDocumentID, batch: batch)
                }else{
                    self.createPosts(uid: uid, documentID: documentID, media: urlStringArray, batch: batch)
                    self.createMediaPosts(uid: uid, documentID: documentID, media: urlStringArray, batch: batch)
                    Firestore.increaseRoomPostCount(uid: uid, roomID: self.passedDocumentID, batch: batch)
                    Firestore.increaseProfilePostCount(uid: uid, roomID: self.passedDocumentID, batch: batch)
                }
                batch.commit { err in
                    if let err = err {
                        print("false\(err)")
                        let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                            self.dismissIndicator()
                            self.dismiss(animated: true, completion: nil)
                        }
                        self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                        return
                    }else{
                        print("success")
                        self.dismissIndicator()
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    @IBAction private func postButton(_ sender: Any) {
        startIndicator()
        textView.resignFirstResponder()
        let uid = Auth.auth().currentUser!.uid
        let documentID = NSUUID().uuidString
        let batch = Firestore.firestore().batch()
        if photoArray.isEmpty == true {
            postBatch(uid: uid, documentID: documentID, batch: batch)
        }else{
            creatFireStorage(uid: uid, documentID: documentID, batch: batch)
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
}



extension PostViewController: UITextViewDelegate{
    
    @objc private func keybordWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String:Any] else {
            return
        }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        guard let rect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        UIView.animate(withDuration: duration) {
            self.buttonView.frame.origin.y = rect.origin.y - self.buttonView.frame.size.height
        }
    }
    
    
    @objc private func keybordWillHide(_ notification: Notification) {
        self.buttonView.frame.origin.y = self.view.frame.size.height - (self.buttonView.frame.size.height+self.view.safeAreaInsets.bottom)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.photoTableView.endEditing(true)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.markedTextRange == nil{
            self.textView.setText(text: textView.text, urls: textView.text.urlsFromRegexs)
        }
        
    }
    
    
    
}















