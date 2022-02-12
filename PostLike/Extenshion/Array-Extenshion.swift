//
//  ArrayChunk.swift
//  PostLike
//
//  Created by taichi on 2021/08/25.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit

extension Array {
    subscript (safe index: Index) -> Element? {
        //indexが配列内なら要素を返し、配列外ならnilを返す（三項演算子）
        return indices.contains(index) ? self[index] : nil
    }
}
