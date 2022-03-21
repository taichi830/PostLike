//
//  CreateProfileViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/03/02.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa

final class CreateProfileViewModel {
    
    private let disposeBag = DisposeBag()
    
    var createCompletedSubject = BehaviorSubject<Bool>.init(value: false)
    var createErrorSubject = PublishSubject<Error>()
    var userImageSubject = PublishSubject<UIImage>()
    
    var isValidTap: Driver<Bool> = Driver.never()
    var isCompleted: Driver<Bool> = Driver.never()
    var errorDriver: Driver<Error> = Driver.never()
    
    init(input:(createButtonTap: Signal<()>, userName: Driver<String>), roomInfo: Room, createProfile: CreateProfileBatch) {
        
        // userNameの空チェック
        let userNameValidation = input.userName.asObservable()
            .map { userName -> Bool in
                return userName != ""
            }
        
        // userImageがあるかチェック
        let userImageViewIsEmpty = userImageSubject.asObservable()
            .map { image in
                return image == UIImage() || image == UIImage(named: "person")
            }
        
        // userImageViewIsEmptyとinput.userNameとuserImageSubjectを合成
        let combinedObserVables = Observable.combineLatest(userImageViewIsEmpty, input.userName.asObservable(), userImageSubject.asObservable())
        
        
        isValidTap = userNameValidation.asDriver(onErrorJustReturn: false)
        isCompleted = createCompletedSubject.asDriver(onErrorJustReturn: false)
        errorDriver = createErrorSubject.asDriver(onErrorDriveWith: Driver.empty())
        
        
        // プロフィールをFirestoreに保存
        input.createButtonTap.asObservable()
            .withLatestFrom(combinedObserVables)
            .flatMapLatest { (userImageViewIsEmpty, userName, userImage) -> Observable<Bool> in
                if userImageViewIsEmpty == true {
                    return createProfile.createProfileWhenNoImage(roomInfo: roomInfo, userName: userName)
                } else {
                    return createProfile.createProfile(roomInfo: roomInfo, userName: userName, userImage: userImage)
                }
            }
            .subscribe { [weak self] bool in
                switch bool {
                case .next(let bool):
                    self?.createCompletedSubject.onNext(bool)
                case .error(let err):
                    self?.createErrorSubject.onError(err)
                case .completed:
                    break
                }
            }
            .disposed(by: disposeBag)
    }
    
    
}
