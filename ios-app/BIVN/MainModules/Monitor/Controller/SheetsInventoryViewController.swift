//
//  SheetsInventoryViewController.swift
//  BIVN
//
//  Created by tinhvan on 28/11/2023.
//

import UIKit
import DropDown
import Moya
import Localize_Swift

protocol TestDelegate {
    func passData(room: String?, area: String?, partCode: String?)
}

class SheetsInventoryViewController: BaseViewController {
    
    @IBOutlet weak var titleCodeLabel: UILabel!
    @IBOutlet weak var titleAreaLabel: UILabel!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var areaTextField: UITextField!
    @IBOutlet weak var roomTextField: UITextField!
    @IBOutlet weak var codeButton: UIButton!
    @IBOutlet weak var areaButton: UIButton!
    @IBOutlet weak var roomButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    let networkManager: NetworkManager = NetworkManager()
    let myDropDown = DropDown()
    var dropdownRoom:[String] = []
    var dropdownArea:[String] = []
    var dropdownCode:[String] = []
    var roomCode: String?
    var areaCode: String?
    var partCode: String?
    var delegate: TestDelegate?
    var isEnable: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        checkIsHiddenTextField()
        addDropdownImage(textField: roomTextField)
        addDropdownImage(textField: areaTextField)
        addDropdownImage(textField: codeTextField)
        getListDropdownDepartment(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "")
        getListAllLocation(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "")
        getListAllComponent(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "")
    }
    
    private func setupView() {
        buttonView.layer.masksToBounds = false
        buttonView.layer.shadowColor = UIColor.gray.cgColor
        buttonView.layer.shadowOffset = CGSize(width: 0, height: -2)
        buttonView.layer.shadowOpacity = 0.2
        buttonView.layer.shadowRadius = 2.0
        closeButton.setTitle("", for: .normal)
        roomButton.setTitle("", for: .normal)
        areaButton.setTitle("", for: .normal)
        codeButton.setTitle("", for: .normal)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: fontUtils.size18.medium,
        ]
        confirmButton.setAttributedTitle(NSAttributedString(string: "Xác nhận".localized(), attributes: attributes), for: .normal)
        settingButton.setAttributedTitle(NSAttributedString(string: "Cài đặt lại".localized(), attributes: attributes), for: .normal)
    }
    
    private func checkIsHiddenTextField() {
        roomTextField.isUserInteractionEnabled = false
        areaTextField.isUserInteractionEnabled = false
        codeTextField.isUserInteractionEnabled = false
        resetView()
    }
    
    private func addDropdownImage(textField: UITextField) {
        let imageIcon = UIImageView()
        imageIcon.image = UIImage(named: R.image.ic_dropDown.name)
        let contentView = UIView()
        contentView.addSubview(imageIcon)
        contentView.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        imageIcon.frame = CGRect(x: -10, y: 0, width: 18, height: 18)
        textField.rightView = contentView
        textField.rightViewMode = .always
        textField.clearButtonMode = .whileEditing
    }
    
    private func resetView() {
        roomTextField.text = "Tất cả".localized()
        areaTextField.text = "Tất cả".localized()
        codeTextField.text = "Tất cả".localized()
        titleAreaLabel.textColor = .black
        titleCodeLabel.textColor = .black
        areaTextField.textColor = .black
        codeTextField.textColor = .black
    }
    
    private func getListAllLocation(inventoryId: String, accountId: String) {
        networkManager.getListDropdownLocation(inventoryId: inventoryId, accountId: accountId, departmentName: "-1") { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dropdownArea = response.arrayOfStrings
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.getListAllLocation(inventoryId: inventoryId, accountId: accountId)
                        }
                    }
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code), message: UserDefault.shared.showErrorText(errorCode: response.code),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code))
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self.showAlertConfigTimeOut()
                    }
                }
                print(error.localizedDescription)
            }
        }
    }
    
    private func getListAllComponent(inventoryId: String, accountId: String) {
        networkManager.getListDropdownComponent(inventoryId: inventoryId, accountId: accountId, departmentName: "-1", locationName: "-1") { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dropdownCode = response.arrayOfStrings
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.getListAllComponent(inventoryId: inventoryId, accountId: accountId)
                        }
                    }
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code), message: UserDefault.shared.showErrorText(errorCode: response.code),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code))
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self.showAlertConfigTimeOut()
                    }
                }
                print(error.localizedDescription)
            }
        }
    }
    
    private func getListDropdownDepartment(inventoryId: String, accountId: String) {
        networkManager.getListDropdownDepartment(inventoryId: inventoryId, accountId: accountId) { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dropdownRoom = response.arrayOfStrings
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.getListDropdownDepartment(inventoryId: inventoryId, accountId: accountId)
                        }
                    }
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code), message: UserDefault.shared.showErrorText(errorCode: response.code),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code))
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self.showAlertConfigTimeOut()
                    }
                }
                print(error.localizedDescription)
            }
        }
    }
    
    private func getListDropdownLocation(inventoryId: String, accountId: String, departmentName: String) {
        networkManager.getListDropdownLocation(inventoryId: inventoryId, accountId: accountId, departmentName: departmentName) { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dropdownArea = response.arrayOfStrings
                    self.areaTextField.text = self.dropdownArea.first
                    self.getListDropdownComponent(inventoryId: inventoryId, accountId: accountId, departmentName: departmentName, locationName: self.areaTextField.text ?? "")
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.getListDropdownLocation(inventoryId: inventoryId, accountId: accountId, departmentName: departmentName)
                        }
                    }
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code), message: UserDefault.shared.showErrorText(errorCode: response.code),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code))
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self.showAlertConfigTimeOut()
                    }
                }
                print(error.localizedDescription)
            }
        }
    }
    
    private func getListDropdownComponent(inventoryId: String, accountId: String, departmentName: String, locationName: String) {
        networkManager.getListDropdownComponent(inventoryId: inventoryId, accountId: accountId, departmentName: departmentName, locationName: locationName) { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dropdownCode = response.arrayOfStrings
                    self.codeTextField.text = self.dropdownCode.first
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.getListDropdownComponent(inventoryId: inventoryId, accountId: accountId, departmentName: departmentName, locationName: locationName)
                        }
                    }
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code), message: UserDefault.shared.showErrorText(errorCode: response.code),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code))
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self.showAlertConfigTimeOut()
                    }
                }
                print(error.localizedDescription)
            }
        }
    }
    
    func close() {
        self.isEnable = false
        dismiss(animated: true)
    }
    
    //Action
    @IBAction func onTapCloseSheets(_ sender: UIButton) {
        self.isEnable = false
        dismiss(animated: true)
    }
    
    @IBAction func onTapDropdownRoom(_ sender: UIButton) {
        showDropdownRoom()
    }
    
    @IBAction func ontapDropdownArea(_ sender: Any) {
        showDropdownArea()
    }
    
    @IBAction func onTapDropdownCode(_ sender: Any) {
        showDropdownCode()
    }
    
    @IBAction func onTapReset(_ sender: Any) {
        getListDropdownDepartment(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "")
        getListAllLocation(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "")
        getListAllComponent(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "")
        resetView()
    }
    
    @IBAction func ontapAccept(_ sender: UIButton) {
        if let room = roomTextField.text, let area = areaTextField.text, let code = codeTextField.text {
            delegate?.passData(room: room, area: area, partCode: code)
            self.isEnable = false
            dismiss(animated: true)
        }
    }
    
    private func showDropdownRoom() {
        myDropDown.dataSource = dropdownRoom.map { $0 }
        myDropDown.anchorView = roomButton
        myDropDown.bottomOffset = CGPoint(x: 0, y: (roomTextField.frame.size.height + 20))
        myDropDown.topOffset = CGPoint(x: 0, y: -(myDropDown.anchorView?.plainView.bounds.height)!)
        myDropDown.dismissMode = .onTap
        myDropDown.direction = .bottom
        myDropDown.selectionAction = { (index: Int, item: String) in
            self.roomTextField.text = "\(self.dropdownRoom[index])"
            self.roomTextField.textColor = .black
            self.titleAreaLabel.textColor = .black
            self.areaTextField.textColor = .black
            self.titleCodeLabel.textColor = .black
            self.codeTextField.textColor = .black
            self.getListDropdownLocation(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", departmentName: item)
            self.roomCode = item
        }
        myDropDown.show()
    }
    
    private func showDropdownArea() {
        myDropDown.dataSource = dropdownArea.map { $0 }
        myDropDown.anchorView = areaButton
        myDropDown.bottomOffset = CGPoint(x: 0, y: (areaTextField.frame.size.height + 20))
        myDropDown.topOffset = CGPoint(x: 0, y: -(myDropDown.anchorView?.plainView.bounds.height)!)
        myDropDown.dismissMode = .onTap
        myDropDown.direction = .bottom
        myDropDown.selectionAction = { (index: Int, item: String) in
            self.areaTextField.text = "\(self.dropdownArea[index])"
            self.getListDropdownComponent(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", departmentName: self.roomCode ?? "-1", locationName: item)
            self.areaCode = item
            self.codeTextField.textColor = .black
            self.titleCodeLabel.textColor = .black
        }
        myDropDown.show()
    }
    
    private func showDropdownCode() {
        myDropDown.dataSource = dropdownCode.map { $0 }
        myDropDown.anchorView = codeButton
        myDropDown.bottomOffset = CGPoint(x: 0, y: (codeTextField.frame.size.height + 20))
        myDropDown.topOffset = CGPoint(x: 0, y: -(myDropDown.anchorView?.plainView.bounds.height)!)
        myDropDown.dismissMode = .onTap
        myDropDown.direction = .bottom
        myDropDown.selectionAction = { (index: Int, item: String) in
            self.codeTextField.text = "\(self.dropdownCode[index])"
            self.partCode = item
        }
        myDropDown.show()
    }
}
