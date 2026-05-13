//
//  SheetPresentationViewController.swift
//  BIVN
//
//  Created by Luyện Đào on 24/11/2023.
//

import UIKit
import DropDown
import Moya
import Localize_Swift

class SheetPresentationViewController: BaseViewController {
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var modelTextField: UITextField!
    @IBOutlet weak var machineLineTextField: UITextField!
    @IBOutlet weak var linesTextField: UITextField!
    @IBOutlet weak var modelButton: UIButton!
    @IBOutlet weak var machineButton: UIButton!
    @IBOutlet weak var lineButton: UIButton!
    @IBOutlet weak var titleMachineLabel: UILabel!
    @IBOutlet weak var titleLinesLabel: UILabel!
    @IBOutlet weak var requiredModelLabel: UILabel!
    @IBOutlet weak var requiredMachinelLabel: UILabel!
    @IBOutlet weak var requiredLineLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    let networkManager: NetworkManager = NetworkManager()
    let myDropDown = DropDown()
    var dropdownModel:[String] = []
    var dropdownMachine:[DataResut] = []
    var dropdownLines:[DataResut] = []
    var modelCode: String?
    var machineCode: String?
    var lineCode: String?
    var passDataFilter: ((_ model: String?, _ machine: String?, _ line: String?) -> Void)?
    var onTapClose: (() -> Void)?
    var onTapPopup: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dismiss(animated: true)
        setupView()
        machineLineTextField.attributedPlaceholder = NSAttributedString(string: "Placeholder text", attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: R.color.lineColor.name)!])
        linesTextField.attributedPlaceholder = NSAttributedString(string: "Placeholder text", attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: R.color.lineColor.name)!])
        checkIsHiddenTextField()
        addDropdownImage(textField: modelTextField)
        addDropdownImage(textField: machineLineTextField)
        addDropdownImage(textField: linesTextField)
        getListDropdownModel(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "")
        
    }
    
    private func setupView() {
        bottomView.layer.masksToBounds = false
        bottomView.layer.shadowColor = UIColor.gray.cgColor
        bottomView.layer.shadowOffset = CGSize(width: 0, height: -2)
        bottomView.layer.shadowOpacity = 0.2
        bottomView.layer.shadowRadius = 2.0
        closeButton.setTitle("", for: .normal)
        modelButton.setTitle("", for: .normal)
        machineButton.setTitle("", for: .normal)
        lineButton.setTitle("", for: .normal)
        requiredModelLabel.isHidden = true
        requiredMachinelLabel.isHidden = true
        requiredLineLabel.isHidden = true
        resetButton.setTitleColor(UIColor.black, for: .normal)
        confirmButton.setTitleColor(UIColor(named: R.color.white.name), for: .normal)
        resetButton.layer.borderColor = UIColor(named: R.color.greyDC.name)?.cgColor
        resetButton.layer.borderWidth = 1.5
        resetButton.layer.cornerRadius = 4
        resetButton.layer.masksToBounds = true
        titleLinesLabel.text = "Chuyền".localized()
        titleMachineLabel.text = "Dòng máy".localized()
    }
    
    private func checkIsHiddenTextField() {
        modelTextField.isUserInteractionEnabled = false
        machineLineTextField.isUserInteractionEnabled = false
        linesTextField.isUserInteractionEnabled = false
        resetView()
    }
    
    func onTapDissmiss() {
        onTapPopup = false
        self.dismiss(animated: true)
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
    
    private func getListDropdownModel(inventoryId: String, accountId: String) {
        networkManager.getListDropdownModel(inventoryId: inventoryId, accountId: accountId) { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dropdownModel = response.arrayOfStrings
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        getListDropdownModel(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "")
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
    
    private func getListDropdownMachine(inventoryId: String, accountId: String, modelCode: String) {
        networkManager.getListDropdownMachines(inventoryId: inventoryId, accountId: accountId, modelCode: modelCode) { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dropdownMachine = response.data ?? []
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        self.getListDropdownMachine(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", modelCode: self.modelCode ?? "")
                    }
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
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
    
    private func getListDropdownLines(inventoryId: String, accountId: String, modelCode: String, machineType: String) {
        networkManager.getListDropdownLines(inventoryId: inventoryId, accountId: accountId, modelCode: modelCode, machineType: machineType) { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dropdownLines = response.data ?? []
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        self.getListDropdownLines(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", modelCode: self.modelCode ?? "", machineType: self.machineCode ?? "")
                    }
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
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
    
    private func resetView() {
        modelTextField.text = "Lựa chọn model".localized()
        machineLineTextField.placeholder = "Lựa chọn dòng máy".localized()
        machineLineTextField.text = ""
        linesTextField.text = ""
        linesTextField.placeholder = "Lựa chọn chuyền".localized()
        titleMachineLabel.textColor = UIColor(named: R.color.dropdown.name)
        titleLinesLabel.textColor = UIColor(named: R.color.dropdown.name)
        machineLineTextField.textColor = UIColor(named: R.color.greyDC.name)
        linesTextField.textColor = UIColor(named: R.color.greyDC.name)
        requiredModelLabel.isHidden = true
        requiredMachinelLabel.isHidden = true
        requiredLineLabel.isHidden = true
    }
    
    //Action
    @IBAction func onTapClose(_ sender: UIButton) {
        onTapPopup = false
        dismiss(animated: true)
        onTapClose?()
    }
    
    @IBAction func onTapDropdownModel(_ sender: UIButton) {
        showDropdownModel()
    }
    
    
    @IBAction func onTapDropdownMachine(_ sender: UIButton) {
        showDropdownMachine()
    }
    
    @IBAction func onTapDropdownLine(_ sender: UIButton) {
        showDropdownLines()
    }
    
    @IBAction func onTapReinstallButton(_ sender: UIButton) {
        dropdownMachine = []
        dropdownLines = []
        resetView()
    }
    
    @IBAction func onTapAccpectButton(_ sender: UIButton) {
        if let model = modelTextField.text, let machine = machineLineTextField.text, let line = linesTextField.text {
            if model == "Lựa chọn model" || model == "Select model" {
                requiredModelLabel.isHidden = false
                requiredModelLabel.text = "Vui lòng chọn model.".localized()
            }
            if machine.isEmpty {
                requiredMachinelLabel.isHidden = false
                requiredMachinelLabel.text = "Vui lòng chọn dòng máy.".localized()
            }
            if line.isEmpty {
                requiredLineLabel.isHidden = false
                requiredLineLabel.text = "Vui lòng chọn chuyền.".localized()
            }
            
            if model != "Lựa chọn model".localized() && !machine.isEmpty && !line.isEmpty {
                passDataFilter? (modelCode ?? "", machineCode ?? "", lineCode ?? "")
                onTapPopup = false
                dismiss(animated: true)
            }
        }
    }
    
    // showDropdown
    
    private func showDropdownModel() {
        myDropDown.dataSource = dropdownModel.map { $0 }
        myDropDown.anchorView = modelButton
        myDropDown.bottomOffset = CGPoint(x: 0, y: (modelTextField.frame.size.height + 20))
        myDropDown.topOffset = CGPoint(x: 0, y: -(myDropDown.anchorView?.plainView.bounds.height)!)
        myDropDown.dismissMode = .onTap
        myDropDown.direction = .bottom
        myDropDown.selectionAction = { (index: Int, item: String) in
            self.modelTextField.text = "\(self.dropdownModel[index])"
            self.modelTextField.font = fontUtils.size12.regular
            self.modelTextField.textColor = .black
            self.titleMachineLabel.textColor = .black
            self.machineLineTextField.textColor = .black
            self.getListDropdownMachine(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", modelCode: item)
            self.modelCode = item
            self.requiredModelLabel.isHidden = true
        }
        myDropDown.show()
    }
    
    private func showDropdownMachine() {
        myDropDown.dataSource = dropdownMachine.map { $0.displayName ?? "" }
        myDropDown.anchorView = machineButton
        myDropDown.bottomOffset = CGPoint(x: 0, y: (machineLineTextField.frame.size.height + 20))
        myDropDown.topOffset = CGPoint(x: 0, y: -(myDropDown.anchorView?.plainView.bounds.height)!)
        myDropDown.dismissMode = .onTap
        myDropDown.direction = .bottom
        myDropDown.selectionAction = { (index: Int, item: String) in
            self.machineLineTextField.text = "\(self.dropdownMachine[index].displayName ?? "")"
            self.getListDropdownLines(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", modelCode: self.modelCode ?? "", machineType: self.dropdownMachine[index].key ?? "")
            self.machineCode = self.dropdownMachine[index].key ?? ""
            self.linesTextField.textColor = .black
            self.machineLineTextField.font = fontUtils.size12.regular
            self.titleLinesLabel.textColor = .black
            self.requiredMachinelLabel.isHidden = true
        }
        myDropDown.show()
    }
    
    private func showDropdownLines() {
        myDropDown.dataSource = dropdownLines.map { $0.displayName ?? "" }
        myDropDown.anchorView = lineButton
        myDropDown.bottomOffset = CGPoint(x: 0, y: (linesTextField.frame.size.height + 20))
        myDropDown.topOffset = CGPoint(x: 0, y: -(myDropDown.anchorView?.plainView.bounds.height)!)
        myDropDown.dismissMode = .onTap
        myDropDown.direction = .bottom
        myDropDown.selectionAction = { (index: Int, item: String) in
            self.linesTextField.font = fontUtils.size12.regular
            self.linesTextField.text = "\(self.dropdownLines[index].displayName ?? "")"
            self.requiredLineLabel.isHidden = true
            self.lineCode = self.dropdownLines[index].key ?? ""
        }
        myDropDown.show()
    }
}
