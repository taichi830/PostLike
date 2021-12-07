//
//  PostViewController.swift
//  postLike
//
//  Created by taichi on 2020/12/27.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import DKImagePickerController

class PostView2Controller: UIViewController,UITableViewDelegate,UITableViewDataSource,UITextViewDelegate{

    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var backView2: UIView!
    @IBOutlet weak var photoTableView: UITableView!
    @IBOutlet weak var backView: UIView!
    
    
    
    var photoArray:[UIImage] = []
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoTableView.delegate = self
        photoTableView.dataSource = self
        textView.delegate = self
        postButton.layer.cornerRadius = 5
        backView.layer.cornerRadius = 10
        backView2.layer.cornerRadius = 10
        
        textView.text = "文章を書く"
        textView.textColor = UIColor.gray
        
        
        textView.translatesAutoresizingMaskIntoConstraints = true
        
        
        
        }
    
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func albumButton(_ sender: Any) {

        let pickerController = DKImagePickerController()
        pickerController.maxSelectableCount = 3
        pickerController.sourceType = .photo
        pickerController.showsCancelButton = true
        pickerController.didSelectAssets = {(assets: [DKAsset]) in
        for asset in assets {
            asset.fetchFullScreenImage(completeBlock: { (image, info) in
                Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(PostViewController.timerUpdate), userInfo: nil, repeats: false)
                self.photoArray.append(image!)
                })
            }
        }
        
        self.present(pickerController, animated: true, completion: nil)
        
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photoArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = photoTableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let contentImageView = cell.viewWithTag(1) as! UIImageView
        contentImageView.image = photoArray[indexPath.row]
        print(photoArray[indexPath.row])
        contentImageView.layer.cornerRadius = 10
       
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 237
    }

    @objc func timerUpdate() {
        photoTableView.reloadData()
     }
    
    func textViewDidBeginEditing(_: UITextView) {
        textView.text = ""
        textView.textColor = .black
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       
            textView.resignFirstResponder()
    }
    
    
    




}
    
    
    
    
    
    
    

    

