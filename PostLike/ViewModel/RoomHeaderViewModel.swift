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
    let isDeleted: Driver<Bool>
    let memberCount: Driver<Room>
    
    init(userListner: UserListner, roomInfoListner: RoomInfoListner, roomID: String) {
        //ユーザー情報を取得
        let userInfoListner = userListner.createUserListner(roomID: roomID).share(replay: 1)
        //取得したユーザー情報をdriverに紐付け
        userInfo = userInfoListner.asDriver(onErrorDriveWith: Driver.empty())
        //ルームに参加しているかチェック
        isJoined = userInfoListner.asObservable()
            .map { content -> Bool in
                return content.isJoined
            }
            .asDriver(onErrorDriveWith: Driver.empty())
        
        //ルーム情報を取得
        let roomListner = roomInfoListner.fetchRoomInfo(roomID: roomID).share(replay: 1)
        //取得したルーム情報をdriverにバインド
        roomInfo = roomListner.asDriver(onErrorDriveWith: Driver.empty())
        //ルームが削除されているかチェック
        isDeleted = roomInfo.asObservable()
            .map{ room -> Bool in
                return room.isDeleted
            }
            .asDriver(onErrorDriveWith: Driver.empty())
        
        //メンバー数を取得
        let memberCountListner = roomInfoListner.fetchMemberCount(roomID: roomID).share(replay: 1)
        memberCount = memberCountListner
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)//複数回呼ばれる可能性があるのでdebounceで制御
            .asDriver(onErrorDriveWith: Driver.empty())
        
        
        
        
        
    }
}


