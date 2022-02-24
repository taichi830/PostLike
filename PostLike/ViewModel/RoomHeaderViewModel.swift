//
//  RoomHeaderViewModel.swift
//  PostLike
//
//  Created by taichi on 2022/02/24.
//  Copyright © 2022 taichi. All rights reserved.
//

import RxSwift
import RxCocoa
import Firebase

final class RoomHeaderViewModel {
    private let disposeBag = DisposeBag()
    let userInfo: Driver<Contents>
    let isJoined: Driver<Bool>
    let roomInfo: Driver<Room>
    
    init(userListner: UserListner, roomInfoListner: RoomInfoListner, roomID: String) {
        let listner = userListner.createUserListner(roomID: roomID)
        
        userInfo = listner.debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .asDriver(onErrorDriveWith: Driver.empty())
        
        isJoined = userInfo.asObservable()
            .map { content -> Bool in
                return content.isJoined
            }
            .asDriver(onErrorJustReturn: false)
        
        
        let roomInfoListner = roomInfoListner.fetchRoomInfo(roomID: roomID)
        
        roomInfo = roomInfoListner.debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .asDriver(onErrorDriveWith: Driver.empty())
        
        
    }
}


