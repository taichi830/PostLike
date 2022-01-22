//
//  DateString-Extenshion.swift
//  PostLike
//
//  Created by taichi on 2022/01/22.
//  Copyright © 2022 taichi. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    func createdAtString(createdAt:Date) -> String {
        let now = Date()
        let diff = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second], from: createdAt, to: now)
        if diff.year == 0 && diff.month == 0 && diff.day == 0 && diff.hour == 0 && diff.minute == 0 && diff.second != 0 {
          return "\(diff.second ?? 0)秒前"
            
        }else if diff.year == 0 && diff.month == 0 && diff.day == 0 && diff.hour == 0 && diff.minute != 0 {
          return "\(diff.minute ?? 0)分前"
            
        }else if diff.year == 0 && diff.month == 0 && diff.day == 0 && diff.hour != 0{
          return "\(diff.hour ?? 0)時間前"
            
        }else if diff.year == 0 && diff.month == 0 && diff.day != 0 {
          return "\(diff.day ?? 0)日前"
            
        }else if diff.year == 0 && diff.month != 0 {
          return "\(diff.month ?? 0)ヶ月前"
            
        }else if diff.year != 0 {
          return "\(diff.year ?? 0)年前"
        }
        return ""
    }
}


