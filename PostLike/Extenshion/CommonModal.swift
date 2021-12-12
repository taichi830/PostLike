//
//  CommonModal.swift
//  PostLike
//
//  Created by taichi on 2021/12/04.
//  Copyright © 2021 taichi. All rights reserved.
//

import Foundation
import UIKit



final class CommonModal {
    

    static let shared = CommonModal()
    
    private let elements = [
        (type:ModalType.post.rawValue,text:["投稿を報告・ミュートする","ユーザーを報告・ブロックする","キャンセル"],image:["square.slash","person","xmark"]),
        (type:ModalType.room.rawValue,text:["シェアする","ルームを報告する","キャンセル"],image:["square.and.arrow.up","flag","xmark"]),
        (type:ModalType.exit.rawValue,text:["ルームを退出する","キャンセル"],image:["arrowshape.turn.up.right","xmark"]),
        (type:ModalType.delete.rawValue,text:["投稿を削除する","キャンセル"],image:["trash","xmark"]),
        (type:ModalType.moderator.rawValue,text:["ルームを退出する","ルームを削除する","キャンセル"],image:["arrowshape.turn.up.right","trash","xmark"])
    ]
    
    func items(type:ModalType,label:UILabel,imageView:UIImageView,row:Int){
        let element = elements.filter { element in
            element.type == type.rawValue
        }
        imageView.image = UIImage(systemName: element[0].image[row])
        label.text = element[0].text[row]
    }
    
    
}
