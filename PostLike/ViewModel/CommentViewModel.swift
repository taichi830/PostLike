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
    let isEmpty: Driver<Bool>
    
    init (commentListner: CommentListner,documentID:String) {
        
        let listner = commentListner.createListner(documentID: documentID)
        
        items = listner
            .debounce(.milliseconds(1000), scheduler: MainScheduler.instance)
            .asDriver(onErrorJustReturn: [])
        
        isEmpty = listner.map { contents -> Bool in
            return contents.isEmpty
        }
        .asDriver(onErrorJustReturn: true)
        
    }
}
