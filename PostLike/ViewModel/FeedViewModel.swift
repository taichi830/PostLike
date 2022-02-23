//
//  FeedViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/02/23.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa

final class FeedViewMode {
    let items: Driver<[Contents]>
    let isEmpty: Driver<Bool>
    
    init(feedContentsListner: FeedContentsListner, roomID: String) {
        let listner = feedContentsListner.fetchFeedContents(roomID: roomID)
        
        items = listner
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .asDriver(onErrorJustReturn: [])
        
        isEmpty = listner.map({ contents -> Bool in
            return contents.isEmpty
        })
        .asDriver(onErrorJustReturn: true)
    }
    
}
