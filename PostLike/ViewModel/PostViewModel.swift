//
//  PostViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/01/24.
//  Copyright © 2022 taichi. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

final class PostViewModel {
    
    private let disposeBag = DisposeBag()
    
    //observable
    var postTextOutPut = PublishSubject<String>()
    var photoArrayOutPut = BehaviorSubject<Array<Any>>.init(value: [])
    var validPostSubject = BehaviorSubject<Bool>.init(value: false)
    
    //observer
    var postTextInPut:AnyObserver<String> {
        postTextOutPut.asObserver()
    }
    var photoArrayInPut:AnyObserver<Array<Any>> {
        photoArrayOutPut.asObserver()
    }
    
    var validPostDriver:Driver<Bool> = Driver.never()
    
    init() {
        
        validPostDriver = validPostSubject
            .asDriver(onErrorDriveWith: Driver.empty())
        
        let validPostText = postTextOutPut
            .asObservable()
            .map { text -> Bool in
                return text != ""
            }
            .share(replay: 1)
            
        let validPhotoArray = photoArrayOutPut
            .asObservable()
            .map { photos -> Bool in
                return !photos.isEmpty
            }
            .share(replay: 1)
        
        Observable.combineLatest(validPostText, validPhotoArray) { $0 || $1 }
            .subscribe { bool in
                self.validPostSubject.onNext(bool)
            }
            .disposed(by: disposeBag)
        
        
    }
    
}
    
