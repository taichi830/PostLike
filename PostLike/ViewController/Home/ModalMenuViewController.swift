//
//  ModalMenuViewController.swift
//  PostLike
//
//  Created by taichi on 2021/10/26.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import RxSwift
import Firebase
import FirebaseFirestore
import FirebaseDynamicLinks


final class ModalMenuViewController: UIViewController{
    

    var passedViewController = UIViewController()
    var passedRoomImage = UIImage()
    var passedModerator = String()
    var passedRoomInfo = Room(dic: [:])
    var passedModalType = ModalType(rawValue: "")
    var passedContent = Contents(dic: [:])
//    weak var deletePostDelegate:DeletePostDelegate?
    weak var exitRoomDelegate:ExitRoomDelegate?
    private let viewModel = ModalViewModel()
    private let disposeBag = DisposeBag()
    
    
    
    @IBOutlet private weak var menuTableView: UITableView!
    @IBOutlet private weak var backViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var clearView: UIView!
    @IBOutlet private weak var backView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.transitioningDelegate = self
        clearView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.viewDidTouch)))
        backView.layer.cornerRadius = 10
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if passedModalType == .exit || passedModalType == .delete {
            backViewHeightConstraint.constant = 160
        }
        setupTableView(passedType: passedModalType!)
        didSelectItem()
    }
    
    
    @objc private func viewDidTouch(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    
    private func setupTableView(passedType: ModalType) {
        viewModel.items.map{ menus -> [Item] in
            let filter = menus.filter { menu in
                menu.type == passedType
            }
            return filter[0].item
        }
        .bind(to: menuTableView.rx.items(cellIdentifier: "cell")) { (row,item,cell) in
            cell.imageView?.tintColor = .label
            cell.imageView?.image = UIImage(systemName: item.imageUrl)
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            cell.textLabel?.text = item.title
        }
        .disposed(by: disposeBag)
        
        menuTableView.isScrollEnabled = false
        menuTableView.rowHeight = 60
        viewModel.fetchItems()
    }
    
    
    private func didSelectItem() {
        menuTableView.rx.modelSelected(Item.self).bind { [weak self] item in
            switch item.type {
            case .cancel:
                self?.dismiss(animated: true,completion: nil)
                
            case .mute:
                let reportVC = self?.storyboard?.instantiateViewController(withIdentifier: "report") as! ReportViewController
                reportVC.passedContent = self!.passedContent
                reportVC.reportType = .post
                self?.present(reportVC, animated: true,completion: nil)
                
            case .block:
                let reportVC = self?.storyboard?.instantiateViewController(withIdentifier: "report") as! ReportViewController
                reportVC.passedContent = self!.passedContent
                reportVC.reportType = .user
                self?.present(reportVC, animated: true, completion: nil)
                
            case .share:
                self?.showActivityViewController()
                
            case .report:
                let reportVC = self?.storyboard?.instantiateViewController(withIdentifier: "report") as! ReportViewController
                reportVC.passedContent = self?.passedContent ?? Contents(dic: [:])
                reportVC.passedRoomInfo = self?.passedRoomInfo ?? Room(dic: [:])
                reportVC.reportType = .room
                self?.present(reportVC, animated: true, completion: nil)
                
            case .exit:
                let alert = UIAlertController(title: "ルームを退出", message: "ルームから退出してよろしいですか？", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "はい", style: .default, handler: { _ in
                    self?.exitRoomDelegate?.exitRoomBatch()
                    self?.dismiss(animated: true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "いいえ", style: .cancel, handler: nil))
                self?.present(alert, animated: true, completion: nil)
                
            case .deletePost:
                let alert = UIAlertController(title: "投稿を削除", message: "本当に投稿を削除してもよろしいですか？", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "はい", style: .default, handler: { _ in
                    self?.deletePostBatch(documentID: self?.passedContent.documentID ?? "", imageUrl: self?.passedContent.mediaArray ?? [""])
                    self?.dismiss(animated: true,completion: {
                        LatestContentsSubject.shared.deletedContents.accept(self!.passedContent)
                    })
                }))
                alert.addAction(UIAlertAction(title: "いいえ", style: .cancel, handler: nil))
                self?.present(alert, animated: true, completion: nil)
                
            case .deleteRoom:
                let storyboard = UIStoryboard.init(name: "Profile", bundle: nil)
                let deleteAlertVC = storyboard.instantiateViewController(withIdentifier: "deleteAlert") as! DeleteRoomViewController
                deleteAlertVC.modalPresentationStyle = .custom
                deleteAlertVC.transitioningDelegate = self?.passedViewController as? UIViewControllerTransitioningDelegate
                deleteAlertVC.passedRoomID = self?.passedContent.roomID ?? ""
                deleteAlertVC.deleteRoomDelegate = self?.passedViewController as? DeleteRoomDelegate
                self?.present(deleteAlertVC, animated: true, completion: nil)
            }
        }
        .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    
    
}





extension ModalMenuViewController {
    //投稿を削除
    func deletePostBatch(documentID:String,imageUrl:[String]){
        let uid = Auth.auth().currentUser!.uid
        let batch = Firestore.firestore().batch()
        Firestore.decreasePostCount(roomID: passedContent.roomID, batch: batch)
        Firestore.decreaseRoomPostCount(roomID: passedContent.roomID, batch: batch)
        Firestore.deletePosts(roomID: passedContent.roomID, documentID: documentID, batch: batch)
        Firestore.deleteModeratorPosts(uid: uid, moderatorUid: passedModerator,roomID: passedContent.roomID, documentID: documentID, batch: batch)
        if passedContent.mediaArray[0] != "" {
            Firestore.deleteMediaPosts(roomID: passedContent.roomID, documentID: documentID, batch: batch)
        }
        batch.commit { err in
            if let err = err {
                print("false\(err)")
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }
            if imageUrl[0] != "" {
                Storage.deleteStrageFile(imageUrl: imageUrl)
            }
        }
    }
}


extension ModalMenuViewController {
    //activityViewを表示
    private func showActivityViewController(){
        var components = URLComponents()
        components.scheme = "https"
        #if DEBUG
        components.host = "postliketest.page.link"
        #else
        components.host = "postlike.page.link"
        #endif
        components.path = "/rooms"
        
        let roomIDQueryItem = URLQueryItem(name: "roomID", value: passedContent.roomID)
        components.queryItems = [roomIDQueryItem]
        
        guard let link = components.url else {return}
        #if DEBUG
        let dynamicLinksDomainURIPrefix = "https://postliketest.page.link"
        #else
        let dynamicLinksDomainURIPrefix = "https://postlike.page.link"
        #endif
        
        guard let shareLink = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomainURIPrefix) else {return}
        
        if let bundleID = Bundle.main.bundleIdentifier {
            shareLink.iOSParameters = DynamicLinkIOSParameters(bundleID: bundleID)
        }
        shareLink.iOSParameters?.appStoreID = "1584149456"
        
        shareLink.androidParameters = .none
        shareLink.androidParameters?.minimumVersion = .zero
        
        shareLink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        shareLink.socialMetaTagParameters?.title = passedRoomInfo.roomName
        shareLink.socialMetaTagParameters?.descriptionText = passedRoomInfo.roomIntro
        shareLink.socialMetaTagParameters?.imageURL = URL(string: passedRoomInfo.roomImage)
        shareLink.shorten { url, warnings, err in
            if err != nil {
                return
            }else{
                if let warnings = warnings {
                    for warning in warnings {
                        print("\(warning)")
                    }
                }
                guard let url = url else {return}
                let activityItems: [Any] = [url,ShareActivitySource(url: url, roomName: self.passedRoomInfo.roomName, roomImage: self.passedRoomImage)]
                let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: .none)
                self.present(activityViewController, animated: true, completion: nil)
            }
        }
        
    }
}



extension ModalMenuViewController:UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentModalViewController(presentedViewController: presented, presenting: presenting)
    }
}





import LinkPresentation

final class ShareActivitySource:NSObject, UIActivityItemSource{
    
    private let linkMetadata:LPLinkMetadata
    
    init(url: URL,roomName:String,roomImage:UIImage) {
        linkMetadata = LPLinkMetadata()
        super.init()
        
        // 完全な情報が取得できるまでプレビューに表示しておく仮の情報を入れておく
        linkMetadata.title = roomName
        linkMetadata.url = url
        linkMetadata.iconProvider = NSItemProvider(object: roomImage)
    }
    
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return nil
    }
    
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        return linkMetadata
    }
    
    
    
}



