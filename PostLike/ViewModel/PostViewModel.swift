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
    
    // Inputs
    var text = BehaviorRelay<String>.init(value: "")
    var photos = BehaviorRelay<[UIImage]>.init(value: [])
    
    // Outputs
    var isPostButtonEnabled: Driver<Bool>
    var isAlbumButtonEnabled: Driver<Bool>
    var isPosted: Driver<Bool> = Driver.never()
    var postError: Driver<Error> = Driver.never()
    var imageCountDriver: Driver<Int>
    var outputPhotos: Driver<[UIImage]>
    
    // Private Properties
    private var postButtonTap: Signal<()>
    private var albumButtonTap: Signal<()>
    private var userName: String
    private var userImage: String
    private var passedUid: String
    private var roomID: String
    private var postAPI: PostAPI
    private let disposeBag = DisposeBag()
    
    
    
    
    init(input:(postButtonTap:Signal<()>,albumButtonTap:Signal<()>),userName:String,userImage:String,passedUid:String,roomID:String, postAPI: PostAPI) {
        
        self.postButtonTap = input.postButtonTap
        self.albumButtonTap = input.albumButtonTap
        self.userName = userName
        self.userImage = userImage
        self.passedUid = passedUid
        self.roomID = roomID
        self.postAPI = postAPI
        
        
        // テキストまたは写真があれば投稿ボタンを有効にする
        isPostButtonEnabled = Observable.combineLatest(text, photos)
            .map { (text, photos)  in
                return text != "" || !photos.isEmpty
            }
            .asDriver(onErrorDriveWith: .empty())
        
        
        // 写真が２個より少なければアルバムボタンを有効にする
        isAlbumButtonEnabled = photos.asObservable()
            .map { photos in
                return photos.count < 2
            }
            .asDriver(onErrorDriveWith: .empty())
        
        
        // アルバムボタンが押されるたび現在の写真の数を通知する
        imageCountDriver = input.albumButtonTap.asObservable()
            .withLatestFrom(photos.asObservable())
            .map { photos in
                return photos.count
            }
            .asDriver(onErrorDriveWith: .empty())
        
        
        // 写真をアウトプット
        outputPhotos = photos.asDriver(onErrorJustReturn: [])
        
        
        // 投稿処理
        post()
        
        
    }
    
    
    
    
    
    func post() {
        let combinedObservable = Observable.combineLatest(text.asObservable(), photos.asObservable())
        
        let result = postButtonTap
            .asObservable()
            .withLatestFrom(combinedObservable)
            .flatMapLatest { (text, photos) -> Observable<Bool> in
                return self.postAPI.post(userName: self.userName, userImage: self.userImage, text: text, passedUid: self.passedUid, roomID: self.roomID, imageArray: photos)
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
    
    
    
    
    
    
    func fetchMyLatestPost(feedListner: GetPosts, roomID: String) {
        feedListner.fetchMyLatestPost(roomID: roomID)
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            .subscribe{ content in
                LatestContentsSubject.shared.latestFeedContents.accept(content)
            }
            .disposed(by: disposeBag)
    }
    
    
    
    
    
    
    
    func remove(row: Int) {
        var items = photos.value
        items.remove(at: row)
        photos.accept(items)
    }
    
    
    
    

    
    
}
    
