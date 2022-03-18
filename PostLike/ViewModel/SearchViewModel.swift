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
    
    private var resultRelay = PublishRelay<[Post_Like]>()
    var resultDriver: Driver<[Post_Like]> = Driver.never()
    
    let isTextEmpty: Driver<Bool>
    let isResultEmpty: Driver<Bool>
    
    init(text: Driver<String>) {
        
        text.asObservable()
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe { text in
                print("text:", text)
            }
            .disposed(by: disposeBag)
        
        isTextEmpty = text.asObservable()
            .map { text -> Bool in
                return text.isEmpty
            }
            .asDriver(onErrorDriveWith: Driver.empty())
        
        resultDriver = resultRelay.asDriver(onErrorJustReturn: [])
        
        isResultEmpty = resultRelay.asObservable()
            .map { result -> Bool in
                return result.isEmpty
            }
            .asDriver(onErrorDriveWith: Driver.empty())
        
        text.asObservable()
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { text -> Observable<[Post_Like]> in
                return AlgoliaAPI.shared.callAlgolia(text: text)
            }
            .subscribe { [weak self] result in
                self?.resultRelay.accept(result.element ?? [])
            }
            .disposed(by: disposeBag)
        
        
        
        
        
        
        
        
        
    }
}

