//
//  ChooseModelDocViewController.swift
//  BIVN
//
//  Created by TinhVan Software on 07/05/2024.
//

import UIKit
import DropDown
import Moya
import Localize_Swift

class ChooseModelDocViewController: BaseViewController {
    
    @IBOutlet weak var modelTextField: UITextField!
    @IBOutlet weak var machineLineTextField: UITextField!
    @IBOutlet weak var modelCodeTextField: UITextField!
    @IBOutlet weak var linesTextField: UITextField!
    @IBOutlet weak var modelButton: UIButton!
    @IBOutlet weak var machineButton: UIButton!
    @IBOutlet weak var modelCodeButton: UIButton!
    @IBOutlet weak var lineButton: UIButton!
    @IBOutlet weak var titleMachineLabel: UILabel!
    @IBOutlet weak var titleModelCodeLabel: UILabel!
    @IBOutlet weak var titleLinesLabel: UILabel!
    @IBOutlet weak var requiredModelLabel: UILabel!
    @IBOutlet weak var requiredMachinelLabel: UILabel!
    @IBOutlet weak var requiredModelCodeLabel: UILabel!
    @IBOutlet weak var requiredLineLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var modelCodeStackView: UIStackView!
    @IBOutlet weak var topStackViewConstraint: NSLayoutConstraint!
    
