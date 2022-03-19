//
//  RoomViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/03/02.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa

final class RoomViewModel {
    let rooms: Driver<[Contents]>
    let isEmpty: Driver<Bool>
    
    init(roomListner: RoomListner) {
        //ルームを取得
        let fetchRooms = roomListner.fetchRooms().share(replay: 1)
        //取得したルームをdriverに紐付け
        rooms = fetchRooms.asDriver(onErrorJustReturn: [])
        //ルームが空かどうかをチェック
        isEmpty = fetchRooms.compactMap { rooms in
            return rooms.isEmpty
        }
        .asDriver(onErrorJustReturn: true)
    }
    
}
