//
//  SearchViewController.swift
//  postLike
//
//  Created by taichi on 2020/11/21.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import InstantSearchClient


final class SearchViewController: UIViewController {
    
    enum TableType:String {
        case history
        case result
    }
    
    var roomArrray = [Room]()
    var resultArray = [Post_Like]()
    var historyArray = [Contents]()
    var cellIdentifier = ""
    var label = UILabel()
    var timer: Timer?
    
    
    
    @IBOutlet private weak var resultTableView: UITableView!
    @IBOutlet private weak var searchField: UISearchBar!
    @IBOutlet private weak var createButton: UIButton!
    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var alertLabel: UILabel!
    @IBOutlet private weak var separateView: UIView!
    @IBOutlet private weak var historyTableView: UITableView!
    @IBOutlet private weak var backView: UIView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var topCreateRoomButton: UIButton!
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var searchBackView: UIView!
    @IBOutlet private weak var topViewHeight: NSLayoutConstraint!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        historyTableView.delegate = self
        historyTableView.dataSource = self
        historyTableView.register(UINib(nibName: "SearchTableViewCell", bundle: nil), forCellReuseIdentifier: "searchTableViewCell")
        
        resultTableView.delegate = self
        resultTableView.dataSource = self
        resultTableView.register(UINib(nibName: "SearchTableViewCell", bundle: nil), forCellReuseIdentifier: "searchTableViewCell")
        
        searchField.delegate = self
        searchField.backgroundImage = UIImage()
        
        headerView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        headerView.isHidden = true
        resultTableView.tableHeaderView = headerView
        
       
        createButton.layer.cornerRadius = 15
        createButton.clipsToBounds = true
        createButton.isEnabled = false
        
        
        topCreateRoomButton.layer.cornerRadius = 15
        topCreateRoomButton.clipsToBounds = true
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchHistory()
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    
    
    @objc private func keybordWillShow(_ notification: Notification) {
        searchField.setShowsCancelButton(true, animated: true)
        UIView.animate(withDuration: 0.2) {
            self.containerView.alpha = 0
            self.topViewHeight.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    
    
    private func emptyCheckOfSearchField(searchText:String){
        if searchText == "" {
            headerView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            headerView.isHidden = true
            resultTableView.isHidden = true
            backView.isHidden = false
        }else{
            alertLabel.text = "\"\(searchText)\" のRoomが見つかりませんでした。"
            headerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 138)
            headerView.isHidden = false
            resultTableView.isHidden = false
            backView.isHidden = true
            createButton.isEnabled = true
        }
    }
    
    
    
    private func fetchHistory(){
        self.historyArray.removeAll()
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).collection("history").order(by: "createdAt", descending: true).limit(to: 10).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("false\(err)")
                return
            }
            for document in querySnapshot!.documents{
                let dic = document.data()
                let historyRoom = Contents.init(dic: dic)
                self.historyArray.append(historyRoom)
            }
            self.label.removeFromSuperview()
            self.label = UILabel(frame: CGRect(x: 0, y: self.view.frame.height/2 - 80, width: self.view.frame.width, height: 30))
            self.label.textAlignment = .center
            self.label.textColor = .lightGray
            self.label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            self.historyTableView.addSubview(self.label)
            if self.historyArray.isEmpty == true {
                self.label.text = "ルームを検索、作成してみよう"
            }else{
                self.label.text = ""
            }
            self.historyTableView.reloadData()
        }
    }
    
    
    
    
    @IBAction private func createRoom(sender: UIButton) {
        let createRoomVC = storyboard?.instantiateViewController(withIdentifier: "createRoomVC") as! CreateRoomViewController
        createRoomVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(createRoomVC, animated: true)
    }
    
    
    
    
    
    
    
}




extension SearchViewController: UISearchBarDelegate {
    
