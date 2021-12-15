//
//  AccountSettingViewController.swift
//  PostLike
//
//  Created by taichi on 2021/12/14.
//  Copyright © 2021 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

final class AccountSettingViewController: UIViewController {
    
    private enum Section:Int {
        case account = 0
        case notification
        case other
    }
    
    @IBOutlet weak var settingMenuTableView: UITableView!
    
    private var userInfo:User?
    private let sections = ["アカウント","通知","その他"]
    private let elements = [
        ["メールアドレス","生年月日","性別"],
        ["通知"],
        ["プライバシーポリシー","利用規約","ログアウト"]
    ]
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationItem.title = "設定"
        navigationController?.navigationBar.barTintColor = .systemBackground
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        
        settingMenuTableView.delegate = self
        settingMenuTableView.dataSource = self
        settingMenuTableView.separatorStyle = .singleLine
        
        fetchUserInfo()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    
    
    private func fetchUserInfo(){
        let uid = Auth.auth().currentUser!.uid
        Firestore.firestore().collection("users").document(uid).getDocument { snapShot, err in
            if let err = err {
                print("false:",err)
                return
            }
            guard let snapShot = snapShot, let dic = snapShot.data() else {return}
            let userInfo = User(dic: dic)
            self.userInfo = userInfo
            self.settingMenuTableView.reloadData()
        }
    }
    
    
    private func alertComfirm(){
        let alert = UIAlertController(title: "ログアウトしてよろしいでしょうか？", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "はい", style: .default, handler: { _ in
            self.logout()
        }))
        alert.addAction(UIAlertAction(title: "いいえ", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    
    private func logout(){
        let auth = Auth.auth()
        do {
            try auth.signOut()
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let navigationVC = storyboard.instantiateViewController(identifier: "navigation") as! UINavigationController
            self.present(navigationVC, animated: false, completion: nil)
            print("success")
            
        } catch let sighOutErr as NSError {
            print ("Error signing out: %@", sighOutErr)
            return
        }
    }
   
    
    
}

extension AccountSettingViewController:UITableViewDelegate,UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .account:
            return elements[section].count
        case .notification:
            return elements[section].count
        case .other:
            return elements[section].count
        default:
            break
        }
        return Int()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.selectionStyle = .none
        
        let label = cell.viewWithTag(1) as! UILabel
        
        switch Section(rawValue: indexPath.section) {
        case .account:
            cell.textLabel?.text = elements[indexPath.section][indexPath.row]
            if indexPath.row == 0 {
                let email = Auth.auth().currentUser!.email
                label.text = email
                
            }else if indexPath.row == 1 {
                 let date = self.userInfo?.birthDay.dateValue()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy/MM/dd"
                let dateString = formatter.string(from: date ?? Date())
                label.text = dateString
                
            }else if indexPath.row == 2 {
                label.text = self.userInfo?.gender
            }
            
            
        case .notification:
            cell.textLabel?.text = elements[indexPath.section][indexPath.row]
            cell.accessoryType = .disclosureIndicator
            UNUserNotificationCenter.current().getNotificationSettings { setting in
                DispatchQueue.main.async {
                    switch setting.authorizationStatus {
                    case .denied:
                        label.text = "オフ"
                    case .authorized:
                        label.text = "オン"
                    default:
                        break
                    }
                }
            }
            
        case .other:
            cell.textLabel?.text = elements[indexPath.section][indexPath.row]
            cell.accessoryType = .disclosureIndicator
            
            
        default:
            break
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section) {
        case .notification:
            let settingsUrl = URL(string: UIApplication.openSettingsURLString)
            if UIApplication.shared.canOpenURL(settingsUrl!)  {
              if #available(iOS 10.0, *) {
                UIApplication.shared.open(settingsUrl!, completionHandler: { (success) in
                })
              }
              else  {
                UIApplication.shared.openURL(settingsUrl!)
              }
            }
        case .other:
            if indexPath.row == 0 {
                let storyboard = UIStoryboard(name: "Login", bundle: nil)
                let privacyPolicyVC = storyboard.instantiateViewController(withIdentifier: "privacyPolicy") as! PrivacyPolicyViewController
                self.navigationController?.pushViewController(privacyPolicyVC, animated: true)
                
            }else if indexPath.row == 1 {
                let storyboard = UIStoryboard(name: "Login", bundle: nil)
                let termOfUseVC = storyboard.instantiateViewController(withIdentifier: "termOfUse") as! TermOfUseViewController
                self.navigationController?.pushViewController(termOfUseVC, animated: true)
                
            }else if indexPath.row == 2 {
                self.alertComfirm()
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let label = UILabel()
//        label.text = "    \(sections[section])"
//        label.textColor = .lightGray
//        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
//        label.backgroundColor = .systemBackground
//        return label
//    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 55
    }
    
    
}
