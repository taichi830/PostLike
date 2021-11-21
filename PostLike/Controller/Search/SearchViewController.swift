//
//  SearchViewController.swift
//  postLike
//
//  Created by taichi on 2020/11/21.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import Firebase
import InstantSearchClient


class SearchViewController: UIViewController,UITextFieldDelegate,UISearchBarDelegate {
    
    
    
    var roomArrray = [Room]()
    var resultArray = [Post_Like]()
    var historyArray = [Contents]()
    var cellIdentifier = ""
    var label = UILabel()
    var timer: Timer?
    
    
    
    @IBOutlet weak var resultTableView: UITableView!
    @IBOutlet weak var searchField: UISearchBar!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var separateView: UIView!
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var topCreateRoomButton: UIButton!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var searchBackView: UIView!
    @IBOutlet weak var topViewHeight: NSLayoutConstraint!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        historyTableView.delegate = self
        historyTableView.dataSource = self
        resultTableView.delegate = self
        resultTableView.dataSource = self
        
        searchField.delegate = self
        searchField.backgroundImage = UIImage()
        
        headerView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        resultTableView.tableHeaderView = headerView
        
        headerView.isHidden = true
        
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
    
    
    
    
    @objc func keybordWillShow(_ notification: Notification) {
        searchField.setShowsCancelButton(true, animated: true)
        UIView.animate(withDuration: 0.2) {
            self.containerView.alpha = 0
            self.topViewHeight.constant = 0
            self.view.layoutIfNeeded()
        }
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
    

    
    
    
    
    
    
    
    func emptyCheckOfSearchField(searchText:String){
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
        }
    }
    
    
    
    
    
    func callAlgolia(searchText:String){
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
            index.search(query, completionHandler: { (content, err) -> Void in
                self.resultArray.removeAll()
                if let err = err {
                    print(err)
                    return
                } else {
                    guard let content = content else { fatalError("no content") }
                    let data = try! JSONSerialization.data(withJSONObject: content, options: .prettyPrinted)
                    let response = try! JSONDecoder().decode(Hits.self, from: data)
                    for hit in response.hits {
                        self.resultArray.append(hit)
                    }
                    self.resultTableView.reloadData()
                }
            })
        }
    }
    
    
    
    
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let searchText: String = (searchBar.text! as NSString).replacingCharacters(in: range, with: text)
        self.emptyCheckOfSearchField(searchText: searchText)
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(self.call), userInfo: nil, repeats: false)
        return true
    }
    
    
    
    
    
    @objc func call(){
        self.callAlgolia(searchText: searchField.text!)
    }
    
    

    
    
    
    
    func fetchHistory(){
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
    
    
    
    @IBAction func createRoom(_ sender: Any) {
        let createRoomVC = storyboard?.instantiateViewController(withIdentifier: "createRoomVC") as! CreateRoomViewController
        createRoomVC.passedRoomName = searchField.text!
        createRoomVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(createRoomVC, animated: true)
    }
    
    
    
    @IBAction func createRoom2(_ sender: Any) {
        let createRoomVC = storyboard?.instantiateViewController(withIdentifier: "createRoomVC") as! CreateRoomViewController
        createRoomVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(createRoomVC, animated: true)
    }
    
    
    
    
    
    
}







extension SearchViewController: UITableViewDelegate,UITableViewDataSource{
    
    func idetifyTable(_ tableView:UITableView) -> Void{
        if tableView.tag == 10 {
            cellIdentifier = "history"
        }
        else if tableView.tag == 11 {
            cellIdentifier = "result"
        }
    }
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        idetifyTable(tableView)
        if cellIdentifier == "history" {
            return historyArray.count
        }
        else if cellIdentifier == "result" {
            return resultArray.count
        }
        return Int()
    }
    
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        idetifyTable(tableView)
        if cellIdentifier == "history"{
            let cell = historyTableView.dequeueReusableCell(withIdentifier: "history", for: indexPath)
            let historyImage = cell.viewWithTag(1) as!
                UIImageView
            let personsImage = cell.viewWithTag(2) as! UIImageView
            let historyName = cell.viewWithTag(3) as! UILabel
            let contentView = cell.viewWithTag(4)!
            
            if historyArray[indexPath.row].roomImage != "" {
                historyImage.sd_setImage(with: URL(string: historyArray[indexPath.row].roomImage), completed: nil)
                personsImage.image = UIImage()
            }else{
                historyImage.image = UIImage()
                historyImage.backgroundColor = .systemGray5
                personsImage.image =  UIImage(systemName: "person.3.fill")
            }
            historyImage.layer.cornerRadius = historyImage.frame.height/2
            historyImage.layer.borderWidth = 1
            historyImage.layer.borderColor = UIColor.systemGray5.cgColor
            
            historyName.text = historyArray[indexPath.row].roomName
            
            for subView in contentView.subviews{
                if let deleteButton = subView as? UIButton{
                    deleteButton.tag = -indexPath.row
                    deleteButton.addTarget(self, action: #selector(deleteContent(_:)), for: .touchUpInside)
                }
            }
            

            return cell
            
        }else if cellIdentifier == "result"{
            let cell = resultTableView.dequeueReusableCell(withIdentifier: "result", for: indexPath)
            
            let roomImage = cell.viewWithTag(5) as! UIImageView
            let personsImage = cell.viewWithTag(6) as! UIImageView
            let resultLabel = cell.viewWithTag(7) as! UILabel
            
            resultLabel.text = resultArray[indexPath.row].roomName
            
            if resultArray[indexPath.row].roomImage != "" {
                roomImage.sd_setImage(with: URL(string: resultArray[indexPath.row].roomImage), completed: nil)
                personsImage.image =  UIImage()
            }else{
                roomImage.image = UIImage()
                roomImage.backgroundColor = .systemGray5
                personsImage.image =  UIImage(systemName: "person.3.fill")
            }
            roomImage.layer.borderWidth = 1
            roomImage.layer.borderColor = UIColor.systemGray5.cgColor
            roomImage.layer.cornerRadius = roomImage.frame.height/2
            
            if resultArray.isEmpty == true {
                headerView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            }else{
                headerView.frame = CGRect(x: 0, y: 106, width: self.view.frame.size.width, height: 138)
            }
            
            if searchField.text == resultLabel.text {
                
                headerView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
                alertLabel.isHidden = true
                createButton.isHidden = true
                createButton.isEnabled = false
                separateView.isHidden = true
                
            }else  if searchField.text != resultLabel.text || resultArray.isEmpty == true  {
                alertLabel.text = "\"\(searchField.text!)\" のルームが見つかりませんでした。"
                headerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 138)
                alertLabel.isHidden = false
                createButton.isHidden = false
                createButton.isEnabled = true
                separateView.isHidden = false
            }
            
            return cell
        }
        return UITableViewCell()
    }
    
    
    
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = storyboard?.instantiateViewController(withIdentifier: "detailVC") as! RoomDetailViewController
        idetifyTable(tableView)
        if cellIdentifier == "history"{
            
            detailVC.passedDocumentID = historyArray[indexPath.row].documentID
            
        }else if cellIdentifier == "result"{
            detailVC.passedDocumentID = resultArray[indexPath.row].documentID
            createHistory(roomImageUrl: resultArray[indexPath.row].roomImage, roomName: resultArray[indexPath.row].roomName, documentID: resultArray[indexPath.row].documentID)
        }
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    
    
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 77
    }
    
    
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    
    
    @objc func deleteContent(_ sender:UIButton){
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
    
    
    
    func createHistory(roomImageUrl:String,roomName:String,documentID:String){
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



