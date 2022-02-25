//
//  FeedTableViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/02/25.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa

final class FeedTableViewModel {
    private let disposedBag = DisposeBag()
    let isJoined: Driver<Bool>
    init(likeButtonTap: Signal<()>, createLikes: CreateLikes, content: Contents, userInfoListner: UserListner, roomID: String) {
        
        let userInfoListner = userInfoListner.createUserListner(roomID: roomID)
        let userInfo = userInfoListner
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
        isJoined = userInfo.asObservable()
            .map { userInfo -> Bool in
                return userInfo.isJoined
            }
            .asDriver(onErrorJustReturn: false)
        
        
        likeButtonTap.asObservable()
            .withLatestFrom(userInfo)
            .flatMapLatest { userInfo in
                return createLikes.createLikes(content: content, userInfo: userInfo)
            }
            .subscribe { bool in
                print("bool", bool)
            }
            .disposed(by: disposedBag)
        
    }
}
