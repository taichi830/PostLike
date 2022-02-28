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
    let likes: Driver<[Contents]>
    
    
    init(feedContentsListner: FeedContentsListner, likeListner: LikeListner, userListner: UserListner, reportListner: ReportListner, roomID: String) {
        
        
        let fetchiItems = feedContentsListner.fetchFeedContents(roomID: roomID)
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
        
        
        //いいねした投稿を取得
        likes = fetchiItems.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return likeListner.fetchLikes(contents: contents)
                    .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            }
            .asDriver(onErrorJustReturn: [])
        
        
        
        //報告したユーザーを取得
        let reportedUsers = fetchiItems.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return reportListner.fetchReportedUsers(contents: contents)
                    .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            }
        
        
        //報告した投稿を取得
        let reportedContents = fetchiItems.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return reportListner.fetchReportedContents(contents: contents)
                    .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            }
        
        
        
        //報告した投稿をremoveする
        items = Observable.combineLatest(fetchiItems, reportedUsers, reportedContents)
            .map { (items,users,contents) -> [Contents] in
                return items.filter { item -> Bool in
                    !users.contains(where: { user in
                        item.uid == user.uid
                    }) &&
                    !contents.contains(where: { content in
                        item.documentID == content.documentID
                    })
                }
            }
            .asDriver(onErrorJustReturn: [])
            
            
    
    }
    
    
    
    
    
    
    
    
}
