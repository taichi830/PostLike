//
//  PostViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/01/24.
//  Copyright © 2022 taichi. All rights reserved.
//

import Foundation
import DKImagePickerController
import RxSwift
import RxCocoa

final class PostViewModel {
    
    private let disposeBag = DisposeBag()
    
    //observable
    var postTextOutPut = PublishSubject<String>()
    var photoArrayOutPut = BehaviorSubject<[UIImage]>.init(value: [])
    
    var validPostSubject = BehaviorSubject<Bool>.init(value: false)
    var validAddImageSubject = BehaviorSubject<Bool>.init(value: true)
    var postCompletedSubject = BehaviorSubject<Bool>.init(value: true)
    var imageArrayCountSubject = BehaviorSubject<Int>.init(value: 0)
    
    //observer
    var postTextInPut:AnyObserver<String> {
        postTextOutPut.asObserver()
        
    }
    var photoArrayInPut:AnyObserver<[UIImage]> {
        photoArrayOutPut.asObserver()
    }
    
    var validPostDriver:Driver<Bool> = Driver.never()
    var validAddImageDriver:Driver<Bool> = Driver.never()
    var postedDriver:Driver<Bool> = Driver.never()
    var imageCountDriver:Driver<Int> = Driver.never()
    
    
    
    
    init(input:(postButtonTap:Signal<()>,text:Driver<String>,albumButtonTap:Signal<()>),userName:String,userImage:String,passedUid:String,roomID:String,postAPI:PostAPI) {
        
        
        PostButtonValidation()
        alubumButtonValidation(alubumButtonTap: input.albumButtonTap)
        post(postButtonTap: input.postButtonTap, text: input.text, userName: userName, userImage: userImage, passedUid: passedUid, roomID: roomID, postAPI: postAPI)
 
    }
    
    
    
    
    
    
    
    
    private func PostButtonValidation() {
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
                return photos != []
            }
            .share(replay: 1)
        
        Observable.combineLatest(validPostText, validPhotoArray) { $0 || $1 }
            .subscribe { bool in
                self.validPostSubject.onNext(bool)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    private func alubumButtonValidation(alubumButtonTap:Signal<()>) {
        validAddImageDriver = validAddImageSubject
            .asSharedSequence(onErrorDriveWith: Driver.empty())
        
        let validAddImage = photoArrayOutPut
            .asObservable()
            .map { imageArray -> Bool in
                return imageArray.count < 2
            }
            .share(replay: 1)
        
        let imageArrayCountObservable = photoArrayOutPut
            .asObservable()
            .map { imageArray -> Int in
                return imageArray.count
            }
            .share(replay: 1)
        
        validAddImage.subscribe { [weak self] bool in
                self?.validAddImageSubject.onNext(bool)
            }
            .disposed(by: disposeBag)

        
        imageCountDriver = imageArrayCountSubject.asDriver(onErrorDriveWith: Driver.empty())
        alubumButtonTap.asObservable()
            .withLatestFrom(imageArrayCountObservable)
            .subscribe { [weak self] count in
                self?.imageArrayCountSubject.onNext(count)
            }
            .disposed(by: disposeBag)
            
    }
    
    
    
    
    
    
    
    
    
    private func post(postButtonTap:Signal<()>,text:Driver<String>,userName:String,userImage:String,passedUid:String,roomID:String,postAPI:PostAPI) {
        postedDriver = postCompletedSubject.asDriver(onErrorJustReturn: true)
        let imageArrayObservable = photoArrayOutPut
            .asObservable()
        let textObservable = text.asObservable()
        let combineObservable = Observable.combineLatest(imageArrayObservable, textObservable)
        
        postButtonTap
            .asObservable()
            .withLatestFrom(combineObservable)
            .flatMapLatest { (imageArray,text) -> Single<Bool> in
                return postAPI.post(userName: userName, userImage: userImage, text: text, passedUid: passedUid, roomID: roomID, imageArray: imageArray)
            }
            .subscribe { [weak self] bool in
                switch bool {
                case .next(let bool):
                    self?.postCompletedSubject.onNext(bool)
                case .error(let error):
                    print(error)
                    self?.postCompletedSubject.onNext(false)
                case .completed:
                    print("completed")
                }
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    
    
    
    func remove(row:Int) {
        var items = try! photoArrayOutPut.value()
        items.remove(at: row)
        photoArrayOutPut.onNext(items)
    }

    
    
}
    
