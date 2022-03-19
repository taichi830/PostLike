//
//  SearchViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/03/17.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa

final class SearchViewModel {
    
    private let disposeBag = DisposeBag()
    
    private var resultRelay = PublishRelay<[Result]>()
    
    var resultDriver: Driver<[Result]> = Driver.never()
    let isTextEmpty: Driver<Bool>
    let isResultEmpty: Driver<Bool>
    
    init(text: Driver<String>) {
        // textが空かどうかチェック
        isTextEmpty = text.asObservable()
            .map { text -> Bool in
                return text.isEmpty
            }
            .asDriver(onErrorDriveWith: Driver.empty())
        // 検索結果が空かどうかチェック
        isResultEmpty = resultRelay.asObservable()
            .map { result -> Bool in
                return result.isEmpty
            }
            .asDriver(onErrorDriveWith: Driver.empty())
        // resultRelayをdriverに紐付け
        resultDriver = resultRelay.asDriver(onErrorJustReturn: [])
        // 検索処理を呼ぶ
        text.asObservable()
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { text -> Observable<[Result]> in
                return AlgoliaAPI.shared.callAlgolia(text: text)
            }
            .subscribe { [weak self] result in
                self?.resultRelay.accept(result.element ?? [])
            }
            .disposed(by: disposeBag)
        
    }
    
    
    
    
}

