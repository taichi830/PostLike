//
//  EditAndPostViewController.swift
//  postLike
//
//  Created by taichi on 2020/10/05.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit

class EditViewController: UIViewController {

    
    var contrast:Float = 0
    var brightness:Float = 0
    var passedImage = UIImage()
    
   
    
    private var ciFilter:CIFilter!
    
    @IBOutlet weak var editImage: UIImageView!
    @IBOutlet weak var valueSlider: UISlider!
    @IBOutlet weak var valueSlider2: UISlider!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var valueLabel2: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editImage.image = passedImage
        
        guard let ciImage = passedImage.ciImage ?? CIImage(image: passedImage) else {return}
        
        valueSlider.maximumValue = 10
        valueSlider2.maximumValue = 10
        valueSlider.minimumValue = -10
        valueSlider2.minimumValue = -10
        valueSlider.value = 0
        valueSlider2.value = 0
        
        valueLabel.text = String(valueSlider.value)
        valueLabel2.text = String(valueSlider2.value)
        
        //CiFilterの作成
        ciFilter = CIFilter(name: "CIColorControls")
        //入力画像の設定
        ciFilter.setValue(ciImage, forKey: kCIInputImageKey)
        
        let navBar = UINavigationBar()
        
        navBar.frame = CGRect(x: 0, y: 49, width: view.frame.size.width, height: 50)
        
        let tabBar = UITabBar()
        
        tabBar.frame = CGRect(x: 0, y: 0, width: view.frame.size.height, height: 49)
        
        let navItem:UINavigationItem = UINavigationItem()
        
        navItem.rightBarButtonItem = UIBarButtonItem(title: "next", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.nextButton))
        
        navItem.leftBarButtonItem = UIBarButtonItem(title: "back", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.backButton))
        
        navBar.pushItem(navItem, animated: true)
        
        self.view.addSubview(navBar)
        self.view.addSubview(tabBar)
        
        
    }
    
    
    @IBAction func contrastChange(_ sender: UISlider) {
        valueLabel.text = String(sender.value)
        
        //コントラストの設定
        ciFilter.setValue(sender.value, forKey: kCIInputContrastKey)
        
        //FIlterの適応後
        if let filteredImage = ciFilter.outputImage {
            editImage.image = UIImage(ciImage: filteredImage)
        }
        
        
    }
    
    @IBAction func brightnessChange(_ sender: UISlider) {
        valueLabel2.text = String(sender.value)
        
        ciFilter.setValue(sender.value, forKey: kCIInputBrightnessKey)
        
        if let filteredImage = ciFilter.outputImage {
            editImage.image = UIImage(ciImage: filteredImage)
        }
    }
    
    
    

    @objc func nextButton() {
        
        performSegue(withIdentifier: "toPost", sender: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let postVC = segue.destination as! PostViewController
        
//        postVC.passedImage2 = editImage.image!
    }
    
    
    @objc func backButton(){
        self.dismiss(animated: false, completion: nil)
    }
    

}
