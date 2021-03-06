//
//  CommentViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/02/07.
//  Copyright © 2022 taichi. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Firebase

final class CommentViewModel {
    private let disposeBag = DisposeBag()
    
    let itemsRelay = BehaviorRelay<[Contents]>.init(value: [])
    var items: Driver<[Contents]> = Driver.never()
    
    var isEmpty: Driver<Bool> = Driver.never()
    
    var isBottomSubject = PublishSubject<()>()
    var isBottomObserver: AnyObserver<()> {
        isBottomSubject.asObserver()
    }
    
    init (commentListner: GetComments, documentID: String, roomID: String) {
        
        // itemsRelayをdriverに紐付け
        items = itemsRelay.asDriver(onErrorJustReturn: [])
        
        // コメントを取得
        let fetchComments = commentListner.fetchComments(documentID: documentID)
            .share(replay: 1)
        
        // 取得したコメントをitemsRelayにアクセプト
        fetchComments.asObservable()
            .subscribe { [weak self] items in
                self?.itemsRelay.accept(items)
            }
            .disposed(by: disposeBag)
        
        // 取得したコメントが空かどうかチェック
        isEmpty = itemsRelay
            .skip(1) //itemsRelayの初期値をスキップ
            .map { contents -> Bool in
            return contents.isEmpty
        }
        .asDriver(onErrorJustReturn: true)
        
        //最下部に来た時、追加でコメントを追加する
        isBottomSubject.asObservable()
            .concatMap{ _ -> Observable<[Contents]> in
                return commentListner.fetchMoreComments(documentID: documentID)
            }
            .subscribe { [weak self] items in
                guard let element = items.element else { return }
                let currentItems = self?.itemsRelay.value ?? []
                self?.itemsRelay.accept(currentItems + element)
            }
            .disposed(by: disposeBag)
        
        //コメントを投稿した時リアルタイムで取得
        commentListner.fetchMyLatestComment(roomID: roomID).asObservable()
            .subscribe { [weak self] items in
                guard let element = items.element else { return }
                let currentItems = self?.itemsRelay.value ?? []
                self?.itemsRelay.accept(element + currentItems)
            }
            .disposed(by: disposeBag)
            
        
        
    }
}
