//
//  NotificationViewController.swift
//  postLike
//
//  Created by taichi on 2021/03/09.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Firebase

final class NotificationViewController: UIViewController {
    

    
    @IBOutlet private weak var notificationTableView: UITableView!
    @IBOutlet private weak var latestLabel: UILabel!
    @IBOutlet private weak var headerView: UIView!
    
    
    private var label = MessageLabel()
    private var viewModel: NotificationViewModel!
    private let disposeBag = DisposeBag()
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = NotificationViewModel(notificationListner: NotificationDefaultListner())
        notificationTableView.tableHeaderView = headerView
        notificationTableView.register(UINib(nibName: "NotificationTableViewCell", bundle: nil), forCellReuseIdentifier: "NotificationTableViewCell")
        notificationTableView.rowHeight = UITableView.automaticDimension
        fetchNotifications()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UserDefaults.standard.setValue(0, forKey: "badgeCount")
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    
    private func fetchNotifications() {
        viewModel.items
            .drive(notificationTableView.rx.items(cellIdentifier: "NotificationTableViewCell", cellType: NotificationTableViewCell.self)) { (row, item, cell) in
                cell.setupCell(notification: item)
            }
            .disposed(by: disposeBag)
        
        viewModel.isEmpty.drive { [weak self] bool in
            self?.latestLabel.isHidden = bool
        }
        .disposed(by: disposeBag)
    }
    
}

