//
//  SearchViewController.swift
//  postLike
//
//  Created by taichi on 2020/11/21.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import RxSwift
import FirebaseFirestore
import FirebaseAuth
import InstantSearchClient


final class SearchViewController: UIViewController, UIGestureRecognizerDelegate {
    
    private enum TableType:String {
        case history
        case result
    }
    
    private var roomArrray = [Room]()
    private var resultArray = [Result]()
    private var historyArray = [Contents]()
    private var cellIdentifier = ""
    private var label = MessageLabel()
    private var timer: Timer?
    private var viewModel: SearchViewModel!
    private let disposeBag = DisposeBag()
    
    
    @IBOutlet private weak var resultTableView: UITableView! {
        didSet {
            resultTableView.delegate = self
            resultTableView.dataSource = self
            resultTableView.register(UINib(nibName: "SearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: "SearchResultTableViewCell")
        }
    }
    
    @IBOutlet private weak var searchField: UISearchBar! {
        didSet {
            searchField.backgroundImage = UIImage()
        }
    }
    
    @IBOutlet private weak var historyTableView: UITableView! {
        didSet {
            historyTableView.delegate = self
            historyTableView.dataSource = self
            historyTableView.register(UINib(nibName: "SearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: "SearchResultTableViewCell")
        }
    }
    
    @IBOutlet private weak var topCreateRoomButton: UIButton! {
        didSet {
            topCreateRoomButton.layer.cornerRadius = 15
            topCreateRoomButton.clipsToBounds = true
        }
    }
    @IBOutlet private weak var backView: UIView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var searchBackView: UIView!
    @IBOutlet private weak var topViewHeight: NSLayoutConstraint!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        setupBinds()
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchHistory()
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    
    
    @IBAction private func createRoom(sender: UIButton) {
        let createRoomVC = storyboard?.instantiateViewController(withIdentifier: "createRoomVC") as! CreateRoomViewController
        createRoomVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(createRoomVC, animated: true)
    }
    
    
    
    
    
    
    
}



// MARK: - RxSwift Method
extension SearchViewController {
    
    private func setupBinds() {
        viewModel = SearchViewModel(text: searchField.rx.text.orEmpty.asDriver())
        fetchResult()
        resultEmptyCheck()
        searchFieldEmptyCheck()
        didTapCancelButton()
        keyboardWillShow()
        
    }
    
    //検索結果を取得
    private func fetchResult() {
        viewModel.resultDriver
            .drive { [weak self] result in
                self?.resultArray.removeAll()
                self?.resultArray.append(contentsOf: result)
                self?.resultTableView.reloadData()
            }
            .disposed(by: disposeBag)
    }
    
    //結果が空かどうかをチェック
    private func resultEmptyCheck() {
        viewModel.isResultEmpty
            .drive { [weak self] bool in
                switch bool {
                case true:
                    self?.resultTableView.isHidden = false
                    self?.backView.isHidden = true
                    self?.label.setupLabel(view: self!.view, y: self!.view.center.y - 200)
                    self?.resultTableView.addSubview(self!.label)
                    self?.label.text = "ルームが見つかりませんでした"
                    
                case false:
                    self?.resultTableView.isHidden = false
                    self?.backView.isHidden = true
                    self?.label.text = ""
                }
            }
            .disposed(by: disposeBag)
    }
    
    //searchFieldが空かどうかをチェック
    private func searchFieldEmptyCheck() {
        viewModel.isTextEmpty
            .drive { [weak self] bool in
                if bool {
                    self?.resultTableView.isHidden = true
                    self?.backView.isHidden = false
                }
            }
            .disposed(by: disposeBag)
    }
    
    //キャンセルボタンを押した時の処理
    private func didTapCancelButton() {
        searchField.rx.cancelButtonClicked
            .subscribe { [weak self] _ in
                self?.searchField.setShowsCancelButton(false, animated: true)
                self?.searchField.resignFirstResponder()
                self?.searchField.text = ""
                self?.resultTableView.isHidden = true
                self?.backView.isHidden = false
                UIView.animate(withDuration: 0.3) {
                    self?.containerView.alpha = 1
                    self?.topViewHeight.constant = 50
                    self?.view.layoutIfNeeded()
                }
            }
            .disposed(by: disposeBag)
    }
    
    //キーボードが表示された時の処理
    private func keyboardWillShow() {
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification, object: nil)
            .subscribe({ [weak self] notificationEvent in
                guard let notification = notificationEvent.element else { return }
                guard let userInfo = notification.userInfo as? [String:Any] else {
                    return
                }
                guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                    return
                }
                UIView.animate(withDuration: duration) {
                    self?.searchField.setShowsCancelButton(true, animated: true)
                    UIView.animate(withDuration: 0.2) {
                        self?.containerView.alpha = 0
                        self?.topViewHeight.constant = 0
                        self?.view.layoutIfNeeded()
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
}








// MARK: - Firestore Method
extension SearchViewController {
    
    //履歴を取得
    private func fetchHistory(){
        self.historyArray.removeAll()
        Firestore.fetchHistroy { contents in
            if contents.isEmpty == true {
                self.label.setupLabel(view: self.view, y: self.view.center.y - 200)
                self.historyTableView.addSubview(self.label)
                self.label.text = "ルームを検索、作成してみよう！"
            }else{
                self.label.removeFromSuperview()
                self.historyArray.append(contentsOf: contents)
                self.historyTableView.reloadData()
            }
        }
    }
    
    //履歴を作成
    private func createHistory(roomImageUrl:String,roomName:String,documentID:String){
        let dic = [
            "roomImage":roomImageUrl,
            "roomName":roomName,
            "documentID":documentID,
            "createdAt":Timestamp()] as [String : Any]
        Firestore.createHistory(documentID: documentID, dic: dic)
    }
    
    //履歴を削除
    @objc private func deleteContent(_ sender:UIButton){
        let documentID = historyArray[-sender.tag].documentID
        Firestore.deleteHistory(documentID: documentID) {
            self.historyArray.remove(at: -sender.tag)
            self.historyTableView.reloadData()
            if self.historyArray.isEmpty == true {
                self.label.setupLabel(view: self.view, y: self.view.center.y - 200)
                self.label.text = "ルームを検索、作成してみよう！"
                self.historyTableView.addSubview(self.label)
            }
        }
    }
    
}









// MARK: - UITableView Method
extension SearchViewController: UITableViewDelegate,UITableViewDataSource{
    
    private func idetifyTable(_ tableView:UITableView) -> Void{
        if tableView.tag == 10 {
            cellIdentifier = TableType.history.rawValue
        }
        else if tableView.tag == 11 {
            cellIdentifier = TableType.result.rawValue
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        idetifyTable(tableView)
        if cellIdentifier == TableType.history.rawValue {
            return historyArray.count
        }
        else if cellIdentifier == TableType.result.rawValue {
            return resultArray.count
        }
        return Int()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        idetifyTable(tableView)
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultTableViewCell", for: indexPath) as! SearchResultTableViewCell
        if cellIdentifier == TableType.history.rawValue {
            let btn = UIButton()
            let btnImage = UIImage(systemName: "xmark")
            btn.tag = -indexPath.row
            btn.sizeToFit()
            btn.setImage(btnImage, for: .normal)
            btn.addTarget(self, action: #selector(deleteContent(_:)), for: .touchUpInside)
            btn.tintColor = .black
            cell.accessoryView = btn
            cell.setupCell(roomName: historyArray[indexPath.row].roomName, roomImage: historyArray[indexPath.row].roomImage, roomIntro: historyArray[indexPath.row].roomIntro)
            
        }else if cellIdentifier == TableType.result.rawValue {
            cell.setupCell(roomName: resultArray[indexPath.row].roomName, roomImage: resultArray[indexPath.row].roomImage, roomIntro: resultArray[indexPath.row].roomIntro)
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = storyboard?.instantiateViewController(withIdentifier: "detailVC") as! RoomDetailViewController
        idetifyTable(tableView)
        if cellIdentifier == TableType.history.rawValue {
            detailVC.passedDocumentID = historyArray[indexPath.row].documentID
            
        }else if cellIdentifier == TableType.result.rawValue {
            detailVC.passedDocumentID = resultArray[indexPath.row].documentID
            createHistory(roomImageUrl: resultArray[indexPath.row].roomImage, roomName: resultArray[indexPath.row].roomName, documentID: resultArray[indexPath.row].documentID)
        }
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
}


// MARK: - UIScrollViewDelegate Method
extension SearchViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if historyTableView.isDragging == true || resultTableView.isDragging == true {
            searchField.resignFirstResponder()
        }
    }
}



