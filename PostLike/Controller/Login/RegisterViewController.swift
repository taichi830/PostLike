//
//  RegisterViewController.swift
//  postLike
//
//  Created by taichi on 2020/09/27.
//  Copyright © 2020 taichi. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class RegisterViewController: UIViewController {
    
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var alertView: UILabel!
    @IBOutlet weak var alertLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var birthDayTextField: UITextField!
    @IBOutlet weak var genderTextField: UITextField!
    
    
    
    
    var toolBar:UIToolbar!
    let dataList = ["","男性","女性","選択しない"]
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        
        
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス", attributes: [.foregroundColor: UIColor.lightGray.cgColor])
        
        registerButton.layer.cornerRadius = 15
        
        birthDayTextField.delegate = self
        birthDayTextField.attributedPlaceholder = NSAttributedString(string: "生年月日", attributes: [.foregroundColor: UIColor.lightGray.cgColor])
        
        genderTextField.delegate = self
        genderTextField.attributedPlaceholder = NSAttributedString(string: "性別", attributes: [.foregroundColor: UIColor.lightGray.cgColor])
        
        
        
        
        
        
        alertView.layer.cornerRadius = 5
        registerButton.layer.cornerRadius = 16
        
        
    }
    
    
    
    
    
    
    @IBAction func backButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    @IBAction func done(_ sender: Any) {
        startIndicator()
        self.view.endEditing(true)
        let actionCodeSettings = ActionCodeSettings() //メールリンクの作成方法をFirebaseに伝えるオブジェクト
        actionCodeSettings.handleCodeInApp = true //ログインをアプリ内で完結させる必要があります
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!) //iOSデバイス内でログインリンクを開くアプリのBundle ID
        //リンクURL
        var components = URLComponents()
        components.scheme = "https"
        
        #if DEBUG
        components.host = "postliketest.page.link"
        #else
        components.host = "postlike.page.link"
        #endif
        
        //Firebaseコンソールで作成したダイナミックリンクURLドメイン
        let queryItemEmailName = "email" //URLにemail情報(パラメータ)を追加する
        let emailTypeQueryItem = URLQueryItem(name: queryItemEmailName, value: emailTextField.text!)
        components.queryItems = [emailTypeQueryItem]
        guard let linkParameter = components.url else { return }
        actionCodeSettings.url = linkParameter
        
        Auth.auth().sendSignInLink(toEmail: emailTextField.text!, actionCodeSettings: actionCodeSettings) { err in
            if let err = err {
                print("error\(err)")
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                return
            }else{
                let confirmVC = self.storyboard?.instantiateViewController(withIdentifier: "confirm") as! ComfirmEmailViewController
                confirmVC.passedEmailAdress = self.emailTextField.text!
                UserDefaults.standard.set(self.emailTextField.text!, forKey: "email")
                UserDefaults.standard.set(self.genderTextField.text!, forKey: "gender")
                UserDefaults.standard.set(self.birthDayTextField.text!, forKey: "birthDay")
                self.navigationController?.pushViewController(confirmVC, animated: true)
                self.dismissIndicator()
            }
        }
        
        
    }
    
    
    
    
    
    
    
    
}

extension RegisterViewController: UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource{
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if emailTextField.text != ""  && birthDayTextField.text != "" && genderTextField.text != "" {
            registerButton.backgroundColor = .systemRed
            registerButton.isEnabled = true
        }else {
            registerButton.backgroundColor = .lightGray
            registerButton.isEnabled = false
        }
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.alertView.isHidden = true
        self.alertLabelHeight.constant = 0
        if textField.placeholder == "生年月日" {
            let datePickerView:UIDatePicker = UIDatePicker()
            datePickerView.backgroundColor = .white
            datePickerView.preferredDatePickerStyle = .wheels
            datePickerView.datePickerMode = UIDatePicker.Mode.date
            textField.inputView = datePickerView
            datePickerView.addTarget(self, action: #selector(datePickerValueChanged), for: UIControl.Event.valueChanged)
        }else if textField == genderTextField {
            let picker = UIPickerView()
            picker.backgroundColor = .white
            picker.delegate = self
            picker.dataSource = self
            genderTextField.inputView = picker
        }
    }
    
    
    
    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat  = "yyyy/MM/dd"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let now =  Date()
        let birthDay = sender.date
        let days = Calendar.current.dateComponents([.year], from: birthDay, to: now)
        print(days.year!)
        
        if sender.date > Date() {
            alertView.isHidden = false
            self.alertLabelHeight.constant = 42
            alertView.text = "未来人は登録できません"
            registerButton.backgroundColor = .lightGray
            registerButton.isEnabled = false
            
        }else if days.year! < 4 {
            alertView.isHidden = false
            self.alertLabelHeight.constant = 42
            alertView.text = "3歳以下はご利用できません"
            registerButton.backgroundColor = .lightGray
            registerButton.isEnabled = false
        }else{
            alertView.isHidden = true
            self.alertLabelHeight.constant = 0
            birthDayTextField.text = dateFormatter.string(from: sender.date)
            if emailTextField.text != ""  && birthDayTextField.text != "" && genderTextField.text != "" {
                registerButton.backgroundColor = .systemRed
                registerButton.isEnabled = true
            }
        }
    }
    
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.alertView.isHidden = true
        self.alertLabelHeight.constant = 0
        return true
    }
    
    
    
    @objc func doneBtn(){
        birthDayTextField.resignFirstResponder()
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 4
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return dataList[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        genderTextField.text = dataList[row]
    }
}





















