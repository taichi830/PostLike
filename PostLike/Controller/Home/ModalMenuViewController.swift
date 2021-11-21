//
//  ModalMenuViewController.swift
//  PostLike
//
//  Created by taichi on 2021/10/26.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseDynamicLinks

class ModalMenuViewController: UIViewController,UITableViewDelegate,UITableViewDataSource{
    
    
    private let element = [
        (type:"post",text:["投稿を報告・ミュートする","ユーザーを報告・ブロックする","キャンセル"],image:["square.slash","person","xmark"]),
        (type:"room",text:["シェアする","ルームを報告する","キャンセル"],image:["square.and.arrow.up","flag","xmark"]),
        (type:"exit",text:["ルームを退出する","ルームを削除する","キャンセル"],image:["arrowshape.turn.up.right","trash","xmark"])
    ]
    var passedDocumentID = String()
    var passedRoomID = String()
    var passedUid = String()
    var passedViewController = UIViewController()
    var passedType = String()
    var passedRoomName = String()
    var passedRoomImageUrl = String()
    var passedRoomIntro = String()
    var passedRoomImage = UIImage()
    
    @IBOutlet weak var menuTableView: UITableView!
    @IBOutlet weak var clearView: UIView!
    @IBOutlet weak var backView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuTableView.delegate = self
        menuTableView.dataSource = self
        self.transitioningDelegate = self
        backView.layer.cornerRadius = 10
        self.clearView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.viewDidTouch)))
    }
    
    
    @objc func viewDidTouch(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return element[0].text.count
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = menuTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let imageView = cell.viewWithTag(1) as! UIImageView
        let label = cell.viewWithTag(2) as! UILabel
        
        switch passedType {
        case "post":
            imageView.image = UIImage(systemName: element[0].image[indexPath.row])
            label.text = element[0].text[indexPath.row]
        case "room":
            imageView.image = UIImage(systemName: element[1].image[indexPath.row])
            label.text = element[1].text[indexPath.row]
        case "exit":
            imageView.image = UIImage(systemName: element[2].image[indexPath.row])
            label.text = element[1].text[indexPath.row]
        default: break
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch passedType {
        case "post":
            if indexPath.row == 0 {
                let reportVC = storyboard?.instantiateViewController(withIdentifier: "report") as! ReportViewController
                reportVC.passedDocumentID = passedDocumentID
                reportVC.passedRoomID = passedRoomID
                reportVC.passedUid = passedUid
                reportVC.reporttype = "post"
                reportVC.titleTableViewDelegate = passedViewController as? RemoveContentsDelegate
                present(reportVC, animated: true,completion: nil)
            }else if indexPath.row == 1 {
                let reportVC = storyboard?.instantiateViewController(withIdentifier: "report") as! ReportViewController
                reportVC.passedDocumentID = passedDocumentID
                reportVC.passedRoomID = passedRoomID
                reportVC.passedUid = passedUid
                reportVC.reporttype = "user"
                reportVC.titleTableViewDelegate = passedViewController as? RemoveContentsDelegate
                present(reportVC, animated: true, completion: nil)
            }else{
                dismiss(animated: true, completion: nil)
            }
        case "room":
            if indexPath.row == 0 {
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
                    shareLink.iOSParameters?.appStoreID = "1584149456"
                    
                    shareLink.androidParameters = .none
                    shareLink.androidParameters?.minimumVersion = .zero
                    
                    shareLink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
                    shareLink.socialMetaTagParameters?.title = passedRoomName
                    shareLink.socialMetaTagParameters?.descriptionText = passedRoomIntro
                    shareLink.socialMetaTagParameters?.imageURL = URL(string: passedRoomImageUrl)
                }
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
                        let activityItems: [Any] = [url,ShareActivitySource(url, self.passedRoomName, self.passedRoomImage)]
                        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: .none)
                        self.present(activityViewController, animated: true, completion: nil)
                    }
                }
            }else if indexPath.row == 1 {
                let storyboard = UIStoryboard(name: "Search", bundle: nil)
                let reportRoomVC = storyboard.instantiateViewController(identifier: "reportRoom") as! ReportRoomViewController
                reportRoomVC.passedRoomID = passedRoomID
                present(reportRoomVC, animated: true, completion: nil)
            }else{
                dismiss(animated: true, completion: nil)
            }
        default:
            return
        }
        
    }
    
    
}

extension ModalMenuViewController:UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        
        return PresentModalViewController(presentedViewController: presented, presenting: presenting)
        
    }
    
    
    
    
}


import LinkPresentation

class ShareActivitySource:NSObject, UIActivityItemSource{
    
    private let linkMetadata:LPLinkMetadata
    
    init(_ url: URL,_ roomName:String,_ roomImage:UIImage) {
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



