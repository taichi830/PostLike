//
//  PrivacyPolicyViewController.swift
//  PostLike
//
//  Created by taichi on 2021/08/30.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import WebKit

final class PrivacyPolicyViewController: UIViewController{
    
    
    @IBOutlet private weak var webView: WKWebView!


    override func viewDidLoad() {
        super.viewDidLoad()
        loadAddressURL()
        
    }
    
    
    private func loadAddressURL() {
        if let targetURL = Bundle.main.path(forResource: "index", ofType: "html"){
            let url = URL(fileURLWithPath: targetURL)
            let req = URLRequest(url: url)
            webView.load(req)
        }else{
            print("hi")
        }
    }
    
    
    @IBAction private func back(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
}
