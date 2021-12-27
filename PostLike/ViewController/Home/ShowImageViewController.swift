//
//  ShowImageViewController.swift
//  postLike
//
//  Created by taichi on 2021/02/15.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore



final class ShowImageViewController: UIViewController,UIGestureRecognizerDelegate {
    
    
    @IBOutlet private weak var bluredImage: UIImageView!
    @IBOutlet private weak var userImage: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var userName: UILabel!
    @IBOutlet private weak var imageScrollView: UIScrollView!
    @IBOutlet private var panGesture: UIPanGestureRecognizer!
    @IBOutlet private weak var backView: UIView!
    @IBOutlet private weak var personImage: UIImageView!
    @IBOutlet private weak var topView: UIView!
    
    
    
    
    
    var passedMedia = Array<String>()
    var passedUid = String()
    var passedUserName = String()
    var passedText = String()
    var passedUserImage = String()
    var passedRoomID = String()
    var passedDocumentID = String()
    private var contentInfo:Contents?
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setContents()
        createScrollView()
        pasteImage()
        self.view.addGestureRecognizer(panGesture)
        panGesture.delegate = self
        
        let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tapGesture.delegate = self
        self.imageScrollView.addGestureRecognizer(tapGesture)
    }
    
    
    
    
    
    
    private func setContents(){
        self.userImage.layer.cornerRadius = 19
        if passedUserImage != "" {
            self.userImage.sd_setImage(with: URL(string: passedUserImage), completed: nil)
            personImage.image = UIImage()
        }else{
            personImage.image = UIImage(systemName: "person.fill")
        }
        self.userName.text = passedUserName
        self.textLabel.text = passedText
        self.bluredImage.sd_setImage(with: URL(string: self.passedMedia[0] ), completed: nil)
    }
    
    
    
    
    @objc private func tapped(_ sender:UITapGestureRecognizer){
        if backView.isHidden == false {
            backView.isHidden = true
            topView.isHidden = true
        }else{
            backView.isHidden = false
            topView.isHidden = false
        }
    }
    
    
    
    
    
    private func createScrollView(){
        let viewHeight = self.view.frame.height - (self.view.safeAreaInsets.top + self.view.safeAreaInsets.bottom)
        imageScrollView.frame = CGRect(x: 0, y: self.view.safeAreaInsets.top, width: self.view.frame.width, height: viewHeight)
        imageScrollView.contentSize = CGSize(width: Int(view.frame.width)*passedMedia.count, height: Int(viewHeight))
        imageScrollView.isPagingEnabled = true
        imageScrollView.showsHorizontalScrollIndicator = false
        imageScrollView.backgroundColor = .clear
    }
    
    
    
    
    private func pasteImage(){
        if passedMedia.count == 1 {
            let fImageView = FlexibleHeightImageView()
            fImageView.imageUrl = passedMedia[0]
            fImageView.x = 0
            imageScrollView.addSubview(fImageView)
            
        } else if passedMedia.count == 2 {
            let firstImageView = FlexibleHeightImageView()
            firstImageView.imageUrl = passedMedia[0]
            firstImageView.x = 0
            imageScrollView.addSubview(firstImageView)
            
            let secondImageView = FlexibleHeightImageView()
            secondImageView.imageUrl = passedMedia[1]
            secondImageView.x = self.view.frame.width
            imageScrollView.addSubview(secondImageView)
        }
    }
    
    
    
    
    
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    
    
    
    
    @IBAction func dragDown(_ sender: UIPanGestureRecognizer) {
        
        let move:CGPoint = panGesture.translation(in: self.imageScrollView)
        
        if self.imageScrollView.isDragging == false {
            self.imageScrollView.center.y += move.y
        }
        
        if self.imageScrollView.frame.origin.y != 0 {
            self.imageScrollView.isScrollEnabled = false
        }
        
        if panGesture.state == .ended  {
            self.imageScrollView.isScrollEnabled = true
            if panGesture.velocity(in: self.imageScrollView).y >= 1000 && self.imageScrollView.frame.origin.y >= 50 {
                self.dismiss(animated: true, completion: nil)
            }else{
                UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCurlUp, animations: {
                    self.imageScrollView.frame.origin.y = 0
                    
                }, completion: { (finished: Bool) in
                    self.backView.alpha = 1.0
                })
            }
        }
        panGesture.velocity(in: self.imageScrollView)
        panGesture.setTranslation(CGPoint.zero, in: self.imageScrollView)
    }
    
    
    

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
    
}
