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

final class NotificationViewModel: NSObject {
    
    let items: Driver<[Contents]>
    var isEmpty: Driver<Bool>

    init(notificationListner: NotificationListner) {
        
        items = notificationListner.items
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .asDriver(onErrorJustReturn: [])
        
        isEmpty = notificationListner.items
            .map { contents -> Bool in
                return contents.isEmpty
            }
            .asDriver(onErrorJustReturn: true)
            
    }
}
