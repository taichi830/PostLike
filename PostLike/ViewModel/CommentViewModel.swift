//
//  CommentViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/02/07.
//  Copyright © 2022 taichi. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Firebase

final class CommentViewModel {
    let items: Driver<[Contents]>
    
    init (commentListner: CommentListner,documentID:String) {
        items = commentListner.createListner(documentID: documentID)
            .debounce(.milliseconds(1000), scheduler: MainScheduler.instance)
            .asDriver(onErrorJustReturn: [])
    }
}
