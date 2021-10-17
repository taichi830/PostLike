//
//  PlaceHolderTextView.swift
//  postLike
//
//  Created by taichi on 2021/04/07.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

@IBDesignable class PlaceHolderTextView: UITextView {

    @IBInspectable private var placeHolder: String = "" {
        willSet {
            self.placeHolderLabel.text = newValue
            self.placeHolderLabel.sizeToFit()
        }
    }
    
    private lazy var placeHolderLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 2, y: 9, width: 200, height: 35)) // 任意の値を入れる
        label.lineBreakMode = .byWordWrapping // 折り返しの種類
        label.numberOfLines = 0
        label.font = self.font
        label.textColor = UIColor.lightGray
        label.backgroundColor = .clear
        self.addSubview(label)
        return label
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        changeVisiblePlaceHolder()
        NotificationCenter.default.addObserver(self, selector: #selector(textChanged),
                                               name: UITextView.textDidChangeNotification, object: nil)
    }

    private func changeVisiblePlaceHolder() {
        self.placeHolderLabel.alpha = (self.placeHolder.isEmpty || !self.text.isEmpty) ? 0.0 : 1.0
    }

    @objc private func textChanged(notification: NSNotification?) {
        changeVisiblePlaceHolder()
    }
   

}
