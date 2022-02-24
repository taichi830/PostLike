//
//  FeedViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/02/23.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa

final class FeedViewModel {
    private let disposeBag = DisposeBag()
    let items: Driver<[Contents]>
    let isEmpty: Driver<Bool>
    let likes: Driver<[Contents]>
    
    
    init(feedContentsListner: FeedContentsListner, likeListner: LikeListner, userListner: UserListner, roomID: String) {
        let feedListner = feedContentsListner.fetchFeedContents(roomID: roomID)
        
        items = feedListner
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .asDriver(onErrorJustReturn: [])
        
        isEmpty = feedListner.map({ contents -> Bool in
            return contents.isEmpty
        })
        .asDriver(onErrorJustReturn: true)
        
        
        
        likes = items.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return likeListner.fetchLikes(contents: contents)
                    .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            }
            .asDriver(onErrorJustReturn: [])
    }
    
}
