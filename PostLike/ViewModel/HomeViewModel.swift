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
    
    
    let feedContentsRelay = PublishRelay<[Contents]>()
    
    
    var isLoadingRelay = BehaviorRelay<Bool>.init(value: true)
    var isLoading: Driver<Bool> = Driver.never()
    
    
    let rooms: Driver<[Contents]>
    let isRoomEmpty: Driver<Bool>
    
    
    var itemsSubject = BehaviorRelay<[Contents]>.init(value: [])
    var feeds: Driver<[Contents]> = Driver.never()
    var isFeedEmpty: Driver<Bool> = Driver.never()
    
    
    var likeRelay = BehaviorRelay<[Contents]>.init(value: [])
    var likes: Driver<[Contents]> = Driver.never()
    
    
    var isBottomSubject = BehaviorSubject<Bool>.init(value: false)
    var isBottomObserver: AnyObserver<Bool> {
        isBottomSubject.asObserver()
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
        feeds = itemsSubject.asDriver(onErrorJustReturn: [])
        likes = likeRelay.asDriver(onErrorJustReturn: [])
        
        
        
        
        //feedsコレクションを取得
        let fetchFeeds = feedListner.fetchModeratorFeeds()
            .share(replay: 1)
        
        
        //空チェック
        isFeedEmpty = fetchFeeds.asObservable()
            .map { contents -> Bool in
                return contents.isEmpty
            }
            .asDriver(onErrorJustReturn: true)
        
        
        
        //いいねした投稿とモデレーターの投稿を取得
        fetchFeeds
            .filter { !$0.isEmpty }
            .subscribe { [weak self] contents in
                guard let element = contents.element else { return }
                self?.fetchLikes(likeListner: likeListner, contents: element)
                self?.fetchModeratorPosts(feedListner: feedListner, contents: element)
            }
            .disposed(by: disposeBag)
        
        
        

        //bottomに到達した際に投稿を追加で取得
        isBottomSubject.asObservable()
            .subscribe { [weak self] _ in
                self?.fetchMoreContents(feedListner: feedListner, likeListner: likeListner)
            }
            .disposed(by: disposeBag)
            
        
        
        
    }
    
    
    
    
    private func fetchModeratorPosts(feedListner: FeedContentsListner, contents: [Contents]) {
        let currentItems = self.itemsSubject.value
        feedListner.fetchModeratorPosts(contents: contents)
            .subscribe { [weak self] contents in
                self?.itemsSubject.accept(currentItems + contents)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    private func fetchLikes(likeListner: LikeListner, contents: [Contents]) {
        let currentLikes = self.likeRelay.value
        likeListner.fetchLikes(contents: contents)
            .subscribe { [weak self] likes in
                self?.likeRelay.accept(currentLikes + likes)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    private func fetchMoreContents(feedListner: FeedContentsListner, likeListner: LikeListner) {
        feedListner.fetchMoreModeratorFeeds()
            .filter { !$0.isEmpty }
            .subscribe { [weak self] contents in
                guard let element = contents.element else { return }
                self?.fetchModeratorPosts(feedListner: feedListner, contents: element)
                self?.fetchLikes(likeListner: likeListner, contents: element)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
}
