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
    
    let feedContentsRelay = PublishRelay<[Contents]>()
    
    let isLoadingRelay = BehaviorRelay<Bool>.init(value: true)
    var isLoading: Driver<Bool> = Driver.never()
    
    var itemsRelay = BehaviorRelay<[Contents]>.init(value: [])
    var items: Driver<[Contents]> = Driver.never()
    
    var likesRelay = BehaviorRelay<[Contents]>.init(value: [])
    var likes: Driver<[Contents]> = Driver.never()
    
    var isEmpty: Driver<Bool> = Driver.never()
    
    var isBottomSubject = BehaviorSubject<Bool>.init(value: false)
    var isBottomObserver: AnyObserver<Bool> {
        isBottomSubject.asObserver()
    }
    
    
    init(feedContentsListner: FeedContentsListner, likeListner: LikeListner, userListner: UserListner, reportListner: ReportListner, roomID: String) {
        
        
        items = itemsRelay.asDriver(onErrorJustReturn: [])
        likes = likesRelay.asDriver(onErrorJustReturn: [])
        isLoading = isLoadingRelay.asDriver()
        
        
        
        
        
        
        feedContentsListner.fetchFeedContents(roomID: roomID)
            .subscribe { [weak self] contents in
                guard let element = contents.element else { return }
                self?.feedContentsRelay.accept(element)
            }
            .disposed(by: disposeBag)
        
        
        
        
        //空チェック
        isEmpty = itemsRelay.asObservable()
            .map { items -> Bool in
                return items.isEmpty
            }
            .asDriver(onErrorJustReturn: true)
        
        
        
        
        
        
        //報告したユーザーを取得
        let reportedUsers = feedContentsRelay.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return reportListner.fetchReportedUsers(contents: contents)
            }
        
        //報告した投稿を取得
        let reportedContents = feedContentsRelay.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return reportListner.fetchReportedContents(contents: contents)
            }
        
        //報告した投稿をremoveする
        Observable.combineLatest(feedContentsRelay, reportedUsers, reportedContents)
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
        feedContentsRelay.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return likeListner.fetchLikes(contents: contents)
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
        let additionalContents = PublishRelay<[Contents]>()
        
        //追加で投稿を取得
        feedListner.fetchMorePosts(roomID: roomID)
            .subscribe { contents in
                additionalContents.accept(contents)
            }
            .disposed(by: disposeBag)
        
        //報告したユーザーを取得
        let reportedUsers = additionalContents.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return reportListner.fetchReportedUsers(contents: contents)
                    .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            }
        
        //報告した投稿を取得
        let reportedContents = additionalContents.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return reportListner.fetchReportedContents(contents: contents)
                    .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            }
        
        //報告した投稿をremoveする
        Observable.combineLatest(additionalContents, reportedUsers, reportedContents)
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
        additionalContents.asObservable()
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
