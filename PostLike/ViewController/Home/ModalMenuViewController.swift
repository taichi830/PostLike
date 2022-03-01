//
//  ModalMenuViewController.swift
//  PostLike
//
//  Created by taichi on 2021/10/26.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseDynamicLinks


enum ItemType {
    case mute
    case block
    case cancel
    case share
    case report
    case exit
    case deletePost
    case deleteRoom
}


struct Menu {
    let type: ModalType
    let item: [Item]
}

struct Item {
    let title: String
    let imageUrl: String
    let type: ItemType
}



struct MenuViewModel {
    var items = PublishSubject<[Menu]>()
    
    func fetchItems() {
        let menu = [
            Menu(type: .post,
                 item: [
                    Item(title: "投稿を報告・ミュートする", imageUrl: "square.slash", type: .mute),
                    Item(title: "ユーザーを報告・ブロックする", imageUrl: "person", type: .block),
                    Item(title: "キャンセル", imageUrl: "xmark", type: .cancel)
                 ]),
            Menu(type: .room,
                 item: [
                    Item(title: "シェアする", imageUrl: "square.and.arrow.up", type: .share),
                    Item(title: "ルームを報告する", imageUrl: "flag", type: .report),
                    Item(title: "キャンセル", imageUrl: "xmark", type: .cancel)
                 ]),
            Menu(type: .exit,
                 item: [
                    Item(title: "ルームを退出する", imageUrl: "arrowshape.turn.up.right", type: .exit),
                    Item(title: "キャンセル", imageUrl: "xmark", type: .cancel)
                 ]),
            Menu(type: .delete,
                 item: [
                    Item(title: "投稿を削除する", imageUrl: "trash", type: .deletePost),
                    Item(title: "キャンセル", imageUrl: "xmark", type: .cancel)
                 ]),
            Menu(type: .moderator,
                 item: [
                    Item(title: "ルームを退出する", imageUrl: "arrowshape.turn.up.right", type: .exit),
                    Item(title: "ルームを削除する", imageUrl: "trash", type: .deleteRoom),
                    Item(title: "キャンセル", imageUrl: "xmark", type: .cancel)
                 ])
        ]
        
        items.onNext(menu)
        items.onCompleted()
    }
}


final class ModalMenuViewController: UIViewController{
    
    var passedDocumentID = String()
    var passedRoomID = String()
    var passedUid = String()
    var passedViewController = UIViewController()
    var passedType = String()
    var passedRoomName = String()
    var passedRoomImageUrl = String()
    var passedRoomIntro = String()
    var passedRoomImage = UIImage()
    var passedImageUrl = [String]()
    var passedRoomInfo = Room(dic: [:])
    var passedModalType = ModalType(rawValue: "")
    var passedContent = Contents(dic: [:])
    weak var deletePostDelegate:DeletePostDelegate?
    weak var exitRoomDelegate:ExitRoomDelegate?
    private let viewModel = MenuViewModel()
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
        
