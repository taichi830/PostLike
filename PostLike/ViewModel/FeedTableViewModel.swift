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
        
        let userInfo = userInfoListner.createUserListner(roomID: roomID)
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
        
        
        isJoined = userInfo.asObservable()
            .map { userInfo -> Bool in
                return userInfo.isJoined
            }
            .asDriver(onErrorJustReturn: false)
        
        
        likeButtonTap.asObservable()
            .withLatestFrom(userInfo)
            .flatMapLatest { userInfo -> Observable<Contents> in
                if content.isLiked == true {
                    return createLikes.deleteLikes(content: content, userInfo: userInfo)
                }else {
                    return createLikes.createLikes(content: content, userInfo: userInfo)
                }
            }
            .subscribe { item in
                LatestContentsSubject.shared.latestLikeContents.accept(item)
            }
            .disposed(by: disposedBag)
        
    }
}