    private func callAlgolia(searchText:String){
        #if DEBUG
        let appID = "AT9Z5755AK"
        let apiKey = "91c505ad021fe4eaf299f4a9d15fbd2b"
        let indexName = "PostLike_dev"
        #else
        let appID = "GICHEEECDF"
        let apiKey = "e66bef3d0dd124854d5137007a5aafc2"
        let indexName = "rooms"
        #endif
    
        let client = Client(appID: appID, apiKey: apiKey)
        let index = client.index(withName: indexName)
        let query = Query(query: searchText)
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if text == "" {
            self.resultArray.removeAll()
            self.resultTableView.reloadData()
        }else{
            index.search(query, completionHandler: { (content,err) -> Void in
                self.resultArray.removeAll()
                do {
                    guard let content = content else { fatalError("no content") }
                    let data = try JSONSerialization.data(withJSONObject: content, options: .prettyPrinted)
                    let response = try JSONDecoder().decode(Hits.self, from: data)
                    self.resultArray.append(contentsOf: response.hits)
                    self.resultTableView.reloadData()
                } catch {
                    print(err ?? "")
                }
            })
        }
    }
    
    
    
    
    @objc private func call(){
        self.callAlgolia(searchText: searchField.text!)
    }
    
    
    
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let searchText: String = (searchBar.text! as NSString).replacingCharacters(in: range, with: text)
        self.emptyCheckOfSearchField(searchText: searchText)
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(call), userInfo: nil, repeats: false)
        return true
    }
    
    
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchField.setShowsCancelButton(false, animated: true)
        searchField.resignFirstResponder()
        searchField.text = ""
        headerView.isHidden = true
        resultTableView.isHidden = true
        backView.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.containerView.alpha = 1
            self.topViewHeight.constant = 50
            self.view.layoutIfNeeded()
        }
    }
    
    
    
    
    
    
    
}




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
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchTableViewCell", for: indexPath) as! SearchTableViewCell
        if cellIdentifier == TableType.history.rawValue {
            cell.setupCell(roomImageUrl: historyArray[indexPath.row].roomImage, roomName: historyArray[indexPath.row].roomName)
            let btn = UIButton()
            let btnImage = UIImage(systemName: "xmark")
            btn.tag = -indexPath.row
            btn.sizeToFit()
            btn.setImage(btnImage, for: .normal)
            btn.addTarget(self, action: #selector(deleteContent(_:)), for: .touchUpInside)
            btn.tintColor = .black
            cell.accessoryView = btn
            
        }else if cellIdentifier == TableType.result.rawValue {
            cell.setupCell(roomImageUrl: resultArray[indexPath.row].roomImage, roomName: resultArray[indexPath.row].roomName)
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
    
    
    
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 77
    }
    
    
    
    
    @objc private func deleteContent(_ sender:UIButton){
        let uid = Auth.auth().currentUser!.uid
        let documentID = historyArray[-sender.tag].documentID
        Firestore.firestore().collection("users").document(uid).collection("history").document(documentID).delete { err in
            if let err = err {
                print("false\(err)")
                return
            }
            print("success")
            self.historyArray.remove(at: -sender.tag)
            self.historyTableView.reloadData()
            if self.historyArray.isEmpty == true {
                self.label.text = "ルームを検索、作成してみよう"
            }
        }
    }
    
    
    
    private func createHistory(roomImageUrl:String,roomName:String,documentID:String){
        let uid = Auth.auth().currentUser!.uid
        let timestamp = Timestamp()
        let docData = ["roomImage":roomImageUrl,"roomName":roomName,"documentID":documentID,"createdAt":timestamp] as [String : Any]
        Firestore.firestore().collection("users").document(uid).collection("history").document(documentID).setData(docData){
            (err) in
            if let err = err {
                print("firestoreへの保存に失敗しました。\(err)")
                return
            }
            print("fireStoreへの保存に成功しました。")
        }
    }
}





extension SearchViewController:UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if historyTableView.isDragging == true || resultTableView.isDragging == true {
            searchField.resignFirstResponder()
        }
    }
}



