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
    let profilePosts: Driver<[Contents]>
    let isEmpty: Driver<Bool>
    let likes: Driver<[Contents]>
    
    init(getProfilePosts: GetProfilePosts, likeListner: LikeListner, uid: String, roomID: String) {
        
        profilePosts = getProfilePosts.fetchProfilePosts(uid: uid, roomID: roomID)
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            .asDriver(onErrorJustReturn: [])
        
        isEmpty = profilePosts.compactMap { posts in
            return posts.isEmpty
        }
        .asDriver(onErrorJustReturn: true)
        
        
        likes = profilePosts.asObservable()
            .concatMap { contents -> Observable<[Contents]> in
                return likeListner.fetchLikes(contents: contents)
                    .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            }
            .asDriver(onErrorJustReturn: [])
        
        
    }
}
