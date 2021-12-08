//
//  LoginViewModel.swift
//  PostLike
//
//  Created by taichi on 2021/12/08.
//  Copyright © 2021 taichi. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class LoginViewModel {
    
    private let disposeBag = DisposeBag()
    
    //MARK: observable
    var emailTextOutPut = PublishSubject<String>()
    var passWordTextOutPut = PublishSubject<String>()
    var validRegisterSubject = BehaviorSubject<Bool>.init(value: false)
    
    //MARK: observer
    var emailTextInPut:AnyObserver<String> {
        emailTextOutPut.asObserver()
    }
    var passWordTextInPut:AnyObserver<String> {
        passWordTextOutPut.asObserver()
    }
    
    var validLoginDriver:Driver<Bool> = Driver.never()
    
    
    init() {
        
        validLoginDriver = validRegisterSubject
            .asDriver(onErrorDriveWith: Driver.empty())
        
        let emailValid = emailTextOutPut
            .asObservable()
            .map { text -> Bool in
                return text != ""
            }
        
        let passWordValid = passWordTextOutPut
            .asObservable()
            .map { text -> Bool in
                return text != ""
            }
        
        Observable.combineLatest(emailValid, passWordValid) { $0 && $1 }
            .subscribe { validAll in
                self.validRegisterSubject.onNext(validAll)
            }
            .disposed(by: disposeBag)
        
        
        
    }
    
}
