//
//  PostViewModelTests.swift
//  PostLikeTests
//
//  Created by taichi on 2022/02/01.
//  Copyright © 2022 taichi. All rights reserved.
//

import XCTest
import RxSwift
import RxCocoa
import RxTest
import RxBlocking
@testable import PostLike_Dev

class PostViewModelTests: XCTestCase {
    
    

    func postValidationTest() throws {
        let disposeBag = DisposeBag()
        
        let scheduler = TestScheduler(initialClock: 0)
        
        let tapEvent = scheduler.createHotObservable([
            .next(0, ()),
        ]).asSignal(onErrorSignalWith: Signal.empty())
        
        let textEvent = scheduler.createHotObservable([
            .next(10, ""),
            .next(20, "hello"),
            .next(40, "hello")
        ]).asDriver(onErrorDriveWith: Driver.empty())
        
        let appendImageEvent = scheduler.createHotObservable([
            .next(30, [UIImage()]),
        ]).asDriver(onErrorDriveWith: Driver.empty())
        
        
        let isPostable = scheduler.createObserver(Bool.self)
        
        let viewModel = PostViewModel(input: (postButtonTap: tapEvent, text: textEvent, albumButtonTap: tapEvent), userName: "", userImage: "", passedUid: "", roomID: "", postAPI: PostDefaultAPI())
        
        textEvent.drive(viewModel.postTextInPut).disposed(by: disposeBag)
        appendImageEvent.drive(viewModel.photoArrayInPut).disposed(by: disposeBag)
        viewModel.validPostDriver.drive(isPostable).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(isPostable.events, [
            .next(0, false),//初期値
            .next(10, false),//どちらも空
            .next(20, true),//文字のみ
            .next(30, true),//写真のみ
            .next(40, true)//文字と写真
                 
        ])
        
        
    }



}