    let networkManager: NetworkManager = NetworkManager()
    let myDropDown = DropDown()
    var dropdownModel:[String] = []
    var dropdownMachine:[DataResut] = []
    var dropdownModelCode:[String] = []
    var dropdownLines:[DataResut] = []
    var param = Dictionary<String, Any>()
    var model: String?
    var modelCode: String?
    var machineType: String?
    var lineCode: String = ""
    var passDataFilter: ((_ model: String?, _ machine: String?, _ line: String?) -> Void)?
    var isAcpect: Bool = false
    var titleString: String?
    var jobIndex : Int = 0
    var docType: String = ""
    var titleJob: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        titleLinesLabel.text = "Chuyền".localized()
        titleMachineLabel.text = "Dòng máy".localized()
        machineLineTextField.attributedPlaceholder = NSAttributedString(string: "Placeholder text", attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: R.color.lineColor.name)!])
        modelCodeTextField.attributedPlaceholder = NSAttributedString(string: "Placeholder text", attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: R.color.lineColor.name)!])
        linesTextField.attributedPlaceholder = NSAttributedString(string: "Placeholder text", attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: R.color.lineColor.name)!])
        checkIsHiddenTextField()
        addDropdownImage(textField: modelTextField)
        addDropdownImage(textField: machineLineTextField)
        addDropdownImage(textField: modelCodeTextField)
        addDropdownImage(textField: linesTextField)
        if docType == "B" {
            getListDropdownModelB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "")
        } else {
            getListDropdownModel(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "")
        }
    }
    
    private func setupView() {
        if docType == "C" {
            modelCodeStackView.isHidden = true
            modelCodeButton.isHidden = true
            topStackViewConstraint.constant = 64
        }
        self.title = titleString
        modelButton.setTitle("", for: .normal)
        machineButton.setTitle("", for: .normal)
        modelCodeButton.setTitle("", for: .normal)
        lineButton.setTitle("", for: .normal)
        requiredModelLabel.isHidden = true
        requiredMachinelLabel.isHidden = true
        requiredModelCodeLabel.isHidden = true
        requiredLineLabel.isHidden = true
        resetButton.setTitleColor(UIColor.black, for: .normal)
        resetButton.setTitle("Reset".localized(), for: .normal)
        confirmButton.setTitle("Confirm".localized(), for: .normal)
        confirmButton.setTitleColor(UIColor(named: R.color.white.name), for: .normal)
        resetButton.layer.borderColor = UIColor(named: R.color.greyDC.name)?.cgColor
        resetButton.layer.borderWidth = 1.5
        resetButton.layer.cornerRadius = 4
        resetButton.layer.masksToBounds = true
    }
    
    private func checkIsHiddenTextField() {
        modelTextField.isUserInteractionEnabled = false
        machineLineTextField.isUserInteractionEnabled = false
        modelCodeTextField.isUserInteractionEnabled = false
        linesTextField.isUserInteractionEnabled = false
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
    
    private func getListDropdownModelB(inventoryId: String, accountId: String) {
        networkManager.getListDropdownModelB(inventoryId: inventoryId, accountId: accountId) { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dropdownModel = response.arrayOfStrings
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            getListDropdownModelB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "")
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
    
    private func getListDropdownMachineB(inventoryId: String, accountId: String, model: String) {
        networkManager.getListDropdownMachinesB(inventoryId: inventoryId, accountId: accountId, modelCode: model) { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dropdownMachine = response.data ?? []
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            getListDropdownMachineB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", model: self.model ?? "")
                        }
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
    
    private func getListDropdownModelCodeB(inventoryId: String, accountId: String, machineModel: String, machineType: String) {
        networkManager.getListDropdownModelCodeB(inventoryId: inventoryId, accountId: accountId, machineModel: machineModel, machineType: machineType) { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dropdownModelCode = response.arrayOfStrings
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.getListDropdownModelCodeB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", machineModel: self.model ?? "", machineType: self.machineType ?? "")
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
    
    private func getListDropdownLinesB(inventoryId: String, accountId: String, machineModel: String, machineType: String, modelCode: String) {
        networkManager.getListDropdownLinesB(inventoryId: inventoryId, accountId: accountId, machineModel: machineModel, machineType: machineType, modelCode: modelCode) { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dropdownLines = response.data ?? []
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.getListDropdownLinesB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", machineModel: self.model ?? "", machineType: self.machineType ?? "", modelCode: self.modelCode ?? "")
                        }
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
    
    private func getListDropdownModel(inventoryId: String, accountId: String) {
        networkManager.getListDropdownModel(inventoryId: inventoryId, accountId: accountId) { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dropdownModel = response.arrayOfStrings
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            getListDropdownModel(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "")
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
    
    private func getListDropdownMachine(inventoryId: String, accountId: String, modelCode: String) {
        networkManager.getListDropdownMachines(inventoryId: inventoryId, accountId: accountId, modelCode: modelCode) { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dropdownMachine = response.data ?? []
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.getListDropdownMachine(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", modelCode: self.model ?? "")
                        }
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
                        if result {
                            self.getListDropdownLines(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", modelCode: self.model ?? "", machineType: self.machineType ?? "")
                        }
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
    
    private func getListDocB(inventoryId: String?, accountId: String?, model: String?, machineType: String?, lineName: String?, modelCode: String?, actionType: Int?) {
        param["inventoryId"] = inventoryId ?? ""
        param["accountId"] = accountId ?? ""
        param["machineModel"] = model ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineName ?? ""
        param["actionType"] = actionType ?? 0
        param["stageName"] = ""
        param["modelCode"] = modelCode ?? ""
        param["pageNum"] = 1
        param["pageSize"] = 20
        
        networkManager.getListdocB(param: param) {[weak self] data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    guard let vc = Storyboards.scanTicketB.instantiate() as? ScanCodeTicketBViewController else {return}
                    vc.listDocB = response.data ?? ListDocB()
                    vc.model = self?.model
                    vc.modelCode = self?.modelCode
                    vc.machineType = self?.machineType
                    vc.lineCode = self?.lineCode ?? ""
                    vc.titleNavi = self?.titleString
                    vc.jobIndex = self?.jobIndex ?? 0
                    self?.navigationController?.pushViewController(vc, animated: true)
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self?.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            getListDocB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", model: self.model, machineType: self.machineType, lineName: self.lineCode, modelCode: self.modelCode, actionType: self.jobIndex)
                        }
                    }
                } else {
                    self?.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self?.showAlertConfigTimeOut()
                    }
                }
                print(error.localizedDescription)
            }
        }
    }

    private func getListDocC(inventoryId: String?, accountId: String?, machineModel: String?, machineType: String?, lineName: String?, stageName: String?, modelCode: String?, actionType: Int?) {
        param["inventoryId"] = inventoryId ?? ""
        param["accountId"] = accountId ?? ""
        param["machineModel"] = machineModel ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineName ?? ""
        param["actionType"] = actionType ?? 0
        param["stageName"] = stageName ?? ""
        param["modelCode"] = modelCode ?? ""
        param["pageNum"] = 1
        param["pageSize"] = 20

        networkManager.scanListDocC(param: param) { [weak self] result in
            switch result {
            case .success(let response):
                guard let `self` = self else { return }
                if response.code == 200 {
                    guard let vc = Storyboards.scanTicketC.instantiate() as? ScanCodeTicketCViewController else {return}
                    vc.listDocC = response.data ?? ArrayData()
                    vc.model = self.model
                    vc.machineType = self.machineType
                    vc.machineModel = machineModel
                    vc.lineCode = self.lineCode
                    vc.lineName = lineName
                    vc.titleNavi = self.titleString
                    vc.jobIndex = self.jobIndex
                    self.navigationController?.pushViewController(vc, animated: true)
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            getListDocC(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, stageName: "", modelCode: "", actionType: self.jobIndex)
                        }
                    }
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self?.showAlertConfigTimeOut()
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
        modelCodeTextField.placeholder = "Lựa chọn model code".localized()
        modelCodeTextField.text = ""
        linesTextField.placeholder = "Lựa chọn chuyền".localized()
        linesTextField.text = ""
        titleMachineLabel.textColor = UIColor(named: R.color.dropdown.name)
        titleModelCodeLabel.textColor = UIColor(named: R.color.dropdown.name)
        titleLinesLabel.textColor = UIColor(named: R.color.dropdown.name)
        machineLineTextField.textColor = UIColor(named: R.color.greyDC.name)
        modelCodeTextField.textColor = UIColor(named: R.color.greyDC.name)
        linesTextField.textColor = UIColor(named: R.color.greyDC.name)
        requiredModelLabel.isHidden = true
        requiredMachinelLabel.isHidden = true
        requiredModelCodeLabel.isHidden = true
        requiredLineLabel.isHidden = true
    }
    
    //Action
    
    @IBAction func onTapDropdownModel(_ sender: UIButton) {
        if docType == "B" {
            showDropdownModelB()
        } else {
            showDropdownModel()
        }
    }
    
    @IBAction func onTapDropdownMachine(_ sender: UIButton) {
        if docType == "B" {
            showDropdownMachineB()
        } else {
            showDropdownMachine()
        }
    }
    
    @IBAction func onTapDropdownModelCode(_ sender: UIButton) {
        if docType == "B" {
            showDropdownModelCodeB()
        } else {
            showDropdownModelCodeB()
        }
    }

    @IBAction func onTapDropdownLine(_ sender: UIButton) {
        if docType == "B" {
            showDropdownLinesB()
        } else {
            showDropdownLines()
        }
    }
    
    @IBAction func onTapReinstallButton(_ sender: UIButton) {
        dropdownMachine = []
        dropdownModelCode = []
        dropdownLines = []
        resetView()
    }
    
    @IBAction func onTapAccpectButton(_ sender: UIButton) {
        if docType == "C" {
            getListDocC(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, stageName: "", modelCode: "", actionType: self.jobIndex)
        } else {
            getListDocB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", model: self.model, machineType: self.machineType, lineName: self.lineCode, modelCode: self.modelCode, actionType: self.jobIndex)
        }
    }
    
    // showDropdown
    
    private func showDropdownModelB() {
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
            self.getListDropdownMachineB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", model: item)
            self.model = item
            self.requiredModelLabel.isHidden = true
        }
        myDropDown.show()
    }
    
    private func showDropdownMachineB() {
        myDropDown.dataSource = dropdownMachine.map { $0.displayName ?? "" }
        myDropDown.anchorView = machineButton
        myDropDown.bottomOffset = CGPoint(x: 0, y: (machineLineTextField.frame.size.height + 20))
        myDropDown.topOffset = CGPoint(x: 0, y: -(myDropDown.anchorView?.plainView.bounds.height)!)
        myDropDown.dismissMode = .onTap
        myDropDown.direction = .bottom
        myDropDown.selectionAction = { (index: Int, item: String) in
            self.machineLineTextField.text = "\(self.dropdownMachine[index].displayName ?? "")"
            self.getListDropdownModelCodeB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", machineModel: self.model ?? "", machineType: self.dropdownMachine[index].key ?? "")
            self.machineType = self.dropdownMachine[index].key ?? ""
            self.modelCodeTextField.textColor = .black
            self.machineLineTextField.font = fontUtils.size12.regular
            self.titleModelCodeLabel.textColor = .black
            self.requiredMachinelLabel.isHidden = true
        }
        myDropDown.show()
    }
    
    private func showDropdownModelCodeB() {
        myDropDown.dataSource = dropdownModelCode.map { $0 }
        myDropDown.anchorView = modelCodeButton
        myDropDown.bottomOffset = CGPoint(x: 0, y: (modelCodeTextField.frame.size.height + 20))
        myDropDown.topOffset = CGPoint(x: 0, y: -(myDropDown.anchorView?.plainView.bounds.height)!)
        myDropDown.dismissMode = .onTap
        myDropDown.direction = .bottom
        myDropDown.selectionAction = { (index: Int, item: String) in
            self.modelCodeTextField.text = "\(self.dropdownModelCode[index])"
            self.modelCodeTextField.font = fontUtils.size12.regular
            self.linesTextField.textColor = .black
            self.titleLinesLabel.textColor = .black
            self.getListDropdownLinesB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", machineModel: self.model ?? "", machineType: self.machineType ?? "", modelCode: item)
            self.modelCode = item
            self.requiredModelCodeLabel.isHidden = true
        }
        myDropDown.show()
    }
    
    private func showDropdownLinesB() {
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
    
    private func showDropdownModel() {
        if dropdownModel.count < 1 {
            getListDropdownModel(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "")
        }
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
            self.model = item
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
            self.getListDropdownLines(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", modelCode: self.model ?? "", machineType: self.dropdownMachine[index].key ?? "")
            self.machineType = self.dropdownMachine[index].key ?? ""
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
