//
//  RegisterViewModel.swift
//  PostLike
//
//  Created by taichi on 2021/12/08.
//  Copyright © 2021 taichi. All rights reserved.
//

import RxSwift
import RxCocoa

final class RegisterViewModel {
    
    private let disposeBag = DisposeBag()
    
    //MARK: observable
    var genderTextOutPut = PublishSubject<String>()
    var birthdayTextOutPut = PublishSubject<Date>()
    var emailTextOutPut = PublishSubject<String>()
    var validBirthDaySubject = BehaviorSubject<Bool>.init(value: true)
    var validRegisterSubject = BehaviorSubject<Bool>.init(value: false)
    
    
    //MARK: observer
    var genderTextInPut:AnyObserver<String> {
        genderTextOutPut.asObserver()
    }
    var birthDayTextInPut:AnyObserver<Date> {
        birthdayTextOutPut.asObserver()
    }
    var emailTextInPut:AnyObserver<String> {
        emailTextOutPut.asObserver()
    }
    
    
    var validBirthDayDriver:Driver<Bool> = Driver.never()
    var validRegisterDriver:Driver<Bool> = Driver.never()
    
    
    
    
    
    init() {
        
        validBirthDayDriver = validBirthDaySubject
            .asDriver(onErrorDriveWith: Driver.empty())
        validRegisterDriver = validRegisterSubject
            .asDriver(onErrorDriveWith: Driver.empty())
        
        
        
        let genderValid = genderTextOutPut
            .asObservable()
            .map { text -> Bool in
                return text != ""
            }
        let birthDayValid = birthdayTextOutPut
            .asObservable()
            .map { date -> Bool in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy/MM/dd"
                dateFormatter.locale = Locale(identifier: "ja_JP")
                let birthDay = date
                let now =  Date()
                let days = Calendar.current.dateComponents([.year], from: birthDay, to: now)
                return date < Date() && days.year! > 4
            }
        let emailTextValid = emailTextOutPut
            .asObservable()
            .map { text -> Bool in
                return text != ""
            }
        
        
        
        birthDayValid.asObservable().subscribe { valid in
            self.validBirthDaySubject.onNext(valid)
        }
        .disposed(by: disposeBag)
        
        
        
        Observable.combineLatest(genderValid, birthDayValid, emailTextValid) { $0 && $1 && $2 }
            .subscribe { valid in
                self.validRegisterSubject.onNext(valid)
        }
        .disposed(by: disposeBag)
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
}
