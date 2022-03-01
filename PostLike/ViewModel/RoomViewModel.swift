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
        
        rooms = roomListner.fetchRooms()
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            .asDriver(onErrorJustReturn: [])
        
        isEmpty = rooms.compactMap{ rooms in
            return rooms.isEmpty
        }
        .asDriver(onErrorJustReturn: true)
    }
    
}
