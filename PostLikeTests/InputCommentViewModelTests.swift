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
        viewModel = InputCommentViewModel(input: (postButtonTap: postButtonEvent, commentText: commentEvent), postComment: PostCommentAPI(), userListner: UserDefaultLisner(), roomID: "Scpt2aw88rr5uJUIRNnR", postID: "0C145B1F-06B2-4C42-8750-9EC517651FC1", roomName: "猫コミュニティ", passedUid: "G7g5K68uk9fo2C5bgKRjnHAboKD2", mediaArray: ["https://firebasestorage.googleapis.com/v0/b/postlike-66c0c.appspot.com/o/images%2FFD3A44C7-5B7F-4C64-91D7-9AE93BE51A39.jpg?alt=media&token=d787e9e0-04fb-41a9-aefc-50ea9b60ead3"])
        
    }

    //コメント投稿時のバリデーション
    func testPostCommentValidation() throws {
        
        let isPostable = sheduler.createObserver(Bool.self)
        viewModel.isPostable.drive(isPostable).disposed(by: disposeBag)
        
        sheduler.start()
        
        XCTAssertEqual(isPostable.events, [
            .next(0, false),
            .next(10, true),
            .next(20, false)
        ])
    }
    
    //プロフィール情報の取得テスト
    func testFetchProfileInfo() {
        //参加中のルームかチェック
        XCTAssertEqual(try viewModel.isJoined.toBlocking().first(), false)
    }

}
