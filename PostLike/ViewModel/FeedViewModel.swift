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
    
    
    init(feedContentsListner: FeedContentsListner, likeListner: GetLikes, userListner: UserListner, reportListner: ReportListner, roomID: String) {
        
        
        items = itemsRelay.asDriver(onErrorJustReturn: [])
        likes = likesRelay.asDriver(onErrorJustReturn: [])
        isEmpty = isEmptyRelay.asDriver(onErrorJustReturn: true)
        
        
        
        let fetchPosts = feedContentsListner.fetchPosts(roomID: roomID)
            .share(replay: 1)
        fetchPosts.asObservable()
            .filter { $0.isEmpty }
            .subscribe { [weak self] items in
                self?.itemsRelay.accept(items)
            }
            .disposed(by: disposeBag)
        self.isEmptyCheck()
        self.fetchLikes(fetchObservable: fetchPosts, likeListner: likeListner, currentLikes: [])
        self.fetchItems(fetchObservable: fetchPosts, reportListner: reportListner, currentItems: [])
        
        
        //更新通知を受け取る
        refreshSubject.asObservable()
            .subscribe { [weak self] _ in
                let fetchPosts = feedContentsListner.fetchPosts(roomID: roomID)
                    .share(replay: 1)
                self?.isEmptyCheck()
                self?.fetchLikes(fetchObservable: fetchPosts, likeListner: likeListner, currentLikes: [])
                self?.fetchItems(fetchObservable: fetchPosts, reportListner: reportListner, currentItems: [])
            }
            .disposed(by: disposeBag)
        
        
        
        
        isBottomSubject.asObservable()
            .subscribe { [weak self] _ in
                let fetchMorePosts = feedContentsListner.fetchMorePosts(roomID: roomID)
                    .share(replay: 1)
                let currentItems = self?.itemsRelay.value ?? []
                let currentLikes = self?.likesRelay.value ?? []
                self?.fetchLikes(fetchObservable: fetchMorePosts, likeListner: likeListner, currentLikes: currentLikes)
                self?.fetchItems(fetchObservable: fetchMorePosts, reportListner: reportListner, currentItems: currentItems)
            }
            .disposed(by: disposeBag)
        
        
        
    }
    
    
    
}





// MARK: - provate methods
extension FeedViewModel {
    private func fetchItems(fetchObservable: Observable<[Contents]>, reportListner: ReportListner, currentItems: [Contents]) {
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
    //いいねした投稿を取得
    private func fetchLikes(fetchObservable: Observable<[Contents]>, likeListner: GetLikes, currentLikes: [Contents]) {
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
    //空チェック
    private func isEmptyCheck() {
        itemsRelay.asObservable()
            .skip(1)
            .map { $0.isEmpty }
            .subscribe { [weak self] bool  in
                self?.isEmptyRelay.accept(bool)
            }
            .disposed(by: disposeBag)
    }
}





// MARK: - VCから呼び出すmethods
extension FeedViewModel {
    //最新の投稿をaccept
    func insertLatestItem(item: [Contents]) {
        let currrentItems = self.itemsRelay.value
        self.itemsRelay.accept(item + currrentItems)
    }
    //最新の投稿をaccept
    func appendLatestLikeContent(content: [Contents]) {
        let cuurentItems = self.itemsRelay.value
        let currentLikes = self.likesRelay.value
        if let i = cuurentItems.firstIndex(where: {$0.documentID == content[0].documentID}) {
            var count = cuurentItems[i].likeCount
            count += 1
            cuurentItems[i].likeCount = count
            cuurentItems[i].isLiked = true
        }
        self.likesRelay.accept(content + currentLikes)
    }
    //いいねを解除した投稿をitemsRelayからremove
    func removeLikeContent(content: Contents) {
        let cuurentItems = self.itemsRelay.value
        var currentLikes = self.likesRelay.value
        currentLikes.removeAll { $0.documentID == content.documentID }
        if let i = cuurentItems.firstIndex(where: {$0.documentID == content.documentID}) {
            var count = cuurentItems[i].likeCount
            count -= 1
            cuurentItems[i].likeCount = count
            cuurentItems[i].isLiked = true
        }
        self.likesRelay.accept(currentLikes)
    }
    //削除した投稿をitemsRelayからremove
    func removeDeletedItem(item: Contents) {
        var currentItems = self.itemsRelay.value
        currentItems.removeAll { $0.documentID == item.documentID }
        self.itemsRelay.accept(currentItems)
    }
}
