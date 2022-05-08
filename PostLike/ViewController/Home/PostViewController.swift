//
//  PostViewController.swift
//  postLike
//
//  Created by taichi on 2020/12/27.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import DKImagePickerController
import RxSwift
import RxCocoa

final class PostViewController: UIViewController{
    
    
    
    
    @IBOutlet private weak var postButton: UIButton! {
        didSet {
            postButton.layer.cornerRadius = 20
            postButton.backgroundColor = .systemGray4
        }
    }
    
    @IBOutlet private weak var profileImage: UIImageView! {
        didSet {
            profileImage.layer.cornerRadius = profileImage.frame.size.height/2
        }
    }
    
    @IBOutlet private weak var showAlbumButton: UIButton! {
        didSet {
            showAlbumButton.setTitle("写真を投稿する", for: .normal)
            showAlbumButton.setImage(UIImage(systemName: "photo"), for: .normal)
            showAlbumButton.tintColor = .systemGray4
            showAlbumButton.imageView?.contentMode = .scaleToFill
            showAlbumButton.contentHorizontalAlignment = .fill
            showAlbumButton.contentVerticalAlignment = .fill
            showAlbumButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 15)
            showAlbumButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
            
        }
    }
    @IBOutlet private weak var textView: LinkTextView!
    @IBOutlet private weak var buttonView: UIView!
    @IBOutlet private weak var photoTableView: UITableView!
    @IBOutlet private weak var postTitleLabel: UILabel!
    @IBOutlet private weak var profileName: UILabel!
    @IBOutlet private weak var postContentView: UIView!
    @IBOutlet private weak var backButton: UIButton!
    
    
    
    
    private var postViewModel:PostViewModel!
    private let disposeBag = DisposeBag()
    var passedRoomTitle = String()
    var passedDocumentID = String()
    var passedUserImageUrl = String()
    var passedUserName = String()
    var passedHostUid = String()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.becomeFirstResponder()
        
        buttonView.frame.size.width = self.view.frame.size.width
        
        profileImage.setImage(imageUrl: passedUserImageUrl)
        
        profileName.text = passedUserName
        
        setupBinds()
        
    }
    
    
    
    
    private func setupBinds() {
        // PostViewModelを初期化
        self.postViewModel = PostViewModel(input: (postButtonTap: postButton.rx.tap.asSignal(), albumButtonTap: showAlbumButton.rx.tap.asSignal()), userName: passedUserName, userImage: passedUserImageUrl, passedUid: passedHostUid, roomID: passedDocumentID, postAPI: PostDefaultAPI())
        
        
        // 戻るボタンの処理
        backButton.rx.tap.subscribe { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        .disposed(by: disposeBag)
        
        
        // 投稿文をviewModel.inputs.textにバインド
        textView.rx.text.orEmpty
            .bind(to: postViewModel.inputs.text)
            .disposed(by: disposeBag)
        
        
        // urlを識別できるようにする
        textView.rx.didChange.subscribe { [weak self] _ in
            if self?.textView.markedTextRange == nil{
                self?.textView.setText(text: self?.textView.text ?? "", urls: self?.textView.text.urlsFromRegexs ?? [""])
            }
        }
        .disposed(by: disposeBag)
        
        
        // 現在の写真の数が2枚より少なかったらAlbumButtonを押せるようにする
        postViewModel.outputs.isAlbumButtonEnabled
            .drive { [weak self] bool in
                self?.showAlbumButton.isEnabled = bool
            }
            .disposed(by: disposeBag)
        
        
        // 現在の写真の数をshowAlbumメソッドに通知
        postViewModel.outputs.imageCountDriver
            .drive { [weak self] count in
                self?.showAlbum(count: count)
            }
            .disposed(by: disposeBag)
        
        
        // 投稿文または写真があれば投稿できるようにする
        postViewModel.outputs.isPostButtonEnabled
            .drive { [weak self] bool in
                self?.postButton.isEnabled = bool
                self?.postButton.backgroundColor = bool ? .red : .systemGray4
            }
            .disposed(by: disposeBag)
        
        
        // photoTableViewをドラッグしたらtextViewを閉じる
        photoTableView.rx.didEndDragging.subscribe { [weak self] _ in
            self?.textView.resignFirstResponder()
        }
        .disposed(by: disposeBag)
        
        
        // 投稿ボタンタップ時indicatorを回す
        postButton.rx.tap.subscribe { [weak self] _ in
            self?.startIndicator()
        }
        .disposed(by: disposeBag)
        
        
        // 投稿完了通知
        postViewModel.outputs.isPosted
            .drive { [weak self] bool in
                if bool == true {
                    self?.dismiss(animated: true) {
                        self?.postViewModel.fetchMyLatestPost(feedListner: GetDefaultPosts(), roomID: self?.passedDocumentID ?? "")
                    }
                }
            }
            .disposed(by: disposeBag)
        
        
        // 投稿失敗時にアラートを表示する
        postViewModel.outputs.postError
            .drive ( self.rx.showErrorAlert )
            .disposed(by: disposeBag)
        
        
        keybordNotifications()
        setUpTableView()
        tapGesture()
        
        
    }
    
    
    
    
    
    private func setUpTableView() {
        photoTableView.register(UINib(nibName: "PostPreViewTableViewCell", bundle: nil), forCellReuseIdentifier: "PostPreViewTableViewCell")
        postViewModel.outputs.outputPhotos.drive(photoTableView.rx.items(cellIdentifier: "PostPreViewTableViewCell", cellType: PostPreViewTableViewCell.self)){ row,image,cell in
            
            cell.setUpCell(image: image)
            
            cell.deleteButton.rx.tap.subscribe { [weak self] _ in
                guard let `self` = self else { return }
                cell.didTapDeleteButton(viewModel: self.postViewModel)
            }
            .disposed(by: self.disposeBag)
        }
        .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    
    private func showAlbum(count:Int){
        let pickerController = DKImagePickerController()
        pickerController.maxSelectableCount = 2 - count
        pickerController.sourceType = .photo
        pickerController.assetType = .allPhotos
        pickerController.allowSelectAll = true
        pickerController.showsCancelButton = true
        pickerController.didSelectAssets = {(assets: [DKAsset]) in
            for asset in assets {
                asset.fetchFullScreenImage { image, info in
                    if let image = image {
                        var item = self.postViewModel.inputs.photos.value
                        item.append(image)
                        self.postViewModel.inputs.photos.accept(item)
                    }
                }
            }
        }
        pickerController.modalPresentationStyle = .fullScreen
        pickerController.UIDelegate = CustomUIDelegate()
        self.present(pickerController, animated: true, completion: nil)
    }
    
    
    
    
    
    
    
    private func keybordNotifications() {
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification, object: nil)
            .subscribe({ notificationEvent in
                guard let notification = notificationEvent.element else { return }
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
            })
            .disposed(by: disposeBag)
        
        
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification, object: nil)
            .subscribe({ [weak self] _ in
                guard let `self` = self else { return }
                self.buttonView.frame.origin.y = self.view.frame.size.height - (self.buttonView.frame.size.height + self.view.safeAreaInsets.bottom)
            })
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    private func tapGesture() {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.rx.event
            .subscribe { [weak self] _ in
                self?.textView.resignFirstResponder()
            }
            .disposed(by: disposeBag)
        view.addGestureRecognizer(tapGesture)
    }
    
    
    
    
    
    
    
    
}















