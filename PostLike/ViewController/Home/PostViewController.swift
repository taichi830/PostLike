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
    @IBOutlet private weak var personImage: UIImageView!
    @IBOutlet private weak var backButton: UIButton!
    
    
    
    
    private var photoArray:[UIImage] = []
    private var photoUrl :[String] = []
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
        
        if passedUserImageUrl != "" {
            profileImage.sd_setImage(with: URL(string: passedUserImageUrl), completed: nil)
            personImage.image = UIImage()
        }
        
        profileName.text = passedUserName
        
        setupBinds()
        
    }
    
    
    
    

    
    
    private func setupBinds() {
        self.postViewModel = PostViewModel(input: (postButtonTap: postButton.rx.tap.asSignal(), text: textView.rx.text.orEmpty.asDriver(), albumButtonTap: showAlbumButton.rx.tap.asSignal()), userName: passedUserName, userImage: passedUserImageUrl, passedUid: passedHostUid, roomID: passedDocumentID, postAPI: PostDefaultAPI())
        
        textViewDidChange()
        postValidateCheck()
        didTapPostButton()
        didTapAlubumButton()
        didTapBackButton()
        keybordNotifications()
        setUpTableView()
        tapGesture()
        didScrollTableView()
    }
    
    
    
    
    
    
    private func textViewDidChange() {
        textView.rx.didChange.subscribe { [weak self] _ in
            if self?.textView.markedTextRange == nil{
                self?.textView.setText(text: self?.textView.text ?? "", urls: self?.textView.text.urlsFromRegexs ?? [""])
            }
        }
        .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    
    
    private func postValidateCheck() {
        //投稿文または写真があれば投稿できるようにする
        postViewModel.validPostDriver
            .drive { [weak self] bool in
                self?.postButton.isEnabled = bool
                self?.postButton.backgroundColor = bool ? .red : .systemGray4
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    
    
    private func didScrollTableView() {
        photoTableView.rx.didEndDragging.subscribe { [weak self] _ in
            self?.textView.resignFirstResponder()
        }
        .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    
    private func didTapPostButton() {
        
        postButton.rx.tap.subscribe { [weak self] _ in
            self?.startIndicator()
        }
        .disposed(by: disposeBag)
        
        //投稿完了通知
        postViewModel.postedDriver
            .drive { [weak self] bool in
                switch bool {
                case true:
                    self?.dismissIndicator()
                    self?.dismiss(animated: true) {
                        self?.postViewModel.fetchMyLatestPost(feedListner: GetDefaultPosts(), roomID: self?.passedDocumentID ?? "")
                    }
                case false:
                    let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                        self?.dismissIndicator()
                    }
                    self?.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                }
                
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    
    
    private func didTapBackButton() {
        backButton.rx.tap.subscribe { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
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
                    if var item = try? self.postViewModel.photoArrayOutPut.value() {
                        item.append(image!)
                        self.postViewModel.photoArrayInPut.onNext(item)
                    }
                }
            }
        }
        pickerController.modalPresentationStyle = .fullScreen
        pickerController.UIDelegate = CustomUIDelegate()
        self.present(pickerController, animated: true, completion: nil)
    }
    
    
    
    
    
    
    
    
    private func didTapAlubumButton() {
        
        postViewModel.validAddImageDriver
            .drive { [weak self] bool in
                self?.showAlbumButton.isEnabled = bool
            }
            .disposed(by: disposeBag)
        
        postViewModel.imageCountDriver
            .drive { [weak self] count in
                self?.showAlbum(count: count)
            }
            .disposed(by: disposeBag)
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
                self!.buttonView.frame.origin.y = self!.view.frame.size.height - (self!.buttonView.frame.size.height+self!.view.safeAreaInsets.bottom)
            })
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    private func setUpTableView() {
        photoTableView.register(UINib(nibName: "PostPreViewTableViewCell", bundle: nil), forCellReuseIdentifier: "PostPreViewTableViewCell")
        postViewModel.photoArrayOutPut.bind(to: photoTableView.rx.items(cellIdentifier: "PostPreViewTableViewCell", cellType: PostPreViewTableViewCell.self)){ row,dkAsset,cell in
            
            cell.setUpCell(image: dkAsset)
            
            cell.deleteButton.rx.tap.subscribe { [weak self] _ in
                cell.didTapDeleteButton(viewModel: self!.postViewModel)
            }
            .disposed(by: self.disposeBag)
            
        }
        .disposed(by: disposeBag)
    }
    
    
    
    
 
    
    func tapGesture() {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.rx.event
            .subscribe { [weak self] _ in
                self?.textView.resignFirstResponder()
            }
            .disposed(by: disposeBag)
        view.addGestureRecognizer(tapGesture)
    }
  
 
}















