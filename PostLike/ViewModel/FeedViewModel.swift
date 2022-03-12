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
    
//    let isLoadingRelay = BehaviorRelay<Bool>.init(value: true)
//    var isLoading: Driver<Bool> = Driver.never()
    
    var itemsRelay = BehaviorRelay<[Contents]>.init(value: [])
    var items: Driver<[Contents]> = Driver.never()
    
    var likesRelay = BehaviorRelay<[Contents]>.init(value: [])
    var likes: Driver<[Contents]> = Driver.never()
    
    var isEmptyRelay = PublishRelay<Bool>()
    var isEmpty: Driver<Bool> = Driver.never()
    
    var isBottomSubject = BehaviorSubject<Bool>.init(value: false)
    var isBottomObserver: AnyObserver<Bool> {
        isBottomSubject.asObserver()
    }
    
    var refreshSubject = PublishSubject<()>()
    var refreshObserver: AnyObserver<()> {
        refreshSubject.asObserver()
    }
    
    
    init(feedContentsListner: FeedContentsListner, likeListner: LikeListner, userListner: UserListner, reportListner: ReportListner, roomID: String) {
        
        
        items = itemsRelay.asDriver(onErrorJustReturn: [])
        likes = likesRelay.asDriver(onErrorJustReturn: [])
        isEmpty = isEmptyRelay.asDriver(onErrorJustReturn: true)
        
        
        
        
        
        
        
        let fetchPosts = feedContentsListner.fetchPosts(roomID: roomID)
            .share(replay: 1)
        self.isEmptyCheck(fetchObservable: fetchPosts)
        self.fetchLikes(fetchObservable: fetchPosts, likeListner: likeListner, currentLikes: [])
        self.fetchMoreContents(fetchObservable: fetchPosts, reportListner: reportListner, currentItems: [])
        
        
        //更新通知を受け取る
        refreshSubject.asObservable()
            .subscribe { [weak self] _ in
                let fetchPosts = feedContentsListner.fetchPosts(roomID: roomID)
                    .share(replay: 1)
                self?.isEmptyCheck(fetchObservable: fetchPosts)
                self?.fetchLikes(fetchObservable: fetchPosts, likeListner: likeListner, currentLikes: [])
                self?.fetchMoreContents(fetchObservable: fetchPosts, reportListner: reportListner, currentItems: [])
            }
            .disposed(by: disposeBag)
        
        
//        //報告したユーザーを取得
//        let reportedUsers = fetchPosts.asObservable()
//            .filter{ !$0.isEmpty }
//            .concatMap { contents -> Observable<[Contents]> in
//                return reportListner.fetchReportedUsers(contents: contents)
//            }
//
//        //報告した投稿を取得
//        let reportedContents = fetchPosts.asObservable()
//            .filter{ !$0.isEmpty }
//            .concatMap { contents -> Observable<[Contents]> in
//                return reportListner.fetchReportedContents(contents: contents)
//            }
//
//        //報告した投稿をremoveする
//        Observable.combineLatest(fetchPosts, reportedUsers, reportedContents)
//            .subscribe { (items,users,contents) in
//                let filteredItems = items.filter { item -> Bool in
//                    !users.contains(where: { user in
//                        item.uid == user.uid
//                    }) &&
//                    !contents.contains(where: { content in
//                        item.documentID == content.documentID
//                    })
//                }
//                self.itemsRelay.accept(filteredItems)
//            }
//            .disposed(by: disposeBag)
//
//
//        //いいねした投稿を取得
//        fetchPosts.asObservable()
//            .filter{ !$0.isEmpty }
//            .concatMap { contents -> Observable<[Contents]> in
//                return likeListner.fetchLikes(contents: contents)
//            }
//            .subscribe { [weak self] likes in
//                self?.likesRelay.accept(likes)
//            }
//            .disposed(by: disposeBag)
        
        
        
        
        isBottomSubject.asObservable()
            .subscribe { [weak self] _ in
                let fetchMorePosts = feedContentsListner.fetchMorePosts(roomID: roomID)
                    .share(replay: 1)
                let currentItems = self?.itemsRelay.value ?? []
                let currentLikes = self?.likesRelay.value ?? []
                self?.fetchLikes(fetchObservable: fetchMorePosts, likeListner: likeListner, currentLikes: currentLikes)
                self?.fetchMoreContents(fetchObservable: fetchMorePosts, reportListner: reportListner, currentItems: currentItems)
            }
            .disposed(by: disposeBag)
        
        
    
    }
    
    
    
    
    private func fetchMoreContents(fetchObservable: Observable<[Contents]>, reportListner: ReportListner, currentItems: [Contents]) {
        
        //報告したユーザーを取得
        let reportedUsers = fetchObservable.asObservable()
            .filter { !$0.isEmpty }
            .concatMap { contents -> Observable<[Contents]> in
                return reportListner.fetchReportedUsers(contents: contents)
            }
        
        //報告した投稿を取得
        let reportedContents = fetchObservable.asObservable()
            .filter { !$0.isEmpty }
            .concatMap { contents -> Observable<[Contents]> in
                return reportListner.fetchReportedContents(contents: contents)
            }
        
        //報告した投稿をremoveする
        Observable.combineLatest(fetchObservable, reportedUsers, reportedContents)
            .subscribe { (items,users,contents) in
                let filteredItems = items.filter { item -> Bool in
                    !users.contains(where: { user in
                        item.uid == user.uid
                    }) &&
                    !contents.contains(where: { content in
                        item.documentID == content.documentID
                    })
                }
                self.itemsRelay.accept(currentItems + filteredItems)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    private func fetchLikes(fetchObservable: Observable<[Contents]>, likeListner: LikeListner, currentLikes: [Contents]) {
        //いいねした投稿を取得
        fetchObservable.asObservable()
            .filter { !$0.isEmpty }
            .concatMap { contents -> Observable<[Contents]> in
                return likeListner.fetchLikes(contents: contents)
                    .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            }
            .subscribe { [weak self] likes in
                self?.likesRelay.accept(currentLikes + likes)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    private func isEmptyCheck(fetchObservable: Observable<[Contents]>) {
        //空チェック
        fetchObservable.asObservable()
            .map { $0.isEmpty }
            .subscribe { [weak self] bool  in
                self?.isEmptyRelay.accept(bool)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    
    
    
    
    
    
}
