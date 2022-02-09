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
        let listner = notificationListner.createNotificationListner()
        items = listner
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .asDriver(onErrorJustReturn: [])
        
        isEmpty = listner.map { contents -> Bool in
            return contents.isEmpty
        }
        .asDriver(onErrorJustReturn: true)
    }
}
