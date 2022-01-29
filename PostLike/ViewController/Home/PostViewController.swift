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

final class PostViewController: UIViewController{
    
    
    
    @IBOutlet private weak var textView: LinkTextView!
    @IBOutlet private weak var photoTableView: UITableView!
    @IBOutlet private weak var buttonView: UIView!
    @IBOutlet private weak var postButton: UIButton!
    @IBOutlet private weak var postTitleLabel: UILabel!
    @IBOutlet private weak var profileImage: UIImageView!
    @IBOutlet private weak var profileName: UILabel!
    @IBOutlet private weak var postContentView: UIView!
    @IBOutlet private weak var personImage: UIImageView!
    @IBOutlet private weak var showAlubumButton: UIView!
    @IBOutlet private weak var backButton: UIButton!
    
    
    
    private var photoArray:[UIImage] = []
    private var photoUrl :[String] = []
    private var postViewModel:PostViewModel!
    private let model = PostDefaultAPI()
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
        
        postButton.layer.cornerRadius = 20
        postButton.backgroundColor = .systemGray4
        
        profileImage.layer.cornerRadius = 18
        if passedUserImageUrl != "" {
            profileImage.sd_setImage(with: URL(string: passedUserImageUrl), completed: nil)
            personImage.image = UIImage()
        }
        
        profileName.text = passedUserName
        
        setupBinds()
        
        
    }
    
    
    
    

    
    
    private func setupBinds() {
        self.postViewModel = PostViewModel(input: (postButtonTap: postButton.rx.tap.asSignal(), text: textView.rx.text.orEmpty.asDriver()), userName: passedUserName, userImage: passedUserImageUrl, passedUid: passedHostUid, roomID: passedDocumentID, postAPI: model)
        
        textViewDidChange()
        postValidateCheck()
        didTapPostButton()
        didTapAlubumButton()
        didTapBackButton()
        keybordNotifications()
        setUpTableView()
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
    
    
    
    
    
    
    
    private func didTapPostButton() {
        
        //投稿完了通知
        postViewModel.postedDriver
            .drive { [weak self] bool in
                switch bool {
                case true:
                    self?.dismiss(animated: true, completion: nil)
                case false:
                    print("false!!!!!!!!!!!!!")
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
    
    
    
    
    
    
    
    
    private func showAlbum(){
        let pickerController = DKImagePickerController()
        pickerController.maxSelectableCount = 2
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
        let tapGesture = UITapGestureRecognizer()
        tapGesture.rx.event.subscribe { [weak self] _ in
            self?.showAlbum()
        }
        .disposed(by: disposeBag)
        
        showAlubumButton.addGestureRecognizer(tapGesture)
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
//            dkAsset.fetchFullScreenImage { image, info in
//
//            }
//
            cell.deleteButton.rx.tap.subscribe { [weak self] _ in
                cell.didTapDeleteButton(viewModel: self!.postViewModel)
            }
            .disposed(by: self.disposeBag)
            
        }
        .disposed(by: disposeBag)
    }
    
    
    
    
 
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if photoTableView.isDragging == true {
            textView.resignFirstResponder()
        }
    }
  
 
}















