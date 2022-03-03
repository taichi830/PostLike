//
//  ProfileHeaderViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/03/03.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa

final class ProfileHeaderViewModel {
    let userInfo: Driver<Contents>
    let postCount: Driver<Contents>
    let likeCount: Driver<Contents>
    
    init(userListner: UserListner, roomID: String) {
        userInfo = userListner.createUserListner(roomID: roomID)
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            .asDriver(onErrorDriveWith: Driver.empty())
        
        postCount = userListner.fetchPostCount(roomID: roomID)
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            .asDriver(onErrorDriveWith: Driver.empty())
        
        likeCount = userListner.fetchLikeCount(roomID: roomID)
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            .asDriver(onErrorDriveWith: Driver.empty())
    }
}
