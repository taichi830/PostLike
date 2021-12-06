//
//  PostViewController.swift
//  postLike
//
//  Created by taichi on 2020/12/27.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import DKImagePickerController
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class PostViewController: UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    
    
    @IBOutlet weak var textView: LinkTextView!
    @IBOutlet weak var photoTableView: UITableView!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var postTitleLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var profileName: UILabel!
    @IBOutlet weak var postContentView: UIView!
    @IBOutlet weak var personImage: UIImageView!
    
    
    private var photoArray:[UIImage] = []
    private var photoUrl :[String] = []
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
        
        profileImage.layer.cornerRadius = 18
        if passedUserImageUrl != "" {
            profileImage.sd_setImage(with: URL(string: passedUserImageUrl), completed: nil)
            personImage.image = UIImage()
        }
        
        profileName.text = passedUserName
        
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    
    
    
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
    
    
    
    
    @IBAction func albumButton(_ sender: Any) {
        showAlbum()
    }
    
    @IBAction func albumButton2(_ sender: Any) {
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
        self.photoArray.remove(at: -sender.tag)
        photoTableView.reloadData()
    }
    
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if photoTableView.isDragging == true {
            textView.resignFirstResponder()
        }
    }
    
    
    
    
    
    
    
    func createPosts(documentID:String,media:Array<Any>,batch:WriteBatch){
        let date = Timestamp()
        let uid = Auth.auth().currentUser!.uid
        let docData = ["userName":passedUserName,"userImage":passedUserImageUrl,"media": media,"text":textView.text!,"createdAt":date,"uid":uid,"documentID":documentID,"roomID":passedDocumentID,"likeCount":0,"commentCount":0] as [String: Any]
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).collection("posts").document(documentID)
        batch.setData(docData, forDocument: ref)
    }
    
    
    //cloud functionのトリガー用
    func createModeratorPosts(documentID:String,media:Array<Any>,batch:WriteBatch){
        let date = Timestamp()
        let uid = Auth.auth().currentUser!.uid
        let docData = ["createdAt":date,"uid":uid,"roomID":passedDocumentID,"documentID":documentID] as [String : Any]
        let ref = Firestore.firestore().collection("rooms").document(passedDocumentID).collection("moderatorPosts").document(documentID)
        batch.setData(docData, forDocument: ref)
    }
    
    
    //クエリの制限で写真のみを作成順で取得できないため写真を別コレクションで保存
    func createMediaPosts(documentID:String,media:Array<String>,batch:WriteBatch){
        let date = Timestamp()
        let uid = Auth.auth().currentUser!.uid
        let docData = ["media":media,"createdAt":date,"uid":uid,"roomID":passedDocumentID,"documentID":documentID,"userName":passedUserName,"userImage":passedUserImageUrl,"likeCount":0,"commentCount":0,"text":textView.text!] as [String : Any]
        let ref = Firestore.firestore().collection("rooms").document(passedDocumentID).collection("mediaPosts").document(documentID)
        batch.setData(docData, forDocument: ref)
    }

    
    
    
    func increaseMyPostCount(batch:WriteBatch){
        let uid = Auth.auth().currentUser!.uid
        let ref = Firestore.firestore().collection("users").document(uid).collection("rooms").document(passedDocumentID).collection("profilePostCount").document("count")
        batch.setData(["postCount": FieldValue.increment(1.0)], forDocument: ref, merge: true)
    }
    
    
    func increaseRoomPostCount(batch:WriteBatch){
        let ref = Firestore.firestore().collection("rooms").document(passedDocumentID).collection("roomPostCount").document("count")
        batch.setData(["postCount": FieldValue.increment(1.0)], forDocument: ref, merge: true)
    }
    
    
    
    
    func postBatch(documentID:String){
        let batch = Firestore.firestore().batch()
        let uid = Auth.auth().currentUser!.uid
        
        if passedHostUid == uid {
            createPosts(documentID: documentID, media: [""], batch: batch)
            increaseMyPostCount(batch: batch)
            increaseRoomPostCount(batch: batch)
            createModeratorPosts(documentID: documentID, media: [""], batch: batch)
        }else{
            createPosts(documentID: documentID, media: [""], batch: batch)
            increaseMyPostCount(batch: batch)
            increaseRoomPostCount(batch: batch)
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
    
    
    
    
    func creatFireStorage(documentID:String){
        for photo in photoArray{
            guard let posting = photo.jpegData(compressionQuality: 0.3)
            else{return}
            let fileName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("images").child("\(fileName).jpg")
            let metaData = StorageMetadata()
            metaData.contentType = "image.jpeg"
            storageRef.putData(posting, metadata: metaData){(metadata,err) in
                if let err = err {
                    print("Storageへの保存に失敗しました。\(err)")
                    let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                        self.dismissIndicator()
                    }
                    self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                    return
                }else{
                    print("Storageへの保存に成功しました")
                    storageRef.downloadURL { (url, err) in
                        if let err = err{
                            print("ダウンロードに失敗しました。\(err)")
                            let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                                self.dismissIndicator()
                                self.dismiss(animated: true, completion: nil)
                            }
                            self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                            return
                        }else{
                            guard let urlString = url?.absoluteString else{return}
                            self.photoUrl.append(urlString)
                            if self.photoUrl.count == self.photoArray.count {
                                let batch = Firestore.firestore().batch()
                                let uid = Auth.auth().currentUser!.uid
                                if self.passedHostUid == uid {
                                    self.createPosts(documentID: documentID, media: self.photoUrl, batch: batch)
                                    self.createMediaPosts(documentID: documentID, media: self.photoUrl, batch: batch)
                                    self.createModeratorPosts(documentID: documentID, media:self.photoUrl, batch: batch)
                                    self.increaseMyPostCount(batch: batch)
                                    self.increaseRoomPostCount(batch: batch)
                                }else{
                                    self.createPosts(documentID: documentID, media: self.photoUrl, batch: batch)
                                    self.createMediaPosts(documentID: documentID, media: self.photoUrl, batch: batch)
                                    self.increaseMyPostCount(batch: batch)
                                    self.increaseRoomPostCount(batch: batch)
                                }
                                batch.commit { err in
                                    if let err = err {
                                        print("false\(err)")
                                        let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                                            self.dismissIndicator()
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
                }
            }
        }
    }
    
    
    
    
    
   

    
    
    
    
    @IBAction func postButton(_ sender: Any) {
        if textView.text == "" && photoArray.isEmpty == true {
            return
        }else{
            startIndicator()
            textView.resignFirstResponder()
            let documentID = NSUUID().uuidString
            if photoArray.isEmpty == true {
                postBatch(documentID: documentID)
            }else{
                creatFireStorage(documentID: documentID)
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
}



extension PostViewController: UITextViewDelegate{
    
    @objc func keybordWillShow(_ notification: Notification) {
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
    
    
    @objc func keybordWillHide(_ notification: Notification) {
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















