//
//  Alert+RxExtension.swift
//  PostLike
//
//  Created by taichi on 2022/05/08.
//  Copyright © 2022 taichi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UIViewController {
    var showErrorAlert: Binder<Error?> {
        return Binder(self.base) { (target,value) in
            if let error = value {
                let alertController = UIAlertController(title: "エラーが発生しました", message: error.localizedDescription, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .cancel) { _ in
                    base.dismiss(animated: true, completion: nil)
                }
                alertController.addAction(okAction)
                target.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
