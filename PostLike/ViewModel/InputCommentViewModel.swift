//
//  CommentViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/02/06.
//  Copyright © 2022 taichi. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Firebase

final class InputCommentViewModel {
    
    private let dispoedBag = DisposeBag()
    var validPostDriver:Driver<Bool> = Driver.never()
    var userInfoDriver: Driver<Contents> = Driver.never()
    var isJoined: Driver<Bool> = Driver.never()
    
    init(input:(postButtonTap:Signal<()>,commentText:Driver<String>),userListner:UserListner,roomID:String) {
        
        //投稿ボタンのバリデーション
        validPostDriver = input.commentText.asObservable()
            .map { text -> Bool in
                text != "" && text != "コメントを入力する"
            }
            .asDriver(onErrorJustReturn: false)
        
        //プロフィール情報を取得
        let userListner = userListner.createUserListner(roomID: roomID)
        
        isJoined = userListner.map({ content -> Bool in
            return content.isJoined != false
        })
        .asDriver(onErrorJustReturn: false)
        
        userInfoDriver = userListner
            .debounce(.milliseconds(1000), scheduler: MainScheduler.instance)
            .asDriver(onErrorJustReturn: Contents(dic: ["isJoined" : false]))
        
        
    }
    
    
   
    
    
}
