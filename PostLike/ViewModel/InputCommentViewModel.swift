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
    var isJoined: Driver<Bool>
    
    var isPostedSubject = PublishSubject<Bool>()
    let isPosted: Driver<Bool>
    
    var postErrorSubject = PublishSubject<Error>()
    let postError: Driver<Error>
    
    
    
    
    init(input:(postButtonTap:Signal<()>,commentText:Driver<String>),postComment:PostComment,userListner:UserListner,roomID: String, postID: String, roomName: String, passedUid: String, mediaArray: [String]) {
        
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
        
        
        
        //投稿処理
        isPosted = isPostedSubject.asDriver(onErrorJustReturn: false)
        postError = postErrorSubject.asDriver(onErrorDriveWith: Driver.empty())
        let combineLatest = Observable.combineLatest(input.commentText.asObservable(), userListner)
        input.postButtonTap
            .asObservable()
            .withLatestFrom(combineLatest)
            .flatMapLatest({ (text,userInfo) -> Single<Bool> in
                return postComment.postComment(userName: userInfo.userName, userImage: userInfo.userImage, text: text, roomID: roomID, postID: postID, roomName: roomName, passedUid: passedUid, mediaArray: mediaArray)
            })
            .subscribe { [weak self] result in
                switch result {
                case .next(let bool):
                    self?.isPostedSubject.onNext(bool)
                case .error(let err):
                    self?.postErrorSubject.onNext(err)
                case .completed:
                    break
                }
            }
            .disposed(by: dispoedBag)
    }
    
    
   
    
    
}
