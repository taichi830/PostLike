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
    
    var itemsRelay = BehaviorRelay<[Contents]>.init(value: [])
    let items: Driver<[Contents]>
    
    var likesRelay = BehaviorRelay<[Contents]>.init(value: [])
    let likes: Driver<[Contents]>
    
    let isEmpty: Driver<Bool>
    
    var isBottomSubject = BehaviorSubject<Bool>.init(value: false)
    var isBottomObserver: AnyObserver<Bool> {
        isBottomSubject.asObserver()
    }
    
    
    init(feedContentsListner: FeedContentsListner, likeListner: LikeListner, userListner: UserListner, reportListner: ReportListner, roomID: String) {
        
        
        
        let fetchiItems = feedContentsListner.fetchFeedContents(roomID: roomID)
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
        
        //空チェック
        isEmpty = fetchiItems.asObservable()
            .map { items -> Bool in
                return items.isEmpty
            }
            .asDriver(onErrorJustReturn: true)
        items = itemsRelay.asDriver(onErrorJustReturn: [])
        likes = likesRelay.asDriver(onErrorJustReturn: [])
        
        
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
        Observable.combineLatest(fetchiItems, reportedUsers, reportedContents)
            .subscribe { (items,users,contents) in
                let filteredItems = items.filter { item -> Bool in
                    !users.contains(where: { user in
                        item.uid == user.uid
                    }) &&
                    !contents.contains(where: { content in
                        item.documentID == content.documentID
                    })
                }
                self.itemsRelay.accept(filteredItems)
            }
            .disposed(by: disposeBag)
        
        //いいねした投稿を取得
        fetchiItems.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return likeListner.fetchLikes(contents: contents)
                    .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            }
            .subscribe { [weak self] likes in
                self?.likesRelay.accept(likes)
            }
            .disposed(by: disposeBag)
 
        
        isBottomSubject.asObservable()
            .subscribe { [weak self] _ in
                self?.fetchMoreContents(feedListner: feedContentsListner, likeListner: likeListner, reportListner: reportListner, roomID: roomID)
            }
            .disposed(by: disposeBag)
        
        
    
    }
    
    
    private func fetchMoreContents(feedListner: FeedContentsListner, likeListner: LikeListner, reportListner: ReportListner, roomID: String) {
        let currentContents = self.itemsRelay.value
        let currentLikes = self.likesRelay.value
        let fetchMoreContents = feedListner.fetchMorePosts(roomID: roomID)
        
        //報告したユーザーを取得
        let reportedUsers = fetchMoreContents.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return reportListner.fetchReportedUsers(contents: contents)
                    .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            }
        
        //報告した投稿を取得
        let reportedContents = fetchMoreContents.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return reportListner.fetchReportedContents(contents: contents)
                    .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            }
        
        //報告した投稿をremoveする
        Observable.combineLatest(fetchMoreContents, reportedUsers, reportedContents)
            .subscribe { (items,users,contents) in
                let filteredItems = items.filter { item -> Bool in
                    !users.contains(where: { user in
                        item.uid == user.uid
                    }) &&
                    !contents.contains(where: { content in
                        item.documentID == content.documentID
                    })
                }
                self.itemsRelay.accept(currentContents + filteredItems)
            }
            .disposed(by: disposeBag)
        
        //いいねした投稿を取得
        fetchMoreContents.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return likeListner.fetchLikes(contents: contents)
                    .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            }
            .subscribe { [weak self] likes in
                self?.likesRelay.accept(currentLikes + likes)
            }
            .disposed(by: disposeBag)
        
    }
    
    
    
    
    
    
    
    
}
