//
//  AcctionInventoryViewController.swift
//  BIVN
//
//  Created by tinhvan on 29/11/2023.
//

import UIKit
import Moya
import Localize_Swift

class ActionInventoryViewController: BaseViewController, AddRowCell {
    
    @IBOutlet weak var heightButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var actionButtonView: UIStackView!
    
    let networkManager: NetworkManager = NetworkManager()
    private var rowSelected = -1
    var arrayData: [DocComponentABEs] = []
    private var valueSumTest: Double = 0
    private var isHiddenReason: Bool = true
    var dataDetailSheets: ResultData?
    var dataHistory: [DocHistory] = []
    var arrayDelete: [String] = []
    var documentId = ""
    var titleNav: String = ""
    var note: String = ""
    private var regionUS: Bool = false
    var errorValid: Bool = false
    var arrayData2: [ConvertDocComponentABEs] = []
    var hideError: Bool = false
    var lastRow = -1
    var isTapSubmit: Bool = false
    var onTapSubmit: Bool = false
    var actionType: Int?
    var evicenceImg: String?
    private var imageCapture: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setDataDetail()
        regionUS = numberFormatter.locale.identifier == "en_US"
    }
    
    private func setupUI() {
        updateRejectButtonState()
        self.hideKeyboardWhenTappedAround()
        updateButton.setTitle("Cập nhật".localized(), for: .normal)
        rejectButton.setTitle(" Không đạt".localized(), for: .normal)
        confirmButton.setTitle(" Xác nhận đạt".localized(), for: .normal)
        let yourBackImage = UIImage(named: R.image.ic_back.name)
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.tintColor = UIColor.gray
        self.navigationItem.setHidesBackButton(true, animated: true)
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: #selector(onTapBack))
        self.navigationItem.leftBarButtonItem = buttonLeft
        self.title = titleNav
        setupTableView()
        setupColorButton(color: UIColor(named: R.color.lineColor.name) ?? .white)
        confirmButton.isUserInteractionEnabled = false
        updateButton.isUserInteractionEnabled = false
        updateButton.isHidden = true
        actionButtonView.isHidden = true
        
        var totalValue: Double = 0.0
        if arrayData.count != 0 {
            for item in arrayData {
                var convertABE = ConvertDocComponentABEs()
                convertABE.id = item.id
                convertABE.inventoryId = item.inventoryId
                convertABE.inventoryDocId = item.inventoryDocId
                convertABE.quantityPerBom = item.quantityPerBom
                convertABE.quantityOfBom = item.quantityOfBom
                arrayData2.append(convertABE)
                if let boxes = item.quantityPerBom, let numberOfboxes = item.quantityOfBom {
                    totalValue = (boxes * numberOfboxes) + totalValue
                }
            }
        }
        let itemWidthImages = dataHistory.filter({$0.evicenceImg != nil && $0.evicenceImg != ""})
        if let latestItem = itemWidthImages.max(by: {$0.createdAt ?? "" < $1.createdAt ?? ""}) {
            self.evicenceImg = latestItem.evicenceImg
        }
        self.valueSumTest = totalValue
    }
    
    private func setDataDetail() {
        if dataDetailSheets?.status == 7 {
            self.updateButton.isHidden = false
            self.actionButtonView.isHidden = true
        } else if dataDetailSheets?.status == 5 {
            self.updateButton.isHidden = true
            self.actionButtonView.isHidden = false
        } else {
            self.buttonView.isHidden = true
            self.heightButtonConstraint.constant = 0
        }
    }
    
    private func setupColorButton(color: UIColor) {
        let updateImage = UIImage(named: R.image.ic_update.name)
        let tintedUpdateImage = updateImage?.withRenderingMode(.alwaysTemplate)
        let origImage = UIImage(named: R.image.ic_tick.name)
        let tintedImage = origImage?.withRenderingMode(.alwaysTemplate)
        confirmButton.setImage(tintedImage, for: .normal)
        confirmButton.tintColor = color
        confirmButton.setTitleColor(color, for: .normal)
        
        updateButton.setImage(tintedUpdateImage, for: .normal)
        updateButton.tintColor = color
        updateButton.setTitleColor(color, for: .normal)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(R.nib.infoTicketTableViewCell)
        tableView.register(R.nib.titleInventoryCell)
        tableView.register(R.nib.invenTableViewCell)
        tableView.register(R.nib.totalItemTableViewCell)
        tableView.register(R.nib.imageViewCell)
        tableView.register(R.nib.errorTableViewCell)
        tableView.register(R.nib.noteCell)
        tableView.register(R.nib.historyInventoryCell)
        tableView.contentInset.bottom = 16
    }
    
    private func totalResult() {
        var totalValue: Double = 0.0
        for item in self.arrayData {
            if let quantityOfBom = item.quantityOfBom, let quantityPerBom = item.quantityPerBom {
                totalValue = (quantityOfBom * quantityPerBom) + totalValue
            }
        }
        
        self.valueSumTest = totalValue
        self.tableView.reloadSections(IndexSet(integer: SectionInventory.sumInventory.rawValue), with: .none)
    }
    
    @objc private func onTapBack() {
        self.showAlertNoti(title: "Xác nhận thoát".localized(), message: "Bạn có chắc chắn muốn thoát không? Nếu bạn thoát khi đã nhập dữ liệu thì dữ liệu đó sẽ không được lưu".localized(), cancelButton: "Không".localized(), acceptButton: "Có".localized(), acceptOnTap: {
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    func addRowCell() {
        self.errorValid = false
        let resultContainer = DocComponentABEs()
        arrayData.append(resultContainer)
        let indexPath = IndexPath(row: arrayData.count - 1, section: SectionInventory.rowInventory.rawValue)
           tableView.insertRows(at: [indexPath], with: .automatic)
        updateCellBackgroundColors()
        self.changeColorButton()
    }
    
    private func updateCellBackgroundColors() {
        for (index, item) in arrayData.enumerated() {
            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: SectionInventory.rowInventory.rawValue)) as? InvenTableViewCell {
                // Kiểm tra và cập nhật màu nền cho các ô nhập liệu
                if let quantityPerBom = item.quantityPerBom, quantityPerBom == 0 {
                    cell.updateBackgroundColor(for: cell.binsTextField)
                }
                if let quantityOfBom = item.quantityOfBom, quantityOfBom == 0 {
                    cell.updateBackgroundColor(for: cell.numberTextField)
                }
            }
        }
    }
    
    @IBAction func onTapSubmit(_ sender: UIButton) {
        var arrayValidate = self.arrayData
        arrayValidate.removeAll(where: { $0.quantityOfBom == nil && $0.quantityPerBom == nil })
        if arrayValidate.isEmpty {
            self.showAlertError(title: "Lỗi".localized(), message: "Không có dữ liệu.Vui lòng nhập dữ liệu Số lượng/thùng và Số thùng".localized(), titleButton: "Đồng ý".localized())
        } else if arrayValidate.contains(where: { $0.quantityOfBom == nil || $0.quantityPerBom == nil }) {
            errorValid = true
            tableView.reloadSections([4], with: .none)
        } else {
            if self.isTapSubmit {
                if !self.onTapSubmit {
                    onTapAction(actionType: 2)
                    onTapSubmit = true
                }
            }
        }
    }
    
    @IBAction func onTapUpdate(_ sender: UIButton) {
        var arrayValidate = self.arrayData
        arrayValidate.removeAll(where: { $0.quantityOfBom == nil && $0.quantityPerBom == nil })
        if arrayValidate.isEmpty {
            self.showAlertError(title: "Lỗi".localized(), message: "Không có dữ liệu.Vui lòng nhập dữ liệu Số lượng/thùng và Số thùng".localized(), titleButton: "Đồng ý".localized())
        } else if arrayValidate.contains(where: { $0.quantityOfBom == nil || $0.quantityPerBom == nil }) {
            errorValid = true
            tableView.reloadSections([4], with: .none)
        } else {
            if self.isTapSubmit {
                if !self.onTapSubmit {
                    onTapAction(actionType: 4)
                    onTapSubmit = true
                }
            }
        }
    }
    
    @IBAction func onTapReject(_ sender: UIButton) {
        if !self.onTapSubmit {
            onTapSubmit = true
            onTapAction(actionType: 3)
        }
    }
    
    func onTapAction(actionType: Int) {
        self.actionType = actionType
        arrayData.removeAll(where: { $0.quantityOfBom == nil || $0.quantityPerBom == nil })
        if  actionType == 3 {
            arrayData = []
            for item in arrayData2 {
                let convertABE = DocComponentABEs()
                convertABE.id = item.id
                convertABE.inventoryId = item.inventoryId
                convertABE.inventoryDocId = item.inventoryDocId
                convertABE.quantityPerBom = item.quantityPerBom
                convertABE.quantityOfBom = item.quantityOfBom
                arrayData.append(convertABE)
            }
        }
        networkManager.submitAudit(userCode: UserDefault.shared.getDataLoginModel().userCode ?? "M1234567", comment: self.note, inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", documentId: self.documentId, containerModel: arrayData, deleteDocOutPut: actionType == 3 ? [] : arrayDelete, actionType: actionType, completion: { data in
                switch data {
                case .success(let response):
                    if response.code == 200 {
                        self.onTapNav(actionType: actionType)
                    } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                        self.showAlertExpiredToken(code: response.code) { [weak self] result in
                            guard let self = self else { return }
                            self.onTapAction(actionType: self.actionType ?? 0)
                        }
                    } else if response.code == 400 {
                        self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: response.message ?? "",cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
                        self.onTapSubmit = false
                    } else {
                        self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
                        self.onTapSubmit = false
                    }
                    break
                case .failure(let error):
                    if case MoyaError.underlying(let underlyingError, _) = error {
                        if (underlyingError as NSError).code == 13 {
                            self.showAlertConfigTimeOut()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                guard let navigationController = self.navigationController else {return}
                                for viewController in navigationController.viewControllers where viewController is ScanCodeMCViewController {
                                    navigationController.popToViewController(viewController, animated: true)
                                }
                            }
                        }
                    }
                    print(error.localizedDescription)
                }
            })
    }
    
    func onTapNav(actionType: Int) {
        arrayData.removeAll(where: { $0.quantityOfBom == nil || $0.quantityPerBom == nil })
        // After performing monitoring action, return to the monitoring list screen and refresh it.
        let inventoryId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId
        let accountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId

        if let navigationController = self.navigationController {
            if let listVC = navigationController.viewControllers.first(where: { $0 is FilterMonitorSheetsViewController }) as? FilterMonitorSheetsViewController {
                // refresh list and pop to it
                listVC.callAPI(inventoryId: inventoryId, accountId: accountId, departmentName: "-1", locationName: "-1", componentCode: "-1")
                navigationController.popToViewController(listVC, animated: true)
                return
            } else {
                // not in stack: push a new FilterMonitorSheetsViewController and let it load
                if let vc = Storyboards.filterInventory.instantiate() as? FilterMonitorSheetsViewController {
                    navigationController.pushViewController(vc, animated: true)
                    vc.callAPI(inventoryId: inventoryId, accountId: accountId, departmentName: "-1", locationName: "-1", componentCode: "-1")
                    return
                }
            }
        }
    }
    
    func changeColorButton() {
        let arrayValidate = self.arrayData
        if arrayValidate.isEmpty {
            self.updateButton.layer.backgroundColor = UIColor(named: R.color.grey1.name)?.cgColor
            self.updateButton.isUserInteractionEnabled = false
            self.rejectButton.layer.backgroundColor = UIColor(named: R.color.greyDC.name)?.cgColor
            self.confirmButton.layer.backgroundColor = UIColor(named: R.color.grey1.name)?.cgColor
            self.setupColorButton(color: UIColor(named: R.color.lineColor.name) ?? .white)
            self.confirmButton.isUserInteractionEnabled = false
            self.isTapSubmit = false
        } else {
            if !arrayValidate.contains(where: { item in
                item.isCheckBox == false || item.isCheckBox == nil
            }) {
                self.updateButton.layer.backgroundColor = UIColor(named: R.color.greenColor.name)?.cgColor
                self.updateButton.isUserInteractionEnabled = true
                self.rejectButton.layer.backgroundColor = UIColor(named: R.color.grey1.name)?.cgColor
                self.confirmButton.layer.backgroundColor = UIColor(named: R.color.greenColor.name)?.cgColor
                self.setupColorButton(color: UIColor(named: R.color.white.name) ?? .white)
                self.confirmButton.isUserInteractionEnabled = true
                self.isTapSubmit = true
            } else {
                self.updateButton.layer.backgroundColor = UIColor(named: R.color.grey1.name)?.cgColor
                self.updateButton.isUserInteractionEnabled = false
                self.rejectButton.layer.backgroundColor = UIColor(named: R.color.greyDC.name)?.cgColor
                self.confirmButton.layer.backgroundColor = UIColor(named: R.color.grey1.name)?.cgColor
                self.setupColorButton(color: UIColor(named: R.color.lineColor.name) ?? .white)
                self.confirmButton.isUserInteractionEnabled = false
                self.isTapSubmit = false
            }
        }
    }
    
}

