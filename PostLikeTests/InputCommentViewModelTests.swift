//
//  InputCommentViewModelTests.swift
//  PostLikeTests
//
//  Created by taichi on 2022/02/08.
//  Copyright © 2022 taichi. All rights reserved.
//

import XCTest
import RxSwift
import RxCocoa
import RxTest
@testable import PostLike_Dev

class InputCommentViewModelTests: XCTestCase {
    
    let disposeBag = DisposeBag()
    let sheduler = TestScheduler(initialClock: 0)
    var commentEvent: Driver<String>!
    var postButtonEvent: Signal<()>!
    var profileInfo: Observable<Contents>!
    var viewModel: InputCommentViewModel!
    
    
    
    override func setUpWithError() throws {
        //コメント入力イベント
        commentEvent = sheduler.createHotObservable([
            .next(0, ""),
            .next(10, "hello"),
            .next(20, "")
        ])
        .asDriver(onErrorDriveWith: Driver.empty())
        
        //投稿ボタンのタップイベント
        postButtonEvent = sheduler.createHotObservable([
            .next(0, ()),
            .next(10, ()),
            .next(20, ()),
        ])
        .asSignal(onErrorSignalWith: Signal.empty())
        
        //viewModelを初期化
        viewModel = InputCommentViewModel(input: (postButtonTap: postButtonEvent, commentText: commentEvent), postComment: PostCommentAPI(), userListner: UserDefaultLisner(), roomID: "LpDA3GOy9H2GIqP9cIOH", postID: "", roomName: "", passedUid: "", mediaArray: [""])
        
    }

    //コメント投稿時のバリデーション
    func testPostCommentValidation() throws {
        
        let isPostable = sheduler.createObserver(Bool.self)
        viewModel.validPostDriver.drive(isPostable).disposed(by: disposeBag)
        
        sheduler.start()
        
        XCTAssertEqual(isPostable.events, [
            .next(0, false),
            .next(10, true),
            .next(20, false)
        ])
    }
    
    //プロフィール情報の取得テスト
    func testFetchProfileInfo() {
        
//        let userInfo = sheduler.createObserver(Contents.self)
//        viewModel.userInfoDriver.drive(userInfo).disposed(by: disposeBag)
//        
//        let isJoined = sheduler.createObserver(Bool.self)
//        viewModel.isJoined.drive(isJoined).disposed(by: disposeBag)
//        
//        sheduler.start()
//        
        
        
    }

}
