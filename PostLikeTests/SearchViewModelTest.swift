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
    let sheduler = TestScheduler(initialClock: 0)
    var textEvent: Driver<String>!
    var viewModel: SearchViewModel!

    override func setUpWithError() throws {
        // 検索バー入力イベント
        textEvent = sheduler.createHotObservable([
            .next(10, ""),
            .next(20, "スニーカー")
        ])
        .asDriver(onErrorDriveWith: Driver.empty())
        
        // viewModelをセットアップ
        viewModel = SearchViewModel(text: textEvent)
    }

    func testIsTextEmpty() throws {
        
        let isEmpty = sheduler.createObserver(Bool.self)
        viewModel.isTextEmpty.drive(isEmpty).disposed(by: disposeBag)
        
        sheduler.start()
        
        XCTAssertEqual(isEmpty.events, [
            .next(10, true),
            .next(20, false)
        ])
        
    }

}
