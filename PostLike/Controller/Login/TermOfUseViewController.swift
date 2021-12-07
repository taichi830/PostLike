//
//  TermOfUseViewController.swift
//  PostLike
//
//  Created by taichi on 2021/08/31.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import WebKit

class TermOfUseViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadAddressURL()
       
    }
    

  
    private func loadAddressURL() {
        if let targetURL = Bundle.main.path(forResource: "termOfUse", ofType: "html"){
            let url = URL(fileURLWithPath: targetURL)
            let req = URLRequest(url: url)
            webView.load(req)
        }
    }
    
    
    @IBAction func back(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    

}
