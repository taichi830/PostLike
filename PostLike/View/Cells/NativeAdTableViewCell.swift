//
//  NativeAdTableViewCell.swift
//  postLike
//
//  Created by taichi on 2021/03/20.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import GoogleMobileAds

final class NativeAdTableViewCell: UITableViewCell {
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let adView : GADUnifiedNativeAdView = self.contentView.subviews.first as! GADUnifiedNativeAdView

        adView.iconView?.layer.cornerRadius = adView.layer.frame.height/2
        adView.iconView?.layer.borderWidth = 1
        adView.iconView?.layer.borderColor = UIColor.lightGray.cgColor
        
        (adView.callToActionView as! UIButton).isUserInteractionEnabled = false
        adView.callToActionView?.layer.cornerRadius = 3
        adView.callToActionView?.layer.borderWidth = 1
        adView.callToActionView?.layer.borderColor = UIColor.lightGray.cgColor
        adView.callToActionView?.isUserInteractionEnabled = false
        
        adView.mediaView?.layer.cornerRadius = 8
        adView.mediaView?.layer.borderColor = UIColor.systemGray6.cgColor
        adView.mediaView?.layer.borderWidth = 1
        
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    func setAd(nativeAd:GADUnifiedNativeAd){
        
        let adView : GADUnifiedNativeAdView = self.contentView.subviews.first as! GADUnifiedNativeAdView
        
        adView.nativeAd = nativeAd
        
        (adView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        adView.iconView?.isHidden = nativeAd.icon == nil
        
        (adView.headlineView as? UILabel)?.text = nativeAd.headline
        
        (adView.bodyView as? UILabel)?.text = nativeAd.body
        
        adView.mediaView?.mediaContent = nativeAd.mediaContent
        
        (adView.callToActionView as? UIButton)?.setTitle(
            nativeAd.callToAction, for: UIControl.State.normal)
        
        if let mediaView = adView.mediaView, nativeAd.mediaContent.aspectRatio > 0 {
            let heightConstraint = NSLayoutConstraint(
                item: mediaView,
                attribute: .height,
                relatedBy: .equal,
                toItem: mediaView,
                attribute: .width,
                multiplier: CGFloat(1 / nativeAd.mediaContent.aspectRatio),
                constant: 0)
            heightConstraint.isActive = true
        }
        
        
    }
    
}
