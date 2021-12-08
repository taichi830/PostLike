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
import RxSwift
import RxCocoa

class RegisterViewController: UIViewController {
    
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var alertView: UILabel!
    @IBOutlet weak var alertLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var birthDayTextField: UITextField!
    @IBOutlet weak var genderTextField: UITextField!
    
    
    
    
    private let disposeBag = DisposeBag()
    private let registerViewModel = RegisterViewModel()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setupBinds()
        
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス", attributes: [.foregroundColor: UIColor.lightGray.cgColor])
        birthDayTextField.attributedPlaceholder = NSAttributedString(string: "生年月日", attributes: [.foregroundColor: UIColor.lightGray.cgColor])
        genderTextField.attributedPlaceholder = NSAttributedString(string: "性別", attributes: [.foregroundColor: UIColor.lightGray.cgColor])
        
        alertView.layer.cornerRadius = 5
        registerButton.layer.cornerRadius = 16
        
        
        
    }
    
    
    
    
    
    
    @IBAction func backButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    private func tappedNextButton() {
        startIndicator()
        self.view.endEditing(true)
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        //リンクURL
        var components = URLComponents()
        components.scheme = "https"
        #if DEBUG
        components.host = "postliketest.page.link"
        #else
        components.host = "postlike.page.link"
        #endif
        
        let queryItemEmailName = "email"
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
    
    
    
    
    
    private func setupBinds() {
        
        let dataList = ["","男性","女性","選択しない"]
        let picker = UIPickerView()
        picker.backgroundColor = .white
        self.genderTextField.inputView = picker
        Observable.just(dataList)
            .bind(to: picker.rx.itemTitles) { _ , str in
                return str
            }
            .disposed(by: disposeBag)
        picker.rx.modelSelected(String.self)
            .map { strs in
                return strs.first
            }
            .bind(to: genderTextField.rx.text)
            .disposed(by: disposeBag)
        genderTextField.rx.text
            .asDriver()
            .drive { [weak self] text in
                self?.registerViewModel.genderTextInPut.onNext(text ?? "")
            }
            .disposed(by: disposeBag)
        
        let datePickerView:UIDatePicker = UIDatePicker()
        datePickerView.backgroundColor = .white
        datePickerView.preferredDatePickerStyle = .wheels
        datePickerView.datePickerMode = UIDatePicker.Mode.date
        self.birthDayTextField.inputView = datePickerView
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat  = "yyyy/MM/dd"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        datePickerView.rx.value.changed.asDriver()
            .drive { [weak self] date in
                self?.registerViewModel.birthDayTextInPut.onNext(date)
                self?.birthDayTextField.text = dateFormatter.string(from: date)
            }
            .disposed(by: disposeBag)
        registerViewModel.validBirthDayDriver
            .drive { valid in
                if valid == false {
                    self.alertView.isHidden = false
                    self.alertView.text = "3歳以下はご利用できません"
                    self.alertLabelHeight.constant = 42
                } else {
                    self.alertView.isHidden = true
                    self.alertLabelHeight.constant = 0
                }
            }
            .disposed(by: disposeBag)
        
        emailTextField.rx.text
            .asDriver()
            .drive { [weak self] text in
                self?.registerViewModel.emailTextInPut.onNext(text ?? "")
            }
            .disposed(by: disposeBag)
        
        registerButton.rx.tap
            .asDriver()
            .drive { [weak self] _ in
                self?.tappedNextButton()
            }
            .disposed(by: disposeBag)
        
        registerViewModel.validRegisterDriver
            .drive { [weak self] validAll in
                self?.registerButton.isEnabled = validAll
                self?.registerButton.backgroundColor = validAll ? .red : .systemGray4
            }
            .disposed(by: disposeBag)
        
        
        
    }
    
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    
    
    
    
    
    
    
}




















