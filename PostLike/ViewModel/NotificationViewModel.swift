//
//  NotificationViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/02/10.
//  Copyright © 2022 taichi. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Firebase

final class NotificationViewModel {
    
    let items: Driver<[Contents]>
    let isEmpty: Driver<Bool>

    init(notificationListner: NotificationListner) {
        //お知らせを取得
        let listner = notificationListner.items
        // 取得したお知らせをdriverに紐付け
        items = listner
            .asDriver(onErrorJustReturn: [])
        // 取得したお知らせが空かどうかチェック
        isEmpty = listner
            .map { contents -> Bool in
                return contents.isEmpty
            }
            .asDriver(onErrorJustReturn: true)
            
    }
}
