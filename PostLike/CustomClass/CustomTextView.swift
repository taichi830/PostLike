//
//  TextView_Extenshion.swift
//  PostLike
//
//  Created by taichi on 2021/11/25.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

final class LinkTextView: UITextView{
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setText(text: String, urls: [String]) {
        self.text = text
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 1
        let attributes = [NSAttributedString.Key.paragraphStyle : style,.font:UIFont.systemFont(ofSize: 15)]
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

