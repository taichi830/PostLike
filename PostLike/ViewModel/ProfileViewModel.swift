//
//  ProfileViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/03/02.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa

final class ProfileViewModel {
    
    private let disposeBag = DisposeBag()
    
    let itemsRelay = BehaviorRelay<[Contents]>.init(value: [])
    let items: Driver<[Contents]>
    
    var isEmpty: Driver<Bool> = Driver.never()
    var isEmptySubject = PublishRelay<Bool>()
    
    let likesRelay = BehaviorRelay<[Contents]>.init(value: [])
    let likes: Driver<[Contents]>
    
    var reflashSubject = PublishSubject<()>()
    var reflashObserver: AnyObserver<()> {
        reflashSubject.asObserver()
    }
    
    var isBottomSubject = PublishSubject<()>()
    var isBottomObserver: AnyObserver<()> {
        isBottomSubject.asObserver()
    }
    
    
    init(profileContentsListner: ProfileContentsListner, likeListner: LikeListner, uid: String, roomID: String) {
        
        items = itemsRelay.asDriver(onErrorJustReturn: [])
        likes = likesRelay.asDriver(onErrorJustReturn: [])
        isEmpty = isEmptySubject.asDriver(onErrorJustReturn: true)
        
        
        fetchProfilePosts(profileContentsListner: profileContentsListner, likeListner: likeListner, uid: uid, roomID: roomID)
        
        
        //更新の通知を受けて最新の投稿を取得する
        reflashSubject.asObservable()
            .subscribe { [weak self] _ in
                self?.fetchProfilePosts(profileContentsListner: profileContentsListner, likeListner: likeListner, uid: uid, roomID: roomID)
            }
            .disposed(by: disposeBag)
        
        //最下部に来た通知を受けてfetchMoreProfilePostsを呼び出す
        isBottomSubject.asObservable()
            .subscribe { [weak self] _ in
                self?.fetchMoreProfilePosts(profileContentsListner: profileContentsListner, likeListner: likeListner, uid: uid, roomID: roomID)
            }
            .disposed(by: disposeBag)
    }
    
    //プロフィール投稿を取得
    private func fetchProfilePosts(profileContentsListner: ProfileContentsListner, likeListner: LikeListner, uid: String, roomID: String) {
        
        let fetchProfilePosts = profileContentsListner.fetchProfilePosts(uid: uid, roomID: roomID)
            .share(replay: 1)
        
        //プロフィール投稿の空チェック
        fetchProfilePosts.asObservable()
            .map { $0.isEmpty }
            .subscribe{ [weak self] bool in
                self?.isEmptySubject.accept(bool)
            }
            .disposed(by: disposeBag)
        
        //取得した投稿をitemsRelayにアクセプト&fetchLikesを呼び出す
        fetchProfilePosts.asObservable()
            .filter { !$0.isEmpty }
            .subscribe { [weak self] contents in
                guard let element = contents.element else { return }
                self?.itemsRelay.accept(element)
                self?.fetchLikes(likeListner: likeListner, contents: element)
            }
            .disposed(by: disposeBag)
    }
    
    //いいねした投稿を取得
    private func fetchLikes(likeListner: LikeListner, contents: [Contents]) {
        let currentLikes = self.likesRelay.value
        likeListner.fetchLikes(contents: contents)
            .subscribe { [weak self] likes in
                self?.likesRelay.accept(currentLikes + likes)
            }
            .disposed(by: disposeBag)
    }
    
    //投稿を追加で取得
    private func fetchMoreProfilePosts(profileContentsListner: ProfileContentsListner, likeListner: LikeListner, uid: String, roomID: String) {
        let currentItems = self.itemsRelay.value
        profileContentsListner.fetchMoreProfilePosts(uid: uid, roomID: roomID)
            .filter { !$0.isEmpty }
            .subscribe { [weak self] contents in
                guard let contents = contents.element else { return }
                self?.fetchLikes(likeListner: likeListner, contents: contents)
                self?.itemsRelay.accept(currentItems + contents)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
}
