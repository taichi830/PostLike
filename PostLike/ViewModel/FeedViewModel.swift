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
    
    
    init(feedContentsListner: FeedContentsListner, likeListner: LikeListner, userListner: UserListner, reportListner: ReportListner, roomID: String) {
        let feedListner = feedContentsListner.fetchFeedContents(roomID: roomID)
        
    
        
        isEmpty = feedListner.map({ contents -> Bool in
            return contents.isEmpty
        })
        .asDriver(onErrorJustReturn: true)
        
        
        let items2 = feedListner
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
        
        
        likes = items2.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return likeListner.fetchLikes(contents: contents)
                    .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            }
            .asDriver(onErrorJustReturn: [])
        
        
        
        
        let reportedUsers = items2.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return reportListner.fetchReportedUsers(contents: contents)
                    .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            }
        
        let reportedContents = items2.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return reportListner.fetchReportedContents(contents: contents)
                    .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            }
        
        items = Observable.combineLatest(items2, reportedUsers, reportedContents)
            .map { (items,users,contents) -> [Contents] in
                print("items:",items.count,"users:",users.count,"contents:",contents.count)
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
