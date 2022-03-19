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
    
    private var postTextOutPut = PublishSubject<String>()
    private var photoArrayOutPut = BehaviorSubject<[UIImage]>.init(value: [])
    
    private var validPostSubject = BehaviorSubject<Bool>.init(value: false)
    private var validAddImageSubject = BehaviorSubject<Bool>.init(value: true)
    private var postCompletedSubject = PublishSubject<Bool>()
    private var imageArrayCountSubject = BehaviorSubject<Int>.init(value: 0)
    
    
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
    var latestContent: Driver<Contents> = Driver.never()
    
    
    
    
    init(input:(postButtonTap:Signal<()>,text:Driver<String>,albumButtonTap:Signal<()>),userName:String,userImage:String,passedUid:String,roomID:String,postAPI:PostAPI) {
        
        
        PostButtonValidation(text: input.text)
        alubumButtonValidation(alubumButtonTap: input.albumButtonTap)
        post(postButtonTap: input.postButtonTap, text: input.text, userName: userName, userImage: userImage, passedUid: passedUid, roomID: roomID, postAPI: postAPI)
 
    }
    
    
    
    
    
    
    
    
    private func PostButtonValidation(text:Driver<String>) {
        validPostDriver = validPostSubject
            .asDriver(onErrorJustReturn: false)
        
        let validPostText = text
            .asObservable()
            .map { text -> Bool in
                return text != ""
            }
            
        let validPhotoArray = photoArrayOutPut
            .asObservable()
            .map { photos -> Bool in
                return photos != []
            }
        
        Observable.combineLatest(validPostText, validPhotoArray) { $0 || $1 }
            .subscribe { bool in
                self.validPostSubject.onNext(bool)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    private func alubumButtonValidation(alubumButtonTap:Signal<()>) {
        
        validAddImageDriver = validAddImageSubject
            .asDriver(onErrorJustReturn: false)
        
        let validAddImage = photoArrayOutPut
            .asObservable()
            .map { imageArray -> Bool in
                return imageArray.count < 2
            }
        
        validAddImage.subscribe { [weak self] bool in
                self?.validAddImageSubject.onNext(bool)
            }
            .disposed(by: disposeBag)
        

        
        imageCountDriver = imageArrayCountSubject.asDriver(onErrorDriveWith: Driver.empty())
        
        let imageArrayCountObservable = photoArrayOutPut
            .asObservable()
            .map { imageArray -> Int in
                return imageArray.count
            }
        
        alubumButtonTap.asObservable()
            .withLatestFrom(imageArrayCountObservable)
            .subscribe { [weak self] count in
                self?.imageArrayCountSubject.onNext(count)
            }
            .disposed(by: disposeBag)
            
    }
    
    
    
    
    
    
    
    
    
    private func post(postButtonTap:Signal<()>,text:Driver<String>,userName:String,userImage:String,passedUid:String,roomID:String,postAPI:PostAPI) {
        
        postedDriver = postCompletedSubject.asDriver(onErrorJustReturn: false)
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
    
    
    
    
    
    
    func fetchMyLatestPost(feedListner: GetPosts ,roomID:String) {
        feedListner.fetchMyLatestPost(roomID: roomID)
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            .subscribe{ content in
                LatestContentsSubject.shared.latestFeedContents.accept(content)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    
    func remove(row:Int) {
        do {
            var items = try photoArrayOutPut.value()
            items.remove(at: row)
            photoArrayOutPut.onNext(items)
        } catch {
            return
        }
        
    }

    
    
}
    
