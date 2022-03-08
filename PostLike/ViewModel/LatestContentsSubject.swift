//
//  LatestContentsSubject.swift
//  PostLike
//
//  Created by taichi on 2022/03/07.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa

final class LatestContentsSubject: NSObject {
    
    static let shared = LatestContentsSubject()
    
    let latestFeedContents = PublishRelay<Contents>()
    let latestLikeContents = PublishRelay<Contents>()
    let deletedContents = PublishRelay<Contents>()
    
    
}
