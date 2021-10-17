//
//  Response.swift
//  postLike
//
//  Created by taichi on 2021/02/27.
//  Copyright © 2021 taichi. All rights reserved.
//

import Foundation

struct Hits: Codable {
    let hits: [Post_Like]
}

struct Post_Like: Codable {
    let objectID: String
    let roomName: String
    let roomImage: String
    let documentID : String
    let roomIntro: String
}

