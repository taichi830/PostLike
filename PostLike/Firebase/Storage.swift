//
//  Storage.swift
//  PostLike
//
//  Created by taichi on 2021/12/22.
//  Copyright © 2021 taichi. All rights reserved.
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseFirestore

extension Storage {
    //プロフィール画像を保存
    static func addUserImageToStrage(userImage:UIImage,self:UIViewController,completion: @escaping (String) -> Void) {
        let fileName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_images").child(fileName)
        guard let updateImage = userImage.jpegData(compressionQuality: 0.2) else {return}
        storageRef.putData(updateImage, metadata: nil) { (metadata, err) in
            if let err = err{
                print("Firestorageへの保存に失敗しました。\(err)")
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }else{
                print("Firestorageへの保存に成功しました。")
                storageRef.downloadURL { (url, err) in
                    if let err = err {
                        print("firestorageからのダウンロードに失敗しました。\(err)")
                        let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                            self.dismissIndicator()
                        }
                        self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                        return
                    }
                    guard let urlString = url?.absoluteString else { return }
                    completion(urlString)
                }
            }
        }
    }
    
    
    
    //ルーム画像を保存
    static func addRoomImageToStrage(roomImage:UIImage,self:UIViewController,completion: @escaping (String) -> Void) {
        let fileName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("room_images").child(fileName)
        guard let updateImage = roomImage.jpegData(compressionQuality: 0.4) else {return}
        storageRef.putData(updateImage, metadata: nil) { metadata, err in
            if let err = err {
                print("Firestorageへの保存に失敗しました。\(err)")
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }else{
                print("Firestorageへの保存に成功しました。")
                storageRef.downloadURL { (url, err) in
                    if let err = err {
                        print("firestorageからのダウンロードに失敗しました。\(err)")
                        let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                            self.dismissIndicator()
                        }
                        self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                        return
                    }
                    guard let urlString = url?.absoluteString else { return }
                    completion(urlString)
                }
            }
        }
    }
    
    
    //ストレージにある画像データを削除
    static func deleteStrage(roomImageUrl:String) {
        let storage = Storage.storage()
        let imageRef = NSString(string: roomImageUrl)
        let desertRef = storage.reference(forURL: imageRef as String)
        desertRef.delete { err in
            if let err = err {
                print("err:",err)
                return
            }else{
                print("success")
            }
        }
    }
    
    
    //投稿画像を保存
    static func addPostImagesToStrage(imagesArray:[UIImage], completion: @escaping (Bool,[String]) -> Void) {
        
        var urlStringArray = [String]()
        
        for image in imagesArray {
            let posting = image.jpegData(compressionQuality: 0.3)
            let fileName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("images").child("\(fileName).jpg")
            let metaData = StorageMetadata()
            metaData.contentType = "image.jpeg"
            storageRef.putData(posting ?? Data(), metadata: metaData){ (metadata,err) in
                
                if let err = err {
                    print("Storageへの保存に失敗しました。\(err)")
                    completion(false,[""])
                    return
                }else{
                    print("Storageへの保存に成功しました")
                    storageRef.downloadURL { (url, err) in
                        if let err = err{
                            print("ダウンロードに失敗しました。\(err)")
                            completion(false,[""])
                            return
                        }else{
                            guard let urlString = url?.absoluteString else{return}
                            urlStringArray.append(urlString)
                            if imagesArray.count == urlStringArray.count {
                                completion(true,urlStringArray)
                            }
                        }
                    }
                }
            }
        }
    }
    
    //投稿画像を削除
    static func deleteStrageFile(imageUrl:Array<String>){
        for url in imageUrl {
            let storage = Storage.storage()
            let imageRef = NSString(string: url)
            let desertRef = storage.reference(forURL: imageRef as String)
            desertRef.delete { err in
                if err != nil {
                    print("false")
                    return
                }else{
                    print("success")
                }
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
}