extension ActionInventoryViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SectionInventory(rawValue: section) {
        case .titleInventory,
                .sumInventory:
            return 1
        case .rowInventory:
            return arrayData.count
        case .titleHistory,
                .infoSheet:
            return 1
        case .imageViewCell:
            if evicenceImg?.count ?? 0 > 0 {
                return 1
            } else {
                return 0
            }
        case .historyInventory:
            return dataHistory.count
        case .noteInventory:
            return self.dataDetailSheets?.status == 6 ? 0 : 1
        case .errorTable:
            return !errorValid ? 0 : 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch SectionInventory(rawValue: indexPath.section) {
        case .infoSheet:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.infoTicketTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.delegateAddRow = self
            cell.fillDataMonitor(model: dataDetailSheets)
            cell.addRowButton.isHidden = true
            cell.selectionStyle = .none
            return cell
        case .titleInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            return cell
        case .rowInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.invenTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setDataToCellMonitor(data: arrayData[indexPath.row],index: indexPath.row, isLast: (arrayData.count - 1) == indexPath.row ? true : false, isHiddenCheckBox: dataDetailSheets?.status == 6, isHideTextField: false)
            cell.deleteRow = { (index) in
                if self.arrayData[index].id != nil {
                    self.arrayDelete.append(self.arrayData[index].id!)
                }
                self.arrayData.remove(at: index)
                var totalValue: Double = 0.0
                for item in self.arrayData {
                    if let quantityOfBom = item.quantityOfBom, let quantityPerBom = item.quantityPerBom {
                        totalValue = (quantityOfBom * quantityPerBom) + totalValue
                    }
                }
                
                self.valueSumTest = totalValue
                self.errorValid = false
                self.tableView.reloadData()
                self.changeColorButton()
            }
            cell.sumTotal = { (index, quantityPerBom, quantityOfBom, isCheckBox) in
                self.errorValid = false
                self.arrayData[index].quantityOfBom = quantityOfBom == "" ? nil : self.unFormatNumber(stringValue: quantityOfBom, regionUS: self.regionUS)
                self.arrayData[index].quantityPerBom = quantityPerBom == "" ? nil : self.unFormatNumber(stringValue: quantityPerBom, regionUS: self.regionUS)
                self.arrayData[index].isCheckBox = isCheckBox
                
                var totalValue: Double = 0.0
                for item in self.arrayData {
                    if let quantityOfBom = item.quantityOfBom, let quantityPerBom = item.quantityPerBom {
                        totalValue = (quantityOfBom * quantityPerBom) + totalValue
                    }
                }
                
                self.changeColorButton()
                self.valueSumTest = totalValue
                if self.tableView.indexPathsForVisibleRows?.contains(indexPath) != nil {
                    self.tableView.beginUpdates()
                    self.tableView.reloadSections(IndexSet(integer: SectionInventory.sumInventory.rawValue), with: .none)
                    self.tableView.reloadSections(IndexSet(integer: SectionInventory.errorTable.rawValue), with: .none)
                    self.tableView.endUpdates()
                }
            }
            cell.isCheckMonitor = { index, isCheck in
                self.arrayData[index].isCheckBox = isCheck
                self.changeColorButton()
            }
            return cell
        case .sumInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.totalItemTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            
            cell.setDataToCell(totalValue: valueSumTest)
            
            return cell
        case .errorTable:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.errorTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            return cell
        case .noteInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.noteCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            if self.dataDetailSheets?.status != 6 {
                cell.isHiddenAddButton = false
                cell.isMonitor = true
                cell.setDataToView()
                cell.hiddenReason = { (hiddenReason) in
                    self.isHiddenReason = hiddenReason
                    UIView.performWithoutAnimation {
                        tableView.reloadSections([indexPath.row], with: .none)
                    }
                    if hiddenReason {
                        self.note = ""
                    }
                }
                cell.getNote = { (note) in
                    self.note = note
                    self.updateRejectButtonState()
                }
            } else {
                cell.setDataForHistory(note: self.dataDetailSheets?.note ?? "")
            }
            return cell
        case .titleHistory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.noteCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.isHiddenAddButton = true
            cell.setDataForTitle()
            return cell
        case .imageViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.imageViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            if evicenceImg != nil {
                let modifiedString = evicenceImg?.replacingOccurrences(of: "\\", with: "/")
                cell.fillDataHistoryDetail(url: modifiedString ?? "")
            } else {
                cell.setDataToCell(data: self.imageCapture ?? UIImage())
            }
            cell.deleteAction = {
                if self.imageCapture != nil {
                    self.imageCapture = nil
                    self.tableView.reloadData()
                }
            }
            return cell
        case .historyInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.historyInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.fillDataDocC(data: self.dataHistory[indexPath.row])
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func updateRejectButtonState() {
        if  !self.note.isEmpty {
            self.rejectButton.isUserInteractionEnabled = true
            rejectButton.setTitleColor(UIColor(named: R.color.textDefault.name), for: .normal)
            let icDenied = UIImage(named: R.image.ic_close_black.name)
            let tintedImageClose = icDenied?.withRenderingMode(.alwaysTemplate)
            rejectButton.setImage(tintedImageClose, for: .normal)
            rejectButton.tintColor =  UIColor(named: R.color.textDefault.name)
            rejectButton.layer.backgroundColor = UIColor(named: R.color.grey2.name)?.cgColor
        } else {
            self.rejectButton.isUserInteractionEnabled = false
            let icDenied = UIImage(named: R.image.ic_close_black.name)
            let tintedImageClose = icDenied?.withRenderingMode(.alwaysTemplate)
            self.rejectButton.setImage(tintedImageClose, for: .normal)
            rejectButton.tintColor = UIColor(named: R.color.lineColor.name) ?? .white
            rejectButton.setTitleColor(UIColor(named: R.color.lineColor.name) ?? .white, for: .normal)
            rejectButton.layer.backgroundColor = UIColor(named: R.color.grey1.name)?.cgColor
        }
    }


    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch SectionInventory(rawValue: indexPath.section) {
        case .noteInventory:
            return self.isHiddenReason ? UITableView.automaticDimension : 130
        case .titleHistory:
            return 50
        case .rowInventory, .sumInventory, .titleInventory:
            return 60
        default:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch SectionInventory(rawValue: indexPath.section) {
        case .historyInventory:
            guard let vc = Storyboards.historyInventoryDetail.instantiate() as? HistoryInventoryDetailViewController else {return}
            vc.componentCode = dataDetailSheets?.componentCode ?? ""
            vc.componentName = dataDetailSheets?.componentName ?? ""
            vc.createAt = self.dataHistory[indexPath.row].createdAt?.formatDateWithInputAndOutputType(inputFormat: TypeFormatDate.ServerFormat.rawValue, outputFormat: TypeFormatDate.DD_MM_YYYY_HH_mm.rawValue) ?? ""
            vc.historyDetailId = self.dataHistory[indexPath.row].id ?? ""
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            return
        }
    }
    
}


