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
    
    let disposeBag = DisposeBag()
    let scheduler = TestScheduler(initialClock: 0)
    var albumButtonTapEvent: Signal<()>!
    var postButtonEvent: Signal<()>!
    var textEvent: Driver<String>!
    var appendImageEvent: Driver<[UIImage]>!
    var viewModel: PostViewModel!
    
    
    override func setUpWithError() throws {
        
        textEvent = scheduler.createHotObservable([
            .next(10, ""),
            .next(20, "hello"),
            .next(40, "hello")
        ]).asDriver(onErrorDriveWith: Driver.empty())
        
        
        albumButtonTapEvent = scheduler.createHotObservable([
            .next(40, ()),
            .next(50, ())
        ]).asSignal(onErrorSignalWith: Signal.empty())
        
        
        
        postButtonEvent = scheduler.createHotObservable([
            .next(0, ()),
        ]).asSignal(onErrorSignalWith: Signal.empty())
        
        
        
        viewModel = PostViewModel(input: (postButtonTap: postButtonEvent, text: textEvent, albumButtonTap: albumButtonTapEvent), userName: "", userImage: "", passedUid: "", roomID: "")
        
        
        
    }
    
    //投稿時のバリデーションをテスト
    func testPostValidation() throws {
        
        appendImageEvent = scheduler.createHotObservable([
            .next(30, [UIImage()]),
        ]).asDriver(onErrorDriveWith: Driver.empty())
        
        let isPostable = scheduler.createObserver(Bool.self)
    
        textEvent.drive(viewModel.postTextInPut).disposed(by: disposeBag)
        appendImageEvent.drive(viewModel.photoArrayInPut).disposed(by: disposeBag)
        viewModel.validPostDriver.drive(isPostable).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(isPostable.events, [
            .next(0, false),//初期値
            .next(10, false),//どちらも空
            .next(20, true),//文字のみ
            .next(30, true),//写真のみ
            .next(40, true),//文字と写真
            
                 
        ])
        
        
    }
    
    
    //アルバムを表示するボタンのバリデーションをテスト
    func testAlbumButtonValidation() throws {
        
        appendImageEvent = scheduler.createHotObservable([
            .next(30, [UIImage()]),
            .next(40, [UIImage(),UIImage()])
        ]).asDriver(onErrorDriveWith: Driver.empty())
        
        
        let isTapable = scheduler.createObserver(Bool.self)
        
        appendImageEvent.drive(viewModel.photoArrayInPut).disposed(by: disposeBag)
        viewModel.validAddImageDriver.drive(isTapable).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(isTapable.events, [
            .next(0, true),
            .next(30, true),
            .next(40, false)
        ])
        
        
    }
    
    
    //写真配列のカウントをテスト
    func testImageArrayCount() {
        
        appendImageEvent = scheduler.createHotObservable([
            .next(30, [UIImage()]),
            .next(40, [UIImage(),UIImage()])
        ]).asDriver(onErrorDriveWith: Driver.empty())
        
        
        let countDriver = scheduler.createObserver(Int.self)
        
        appendImageEvent.drive(viewModel.photoArrayInPut).disposed(by: disposeBag)
        viewModel.imageCountDriver.drive(countDriver).disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(countDriver.events, [
            .next(0, 0),
            .next(40, 1),
            .next(50, 2)
        ])
        
        
    }
    



}
