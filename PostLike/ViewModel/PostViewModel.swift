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
    var isLoading: Driver<Bool> { get }
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
    var imageCountDriver:Driver<Int>
    var isLoading: Driver<Bool> = Driver.never()
    var outputPhotos: Driver<[UIImage]>
    
    private let disposeBag = DisposeBag()
    var isLoadingSubject = PublishSubject<Bool>()
    
    
    
    
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
        isLoading = isLoadingSubject.asDriver(onErrorJustReturn: true)
        let combineObservable = Observable.combineLatest(photos.asObservable(), text.asObservable())
        postButtonTap
            .asObservable()
            .withLatestFrom(combineObservable)
            .flatMapLatest { (photos, text) -> Single<Bool> in
                return postAPI.post(userName: userName, userImage: userImage, text: text, passedUid: passedUid, roomID: roomID, imageArray: photos)
            }
            .subscribe { [weak self] bool in
                switch bool {
                case .next(let bool):
                    self?.isLoadingSubject.onNext(bool)
                case .error(let err):
                    print("保存に失敗しました:", err)
                    self?.isLoadingSubject.onNext(false)
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
        var items = photos.value
        items.remove(at: row)
        photos.accept(items)
    }
    
    
    
    

    
    
}
    
