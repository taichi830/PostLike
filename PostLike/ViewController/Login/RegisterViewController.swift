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

final class RegisterViewController: UIViewController {
    
    
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var alertView: UILabel!
    @IBOutlet private weak var alertLabelHeight: NSLayoutConstraint!
    @IBOutlet private weak var birthDayTextField: UITextField!
    @IBOutlet private weak var genderTextField: UITextField!
    
    
    
    
    private let disposeBag = DisposeBag()
    private let registerViewModel = RegisterViewModel()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setupBinds()
        
        emailTextField.attributedPlaceholder = NSAttributedString(string: "メールアドレス", attributes: [.foregroundColor: UIColor.lightGray.cgColor])
        birthDayTextField.attributedPlaceholder = NSAttributedString(string: "生年月日", attributes: [.foregroundColor: UIColor.lightGray.cgColor])
        genderTextField.attributedPlaceholder = NSAttributedString(string: "性別", attributes: [.foregroundColor: UIColor.lightGray.cgColor])
        
        alertView.layer.cornerRadius = 5
        nextButton.layer.cornerRadius = 16
        
        
        
    }
    
    
    
    
    
    
    @IBAction private func backButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    private func tappedNextButton() {
        startIndicator()
        self.view.endEditing(true)
        guard let email = emailTextField.text else { return }
        Auth.sendSignInLink(email: email) { bool in
            switch bool {
            case false:
                let alertAction = UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismissIndicator()
                }
                self.showAlert(title: "エラーが発生しました", message: "もう一度試してください", actions: [alertAction])
                
            case true:
                let confirmVC = self.storyboard?.instantiateViewController(withIdentifier: "confirm") as! ComfirmEmailViewController
                confirmVC.passedEmailAdress = self.emailTextField.text ?? ""
                UserDefaults.standard.set(self.emailTextField.text ?? "", forKey: "email")
                UserDefaults.standard.set(self.genderTextField.text ?? "", forKey: "gender")
                UserDefaults.standard.set(self.birthDayTextField.text ?? "", forKey: "birthDay")
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
        picker.rx.itemSelected.asDriver()
            .drive { [weak self] item in
                self?.registerViewModel.genderTextInPut.onNext(dataList[item.row])
                self?.genderTextField.text = dataList[item.row]
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
        
        
        
        
        nextButton.rx.tap
            .asDriver()
            .drive { [weak self] _ in
                self?.tappedNextButton()
                print(self?.genderTextField.text ?? "no value")
            }
            .disposed(by: disposeBag)
        
        
        
        
        
        registerViewModel.validRegisterDriver
            .drive { [weak self] validAll in
                self?.nextButton.isEnabled = validAll
                self?.nextButton.backgroundColor = validAll ? .red : .systemGray4
            }
            .disposed(by: disposeBag)
        
        
        
    }
    
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    
    
    
    
    
    
    
}




















