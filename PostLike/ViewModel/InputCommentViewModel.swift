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

final class InputCommentViewModel {
    private let dispoedBag = DisposeBag()
    
    var validPostSubject = BehaviorSubject<Bool>.init(value: false)
    var validPostDriver:Driver<Bool> = Driver.never()
    
    var isEmpty = BehaviorSubject<Bool>.init(value: false)
    var isEmptyDriver:Driver<Bool> = Driver.never()
    
    var isPlaceholder = BehaviorSubject<Bool>.init(value: true)
    var isPlaceholderDriver:Driver<Bool> = Driver.never()
    
    init(input:(postButtonTap:Signal<()>,commentText:Driver<String>)) {
        
        //投稿ボタンのバリデーション
        validPostDriver = validPostSubject.asDriver(onErrorJustReturn: false)
        isEmptyDriver = isEmpty.asDriver(onErrorJustReturn: true)
        isPlaceholderDriver = isPlaceholder.asDriver(onErrorJustReturn: true)
        
        let emptyCheck = input.commentText
            .asObservable()
            .map { text -> Bool in
                text != ""
            }
        
        let textCheck = input.commentText
            .asObservable()
            .map { text -> Bool in
                text != "コメントを入力する"
            }
        
        emptyCheck.asObservable()
            .subscribe { [weak self] bool in
                self?.isEmpty.onNext(!bool)
            }
            .disposed(by: dispoedBag)
        
        textCheck.asObservable()
            .subscribe { [weak self] bool in
                self?.isPlaceholder.onNext(!bool)
            }
            .disposed(by: dispoedBag)
        
        Observable.combineLatest(emptyCheck, textCheck) { $0 || $1 }
            .subscribe { [weak self] bool in
                self?.validPostSubject.onNext(bool)
            }
            .disposed(by: dispoedBag)
        
        
        
    }
    
    
}
