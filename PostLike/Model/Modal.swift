//
//  Modal.swift
//  PostLike
//
//  Created by taichi on 2022/03/13.
//  Copyright © 2022 taichi. All rights reserved.
//

import Foundation


enum ModalType: String {
    case post
    case room
    case exit
    case delete
    case moderator
}


enum ItemType {
    case mute
    case block
    case cancel
    case share
    case report
    case exit
    case deletePost
    case deleteRoom
}


struct Menu {
    let type: ModalType
    let item: [Item]
}

struct Item {
    let title: String
    let imageUrl: String
    let type: ItemType
}




