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
    let feeds: Driver<[Contents]>
    let isFeedEmpty: Driver<Bool>
    
    
    var likeRelay = BehaviorRelay<[Contents]>.init(value: [])
    let likes: Driver<[Contents]>
    
    
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
        
        
        
        
        
        let moderatorFeedsDocumentIDs = feedListner.fetchModeratorFeedsDocumentIDs()
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
        
        isFeedEmpty = moderatorFeedsDocumentIDs.asObservable()
            .map { contents -> Bool in
                return contents.isEmpty
            }
            .asDriver(onErrorJustReturn: true)
        
        
        feeds = itemsSubject.asDriver(onErrorJustReturn: [])
        likes = likeRelay.asDriver(onErrorJustReturn: [])

        
        moderatorFeedsDocumentIDs.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return feedListner.fetchModeratorPosts(contents: contents)
                    .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            }
            .subscribe { [weak self] contents in
                self?.itemsSubject.accept(contents)
            }
            .disposed(by: disposeBag)
        
        
        
        moderatorFeedsDocumentIDs.asObservable()
            .concatMap{ contents -> Observable<[Contents]> in
                return likeListner.fetchLikes(contents: contents)
                    .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            }
            .subscribe { [weak self] likes in
                self?.likeRelay.accept(likes)
            }
            .disposed(by: disposeBag)
        
        


        
        
        
        
        
        
        isBottomSubject.asObservable()
            .subscribe { [weak self] _ in
                self?.fetchMoreContents(feedListner: feedListner, likeListner: likeListner)
            }
            .disposed(by: disposeBag)
            
        
        
        
    }
    
    
    
    
    
    
    
    
    private func fetchMoreContents(feedListner: FeedContentsListner, likeListner: LikeListner) {
        let currentItems = self.itemsSubject.value
        let fetchMoreModeratorPosts = feedListner.fetchMoreModeratorPosts()
        let currentLikes = self.likeRelay.value
        
        
        fetchMoreModeratorPosts.asObservable()
            .concatMap{ contents -> Observable<[Contents]> in
                return likeListner.fetchLikes(contents: contents)
                    .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            }
            .subscribe { [weak self] likes in
                self?.likeRelay.accept(currentLikes + likes)
            }
            .disposed(by: disposeBag)


        fetchMoreModeratorPosts.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return feedListner.fetchModeratorPosts(contents: contents)
                    .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            }
            .subscribe { [weak self] contents in
                self?.itemsSubject.accept(currentItems + contents)
            }
            .disposed(by: disposeBag)

    }
    
    
    
    
    
}