        if passedType == ModalType.exit.rawValue || passedType == ModalType.delete.rawValue {
            backViewHeightConstraint.constant = 160
        }
        setupTableView(passedType: passedModalType!)
    }
    
    
    @objc private func viewDidTouch(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    
    private func showActivityViewController(){
        
        var components = URLComponents()
        components.scheme = "https"
        #if DEBUG
        components.host = "postliketest.page.link"
        #else
        components.host = "postlike.page.link"
        #endif
        components.path = "/rooms"
        
        let roomIDQueryItem = URLQueryItem(name: "roomID", value: passedRoomID)
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
    
    
    
    func setupTableView(passedType: ModalType) {
        
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
        
        menuTableView.rx.modelSelected(Item.self).bind { [weak self] item in
            switch item.type {
            case .cancel:
                self?.dismiss(animated: true,completion: nil)
                
            case .mute:
                let reportVC = self?.storyboard?.instantiateViewController(withIdentifier: "report") as! ReportViewController
                reportVC.passedContent = self!.passedContent
                reportVC.reportType = .post
                reportVC.removeContentsDelegate = self?.passedViewController as? RemoveContentsDelegate
                self?.present(reportVC, animated: true,completion: nil)
                
            case .block:
                let reportVC = self?.storyboard?.instantiateViewController(withIdentifier: "report") as! ReportViewController
                reportVC.passedContent = self!.passedContent
                reportVC.reportType = .user
                reportVC.removeContentsDelegate = self?.passedViewController as? RemoveContentsDelegate
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
                    self?.deletePostDelegate?.deletePostBatch(documentID: self?.passedDocumentID ?? "", imageUrl: self?.passedImageUrl ?? [""])
                    self?.dismiss(animated: true,completion: nil)
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
        
        menuTableView.isScrollEnabled = false
        menuTableView.rowHeight = 60
        
        
        viewModel.fetchItems()

    }
    
    
    
    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        switch passedType {
//        case ModalType.post.rawValue:
//            return 3
//
//        case ModalType.room.rawValue:
//            return 3
//
//        case ModalType.exit.rawValue:
//            return 2
//
//        case ModalType.delete.rawValue:
//            return 2
//
//        case ModalType.moderator.rawValue:
//            return 3
//
//        default:
//            break
//        }
//
//        return Int()
//
//    }
//
//
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = menuTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
//        let imageView = cell.viewWithTag(1) as! UIImageView
//        let label = cell.viewWithTag(2) as! UILabel
//
//        switch passedType {
//        case ModalType.post.rawValue:
//            CommonModal.shared.items(type: .post, label: label, imageView: imageView, row: indexPath.row)
//
//        case ModalType.room.rawValue:
//            CommonModal.shared.items(type: .room, label: label, imageView: imageView, row: indexPath.row)
//
//        case ModalType.exit.rawValue:
//            CommonModal.shared.items(type: .exit, label: label, imageView: imageView, row: indexPath.row)
//
//        case ModalType.exit.rawValue:
//            CommonModal.shared.items(type: .exit, label: label, imageView: imageView, row: indexPath.row)
//
//        case ModalType.delete.rawValue:
//            CommonModal.shared.items(type: .delete, label: label, imageView: imageView, row: indexPath.row)
//
//        case ModalType.moderator.rawValue:
//            CommonModal.shared.items(type: .moderator, label: label, imageView: imageView, row: indexPath.row)
//
//        default: break
//        }
//        return cell
//    }
//
//
//
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 60
//    }
//
//
//
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        switch passedType {
//        case ModalType.post.rawValue:
//            if indexPath.row == 0 {
//                let reportVC = storyboard?.instantiateViewController(withIdentifier: "report") as! ReportViewController
//                reportVC.passedDocumentID = passedDocumentID
//                reportVC.passedRoomID = passedRoomID
//                reportVC.passedUid = passedUid
//                reportVC.reportType = ReportType.post.rawValue
//                reportVC.removeContentsDelegate = passedViewController as? RemoveContentsDelegate
//                present(reportVC, animated: true,completion: nil)
//
//            }else if indexPath.row == 1 {
//                let reportVC = storyboard?.instantiateViewController(withIdentifier: "report") as! ReportViewController
//                reportVC.passedDocumentID = passedDocumentID
//                reportVC.passedRoomID = passedRoomID
//                reportVC.passedUid = passedUid
//                reportVC.reportType = ReportType.user.rawValue
//                reportVC.removeContentsDelegate = passedViewController as? RemoveContentsDelegate
//                present(reportVC, animated: true, completion: nil)
//
//            }else{
//                dismiss(animated: true, completion: nil)
//            }
//
//        case ModalType.room.rawValue:
//            if indexPath.row == 0 {
//                self.showActivityViewController()
//
//            }else if indexPath.row == 1 {
//                let reportVC = storyboard?.instantiateViewController(withIdentifier: "report") as! ReportViewController
//                reportVC.passedDocumentID = passedDocumentID
//                reportVC.passedRoomID = passedRoomID
//                reportVC.passedUid = passedUid
//                reportVC.reportType = ReportType.room.rawValue
//                present(reportVC, animated: true, completion: nil)
//            }else{
//                dismiss(animated: true, completion: nil)
//            }
//
//        case ModalType.exit.rawValue:
//            if indexPath.row == 0 {
//                let alert = UIAlertController(title: "ルームを退出", message: "ルームから退出してよろしいですか？", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "はい", style: .default, handler: { _ in
//                    self.exitRoomDelegate?.exitRoomBatch()
//                    self.dismiss(animated: true, completion: nil)
//                }))
//                alert.addAction(UIAlertAction(title: "いいえ", style: .cancel, handler: nil))
//                self.present(alert, animated: true, completion: nil)
//
//            }else if indexPath.row == 1 {
//                dismiss(animated: true, completion: nil)
//            }
//
//        case ModalType.delete.rawValue:
//            if indexPath.row == 0 {
//                let alert = UIAlertController(title: "投稿を削除", message: "本当に投稿を削除してもよろしいですか？", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "はい", style: .default, handler: { _ in
//                    self.deletePostDelegate?.deletePostBatch(documentID: self.passedDocumentID, imageUrl: self.passedImageUrl)
//                    self.dismiss(animated: true,completion: nil)
//                }))
//                alert.addAction(UIAlertAction(title: "いいえ", style: .cancel, handler: nil))
//                self.present(alert, animated: true, completion: nil)
//
//            }else if indexPath.row == 1 {
//                dismiss(animated: true, completion: nil)
//            }
//
//        case ModalType.moderator.rawValue:
//            if indexPath.row == 0 {
//                let alert = UIAlertController(title: "ルームを退出", message: "ルームから退出してよろしいですか？", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "はい", style: .default, handler: { _ in
//                    self.exitRoomDelegate?.exitRoomBatch()
//                    self.dismiss(animated: true,completion: nil)
//                }))
//                alert.addAction(UIAlertAction(title: "いいえ", style: .cancel, handler: nil))
//                self.present(alert, animated: true, completion: nil)
//
//            }else if indexPath.row == 1 {
//                let storyboard = UIStoryboard.init(name: "Profile", bundle: nil)
//                let deleteAlertVC = storyboard.instantiateViewController(withIdentifier: "deleteAlert") as! DeleteRoomViewController
//                deleteAlertVC.modalPresentationStyle = .custom
//                deleteAlertVC.transitioningDelegate = passedViewController as? UIViewControllerTransitioningDelegate
//                deleteAlertVC.passedRoomID = passedRoomID
//                deleteAlertVC.deleteRoomDelegate = passedViewController as? DeleteRoomDelegate
//                present(deleteAlertVC, animated: true, completion: nil)
//            }else {
//                dismiss(animated: true,completion: nil)
//            }
//
//        default:
//            return
//        }
//
//    }
    
    
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



