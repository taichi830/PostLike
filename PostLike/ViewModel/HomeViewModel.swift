//
//  HomeViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/03/04.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa
import FirebaseFirestore

final class HomeViewModel {
    
    private let disposeBag = DisposeBag()
    
    
//    let feedContentsRelay = PublishRelay<[Contents]>()
    
    
    var isLoadingRelay = BehaviorRelay<Bool>.init(value: true)
    var isLoading: Driver<Bool> = Driver.never()
    
    
    let rooms: Driver<[Contents]>
    let isRoomEmpty: Driver<Bool>
    
    
    var itemsRelay = BehaviorRelay<[Contents]>.init(value: [])
    var items: Driver<[Contents]> = Driver.never()
    
    var isItemEmptyRelay = PublishRelay<Bool>()
    var isItemEmpty: Driver<Bool> = Driver.never()
    
    
    var likeRelay = BehaviorRelay<[Contents]>.init(value: [])
    var likes: Driver<[Contents]> = Driver.never()
    
    
    var isBottomSubject = BehaviorSubject<Bool>.init(value: false)
    var isBottomObserver: AnyObserver<Bool> {
        isBottomSubject.asObserver()
    }
    
    var refreshSubject = PublishSubject<()>()
    var refreshObserver: AnyObserver<()> {
        refreshSubject.asObserver()
    }
    
    
    
    init(roomListner: RoomListner, feedListner: FeedContentsListner, likeListner: LikeListner, reportListner: ReportListner) {
        
        //ルームを取得
        rooms = roomListner.fetchRooms()
            .asDriver(onErrorJustReturn: [])
        //ルームの空チェック
        isRoomEmpty = rooms.asObservable()
            .map { rooms in
                return rooms.isEmpty
            }
            .asDriver(onErrorJustReturn: true)
        
        
        
        items = itemsRelay.asDriver(onErrorJustReturn: [])
        likes = likeRelay.asDriver(onErrorJustReturn: [])
        isItemEmpty = isItemEmptyRelay.asDriver(onErrorJustReturn: true)
        
        
        //feedsコレクションを取得
        let feedObservable = feedListner.fetchModeratorFeeds().share(replay: 1)
        //空チェック
        self.isEmptyCheck(feedObservable: feedObservable)
        //いいねした投稿とモデレーターの投稿を取得
        self.callModeratorPostsAndLikes(feedObservable: feedObservable, feedListner: feedListner, likeListner: likeListner, currentItems: [], currentLikes: [])
        
        
        //更新通知を受け取る
        refreshSubject.asObservable()
            .subscribe { [weak self] _ in
                let fetchFeeds = feedListner.fetchModeratorFeeds().share(replay: 1)
                self?.isEmptyCheck(feedObservable: fetchFeeds)
                self?.callModeratorPostsAndLikes(feedObservable: fetchFeeds, feedListner: feedListner, likeListner: likeListner, currentItems: [], currentLikes: [])
            }
            .disposed(by: disposeBag)
        
        
        

        //bottomに到達した際に投稿を追加で取得
        isBottomSubject.asObservable()
            .subscribe { [weak self] _ in
                self?.fetchMoreContents(feedListner: feedListner, likeListner: likeListner)
            }
            .disposed(by: disposeBag)
            
        
        
        
    }
    
    
    
    private func isEmptyCheck(feedObservable: Observable<[Contents]>) {
        feedObservable.asObservable()
            .map { $0.isEmpty }
            .subscribe { [weak self] bool in
                self?.isItemEmptyRelay.accept(bool)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    private func callModeratorPostsAndLikes(feedObservable: Observable<[Contents]>, feedListner: FeedContentsListner, likeListner: LikeListner, currentItems: [Contents], currentLikes: [Contents]) {
        feedObservable.asObservable()
            .filter { !$0.isEmpty }
            .subscribe { [weak self] contents in
                guard let element = contents.element else { return }
                self?.fetchModeratorPosts(feedListner: feedListner, contents: element, currentItems: currentItems)
                self?.fetchLikes(likeListner: likeListner, contents: element, currentLikes: currentLikes)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    private func fetchModeratorPosts(feedListner: FeedContentsListner, contents: [Contents], currentItems: [Contents]) {
        feedListner.fetchModeratorPosts(contents: contents)
            .subscribe { [weak self] contents in
                self?.itemsRelay.accept(currentItems + contents)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    private func fetchLikes(likeListner: LikeListner, contents: [Contents], currentLikes: [Contents]) {
        likeListner.fetchLikes(contents: contents)
            .subscribe { [weak self] likes in
                self?.likeRelay.accept(currentLikes + likes)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    private func fetchMoreContents(feedListner: FeedContentsListner, likeListner: LikeListner) {
        let currentItems = self.itemsRelay.value
        let currentLikes = self.likeRelay.value
        feedListner.fetchMoreModeratorFeeds()
            .filter { !$0.isEmpty }
            .subscribe { [weak self] contents in
                guard let element = contents.element else { return }
                self?.fetchModeratorPosts(feedListner: feedListner, contents: element, currentItems: currentItems)
                self?.fetchLikes(likeListner: likeListner, contents: element, currentLikes: currentLikes)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
}
