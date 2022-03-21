//
//  ModalViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/03/13.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift

struct ModalViewModel {
    var items = PublishSubject<[Menu]>()
    
    func fetchItems() {
        let menu = [
            Menu(type: .post,
                 item: [
                    Item(title: "投稿を報告・ミュートする", imageUrl: "square.slash", type: .mute),
                    Item(title: "ユーザーを報告・ブロックする", imageUrl: "person", type: .block),
                    Item(title: "キャンセル", imageUrl: "xmark", type: .cancel)
                 ]),
            Menu(type: .room,
                 item: [
                    Item(title: "シェアする", imageUrl: "square.and.arrow.up", type: .share),
                    Item(title: "ルームを報告する", imageUrl: "flag", type: .report),
                    Item(title: "キャンセル", imageUrl: "xmark", type: .cancel)
                 ]),
            Menu(type: .exit,
                 item: [
                    Item(title: "ルームを退出する", imageUrl: "arrowshape.turn.up.right", type: .exit),
                    Item(title: "キャンセル", imageUrl: "xmark", type: .cancel)
                 ]),
            Menu(type: .delete,
                 item: [
                    Item(title: "投稿を削除する", imageUrl: "trash", type: .deletePost),
                    Item(title: "キャンセル", imageUrl: "xmark", type: .cancel)
                 ]),
            Menu(type: .moderator,
                 item: [
                    Item(title: "ルームを退出する", imageUrl: "arrowshape.turn.up.right", type: .exit),
                    Item(title: "ルームを削除する", imageUrl: "trash", type: .deleteRoom),
                    Item(title: "キャンセル", imageUrl: "xmark", type: .cancel)
                 ])
        ]
        
        items.onNext(menu)
        items.onCompleted()
    }
}
