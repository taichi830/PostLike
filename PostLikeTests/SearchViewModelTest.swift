//
//  SearchViewModelTest.swift
//  PostLikeTests
//
//  Created by taichi on 2022/03/19.
//  Copyright © 2022 taichi. All rights reserved.
//

import XCTest
import RxSwift
import RxCocoa
import RxTest
@testable import PostLike_Dev

class SearchViewModelTest: XCTestCase {
    
    let disposeBag = DisposeBag()
    let sheduler = TestScheduler(initialClock: 0, resolution: 0.1)
    var textEvent: Driver<String>!
    var viewModel: SearchViewModel!

    override func setUpWithError() throws {
        // 検索バー入力イベント
        textEvent = sheduler.createHotObservable([
            .next(1, "ス"),
            .next(5, "スニー"),
            .next(7, "スニーカー")
        ])
        .asDriver(onErrorDriveWith: Driver.empty())
        
        // viewModelをセットアップ
        viewModel = SearchViewModel(text: textEvent)
    }

    // textの空判定テスト
    func testIsTextEmpty() throws {
        let isEmpty = sheduler.createObserver(Bool.self)
        
        viewModel.isTextEmpty.drive(isEmpty).disposed(by: disposeBag)
        
        sheduler.start()
        
        XCTAssertEqual(isEmpty.events, [
            .next(1, false),
            .next(5, false),
            .next(7, false)
        ])
    }
    
    //0.3秒に一回テキストイベントを受け取れているかテスト
    func testResult() throws {
        let observer = sheduler.createObserver(String.self)
        textEvent.asObservable()
            .debounce(.milliseconds(300), scheduler: sheduler)
            .bind(to: observer)
            .disposed(by: disposeBag)
        sheduler.start()
        XCTAssertEqual(observer.events, [
            .next(4, "ス"),
            .next(10, "スニーカー")
        ])
    }

}
