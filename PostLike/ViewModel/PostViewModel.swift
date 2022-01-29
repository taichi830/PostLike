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
    private let storageModel = PostDefaultAPI()
    
    //observable
    var postTextOutPut = PublishSubject<String>()
    var photoArrayOutPut = BehaviorSubject<[UIImage]>.init(value: [])
    var validPostSubject = BehaviorSubject<Bool>.init(value: false)
    var postCompletedSubject = BehaviorSubject<Bool>.init(value: true)
    
    //observer
    var postTextInPut:AnyObserver<String> {
        postTextOutPut.asObserver()
        
    }
    var photoArrayInPut:AnyObserver<[UIImage]> {
        photoArrayOutPut.asObserver()
    }
    
    var validPostDriver:Driver<Bool> = Driver.never()
    var postedDriver:Driver<Bool> = Driver.never()
    
    
    
    
    init(input:(postButtonTap:Signal<()>,text:Driver<String>),userName:String,userImage:String,passedUid:String,roomID:String,postAPI:PostAPI) {
        
        
        PostButtonValidation()
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
    
