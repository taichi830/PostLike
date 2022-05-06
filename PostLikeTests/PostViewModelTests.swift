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
        
        
        
        viewModel = PostViewModel(input: (postButtonTap: postButtonEvent, albumButtonTap: albumButtonTapEvent), userName: "taichi", userImage: "", passedUid: "G7g5K68uk9fo2C5bgKRjnHAboKD2", roomID: "Scpt2aw88rr5uJUIRNnR", postAPI: PostDefaultAPI())
        
        
        
    }
    
    //投稿時のバリデーションをテスト
    func testPostValidation() throws {
        
        textEvent.drive(viewModel.inputs.text).disposed(by: disposeBag)
        
        appendImageEvent = scheduler.createHotObservable([
            .next(30, [UIImage()]),
        ]).asDriver(onErrorDriveWith: Driver.empty())
        appendImageEvent.drive(viewModel.inputs.photos).disposed(by: disposeBag)
        
        let isPostButtonEnabled = scheduler.createObserver(Bool.self)
        viewModel.outputs.isPostButtonEnabled.drive(isPostButtonEnabled).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(isPostButtonEnabled.events, [
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
        appendImageEvent.drive(viewModel.inputs.photos).disposed(by: disposeBag)
        
        let isAlbumButtonEnabled = scheduler.createObserver(Bool.self)
        viewModel.isAlbumButtonEnabled.drive(isAlbumButtonEnabled).disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(isAlbumButtonEnabled.events, [
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
        appendImageEvent.drive(viewModel.inputs.photos).disposed(by: disposeBag)
        
        let imageCountDriver = scheduler.createObserver(Int.self)
        viewModel.outputs.imageCountDriver.drive(imageCountDriver).disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(imageCountDriver.events, [
            .next(40, 1),
            .next(50, 2)
        ])
        
        
    }
    



}
