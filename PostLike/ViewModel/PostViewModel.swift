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
import UIKit

protocol PostViewModelInputs {
    var text: BehaviorRelay<String> { get }
    var photos: BehaviorRelay<[UIImage]> { get }
}

protocol PostViewModelOutputs {
    var isPostButtonEnabled: Driver<Bool> { get }
    var isAlbumButtonEnabled: Driver<Bool> { get }
    var imageCountDriver: Driver<Int> { get }
    var outputPhotos: Driver<[UIImage]> { get }
    var isPosted: Driver<Bool> { get }
    var postError: Driver<Error> { get }
}

protocol PostViewModelType {
    var inputs: PostViewModelInputs { get }
    var outputs: PostViewModelOutputs { get }
}

final class PostViewModel: PostViewModelType, PostViewModelInputs, PostViewModelOutputs {
    
    var inputs: PostViewModelInputs { return self }
    var outputs: PostViewModelOutputs { return self }
    
    //MARK: - Inputs
    var text = BehaviorRelay<String>.init(value: "")
    var photos = BehaviorRelay<[UIImage]>.init(value: [])
    
    //MARK: - Outputs
    var isPostButtonEnabled: Driver<Bool>
    var isAlbumButtonEnabled: Driver<Bool>
    var isPosted: Driver<Bool> = Driver.never()
    var postError: Driver<Error> = Driver.never()
    var imageCountDriver:Driver<Int>
    var outputPhotos: Driver<[UIImage]>
    
    private let disposeBag = DisposeBag()
    
    
    
    
    init(input:(postButtonTap:Signal<()>,albumButtonTap:Signal<()>),userName:String,userImage:String,passedUid:String,roomID:String, postAPI: PostAPI) {
        
        
        //テキストまたは写真があれば投稿ボタンを有効にする
        isPostButtonEnabled = Observable.combineLatest(text, photos)
            .map { (text, photos)  in
                return text != "" || !photos.isEmpty
            }
            .asDriver(onErrorDriveWith: .empty())
        
        
        //写真が２個より少なければアルバムボタンを有効にする
        isAlbumButtonEnabled = photos.asObservable()
            .map { photos in
                return photos.count < 2
            }
            .asDriver(onErrorDriveWith: .empty())
        
        
        //アルバムボタンが押されるたび現在の写真の数を通知する
        imageCountDriver = input.albumButtonTap.asObservable()
            .withLatestFrom(photos.asObservable())
            .map { photos in
                return photos.count
            }
            .asDriver(onErrorDriveWith: .empty())
        
        
        //写真をアウトプット
        outputPhotos = photos.asDriver(onErrorJustReturn: [])
        
        
        //投稿処理
        post(postButtonTap: input.postButtonTap, userName: userName, userImage: userImage, passedUid: passedUid, roomID: roomID, postAPI: postAPI)
        
        
    }
    
    
    
    
    
    func post(postButtonTap:Signal<()>,userName:String,userImage:String,passedUid:String,roomID:String, postAPI: PostAPI) {
        let combinedObservable = Observable.combineLatest(text.asObservable(), photos.asObservable())
        
        let result = postButtonTap
            .asObservable()
            .withLatestFrom(combinedObservable)
            .flatMapLatest { (text, photos) -> Observable<Bool> in
                return postAPI.post(userName: userName, userImage: userImage, text: text, passedUid: passedUid, roomID: roomID, imageArray: photos)
            }
            .materialize()
            .share(replay: 1)
            
        isPosted = result
            .filter { $0.event.element == true }
            .map { $0.event.element ?? false }
            .asDriver(onErrorJustReturn: false)
            
        postError = result
            .compactMap { $0.event.error }
            .asDriver(onErrorDriveWith: .empty())
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
        var items = photos.value
        items.remove(at: row)
        photos.accept(items)
    }
    
    
    
    

    
    
}
    
