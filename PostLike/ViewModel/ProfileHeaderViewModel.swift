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
        //ユーザー情報を取得
        userInfo = userListner.createUserListner(roomID: roomID)
            .asDriver(onErrorDriveWith: Driver.empty())
        //投稿数を取得
        postCount = userListner.fetchPostCount(roomID: roomID)
            .asDriver(onErrorDriveWith: Driver.empty())
        //自分がいいねした数を取得
        likeCount = userListner.fetchLikeCount(roomID: roomID)
            .asDriver(onErrorDriveWith: Driver.empty())
    }
}
