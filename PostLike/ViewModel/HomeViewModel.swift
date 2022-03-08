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
    
    
    let rooms: Driver<[Contents]>
    let isRoomEmpty: Driver<Bool>
    
    
    var itemsSubject = BehaviorRelay<[Contents]>.init(value: [])
    var feeds: Driver<[Contents]> = Driver.never()
    let isFeedEmpty: Driver<Bool>
    
    
    var likeRelay = BehaviorRelay<[Contents]>.init(value: [])
    var likes: Driver<[Contents]> = Driver.never()
    
    
    var isBottomSubject = BehaviorSubject<Bool>.init(value: false)
    var isBottomObserver: AnyObserver<Bool> {
        isBottomSubject.asObserver()
    }
    
    
    
    init(roomListner: RoomListner, feedListner: FeedContentsListner, likeListner: LikeListner, reportListner: ReportListner) {
        
        
        rooms = roomListner.fetchRooms()
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            .asDriver(onErrorJustReturn: [])
        
        isRoomEmpty = rooms.asObservable()
            .map { rooms in
                return rooms.isEmpty
            }
            .asDriver(onErrorJustReturn: true)
        
        
        
        
        
        
        let fetchFeedContents = feedListner.fetchModeratorFeedsDocumentIDs()
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
        
        //空チェック
        isFeedEmpty = fetchFeedContents.asObservable()
            .map { contents -> Bool in
                return contents.isEmpty
            }
            .asDriver(onErrorJustReturn: true)
        
        //いいねした投稿とモデレーターの投稿を取得
        fetchFeedContents
            .subscribe { [weak self] contents in
                guard let element = contents.element else { return }
                self?.fetchLikes(likeListner: likeListner, contents: element)
                self?.fetchModeratorPosts(feedListner: feedListner, contents: element)
            }
            .disposed(by: disposeBag)
        

        
        isBottomSubject.asObservable()
            .subscribe { [weak self] _ in
                self?.fetchMoreContents(feedListner: feedListner, likeListner: likeListner)
            }
            .disposed(by: disposeBag)
            
        
        
        
    }
    
    
    
    
    private func fetchModeratorPosts(feedListner: FeedContentsListner, contents: [Contents]) {
        let currentItems = self.itemsSubject.value
        feeds = itemsSubject.asDriver(onErrorJustReturn: [])
        feedListner.fetchModeratorPosts(contents: contents)
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            .subscribe { [weak self] contents in
                self?.itemsSubject.accept(currentItems + contents)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    private func fetchLikes(likeListner: LikeListner, contents: [Contents]) {
        let currentLikes = self.likeRelay.value
        likes = likeRelay.asDriver(onErrorJustReturn: [])
        likeListner.fetchLikes(contents: contents)
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            .subscribe { [weak self] likes in
                self?.likeRelay.accept(currentLikes + likes)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    private func fetchMoreContents(feedListner: FeedContentsListner, likeListner: LikeListner) {
        feedListner.fetchMoreModeratorPosts()
            .subscribe { [weak self] contents in
                guard let element = contents.element else { return }
                self?.fetchModeratorPosts(feedListner: feedListner, contents: element)
                self?.fetchLikes(likeListner: likeListner, contents: element)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
}
