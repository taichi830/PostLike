//
//  TextView_Extenshion.swift
//  PostLike
//
//  Created by taichi on 2021/11/25.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

class LinkTextView: UITextView{
    
    func setText(text: String, urls: [String]) {
        self.text = text
        let style = NSMutableParagraphStyle()
//        style.lineSpacing = 1
        let attributes = [NSAttributedString.Key.paragraphStyle : style,.font:UIFont.systemFont(ofSize: 16)]
        let attributeString = NSMutableAttributedString(string:self.text,
                                                        attributes: attributes)
        urls.forEach { url in
            attributeString.addAttribute(.link,
                                         value: url,
                                         range: NSString(string: text).range(of: url))
        }
        self.attributedText = attributeString
    }
    
}

