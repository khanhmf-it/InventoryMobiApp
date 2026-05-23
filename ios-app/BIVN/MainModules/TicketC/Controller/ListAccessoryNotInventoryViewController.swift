//
//  ListAccessoryNotInventoryViewController.swift
//  BIVN
//
//  Created by TinhVan Software on 09/05/2024.
//

import UIKit
import Moya
import Localize_Swift

class ListAccessoryNotInventoryViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(UINib(nibName: "ListAccessoryNotInventoryABECell", bundle: nil), forCellReuseIdentifier: "ListAccessoryNotInventoryABECell")
            tableView.register(UINib(nibName: "InventoryTableViewCell", bundle: nil), forCellReuseIdentifier: "InventoryTableViewCell")
        }
    }
    @IBOutlet weak var errorDataLabel: UILabel!
    
    let networkManager: NetworkManager = NetworkManager()
    var titleString: String?
    var listDataDocB: [DocBInfoModels] = []
    var listDataDocAE: [DocAEInfoModels] = []
    var listDataDocC: [DocCInfoModels] = []
    var listDocB = ListDocB()
    var listDocC = ArrayData()
    var param = Dictionary<String, Any>()
    var model: String?
    var modelCode: String?
    var machineType: String?
    var lineCode: String = ""
    var pageNumber = 1
    var docType: String?
    var jobIndex : Int = 0
    var currentUserID = ""
    var isConfirmScan: Bool = false
    var isCheckLoadMore: Bool = true
    var componentCode = ""
    var positionCode = ""
    var docCode = ""
    var reloadListDocB: ((ListDocB) -> Void)?
    var reloadListDocC: ((ArrayData) -> Void)?
    var isReload: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        if docType == "AE" {
            getListDocAE(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", pageNumber: pageNumber, actionType: self.jobIndex)
        }
    }
    
    private func setupView() {
        currentUserID = UserDefault.shared.getUserID()
        tableView.delegate = self
        tableView.dataSource = self
        let yourBackImage = UIImage(named: R.image.ic_back.name)
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.tintColor = UIColor.gray
        self.navigationItem.setHidesBackButton(true, animated: true)
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: #selector(onTapNotification))
        self.navigationItem.leftBarButtonItem = buttonLeft
        self.title = titleString
        isHidenLabelErrorData()
        setFontTitleNavBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UserDefault.shared.getReload() {
            listDataDocC = []
            getListDocC(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, stageName: "", modelCode: "", actionType: self.jobIndex, pageNumber: self.pageNumber)
            UserDefault.shared.setReload(isReload: false)
        }
        if jobIndex == 1 {
            isConfirmScan = true
            if docType == "C" {
                titleLabel.text = "Danh sách phiếu chờ xác nhận".localized()
            } else {
                titleLabel.text = "Danh sách LK chờ xác nhận".localized()
                tableView.separatorStyle = .none
            }
        } else if jobIndex == 2 {
            isConfirmScan = false
            if docType == "C" {
                titleLabel.text = "Danh sách phiếu cần giám sát".localized()
            } else {
                titleLabel.text = "Danh sách LK cần giám sát".localized()
                tableView.separatorStyle = .none
            }
        } else {
            isConfirmScan = false
            if docType == "C" {
                titleLabel.text = "Danh sách phiếu chưa kiểm kê".localized()
            } else {
                titleLabel.text = "Danh sách LK chưa kiểm kê".localized()
                tableView.separatorStyle = .none
            }
        }
        tableView.isUserInteractionEnabled = true
        tableView.reloadData()
    }
    
    @objc private func onTapNotification() {
        if docType == "B" {
            reloadListDocB?(self.listDocB)
        } else if docType == "C" {
            reloadListDocC?(self.listDocC)
        } else {}
        navigationController?.popViewController(animated: true)
    }
    
    private func reloadTableViewDocAE(docAE: [DocAEInfoModels]) {
        if self.jobIndex == 0 {
            let listDocAE = docAE.filter({ $0.status == 2})
            self.listDataDocAE.append(contentsOf: listDocAE)
        } else {
            let listDocAE = docAE.filter({ $0.status == 3})
            self.listDataDocAE.append(contentsOf: listDocAE)
        }
        if self.listDataDocAE.count == 0 {
            errorDataLabel.isHidden = false
            return
        } else {
            errorDataLabel.isHidden = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tableView.reloadData()
        }
    }
    
    private func reloadTableViewDocB(docB: [DocBInfoModels]) {
        if self.jobIndex == 0 {
            let listDocB = docB.filter({ $0.status == 2})
            self.listDataDocB.append(contentsOf: listDocB)
        } else {
            let listDocB = docB.filter({ $0.status == 3})
            self.listDataDocB.append(contentsOf: listDocB)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tableView.reloadData()
        }
    }
    
    private func reloadTableViewDocC(docC: [DocCInfoModels]) {
        if self.jobIndex == 0 {
            let listDocC = docC.filter({ $0.status == 2})
            self.listDataDocC.append(contentsOf: listDocC)
        } else if self.jobIndex == 2 {
            let listDocC = docC.filter({ ($0.status ?? 0) >= 5 })
            self.listDataDocC.append(contentsOf: listDocC)
        } else {
            let listDocC = docC.filter({ $0.status == 3})
            self.listDataDocC.append(contentsOf: listDocC)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tableView.reloadData()
        }
    }
    
    private func getListDocAE(inventoryId: String?, accountId: String?, pageNumber: Int, actionType: Int?) {
        param["inventoryId"] = inventoryId ?? ""
        param["accountId"] = accountId ?? ""
        param["actionType"] = actionType
        param["pageNum"] = pageNumber
        param["pageSize"] = 20
        
        self.startLoading()
        networkManager.getListdocAE(param: param) {[weak self] data in
            self?.stopLoading()
            switch data {
            case .success(let response):
                if response.code == 200 {
                    let docAE = response.data?.docAEInfoModels ?? []
                    if docAE.count > 0 {
                        self?.reloadTableViewDocAE(docAE: docAE)
                    } else {
                        self?.isCheckLoadMore = false
                        self?.reloadTableViewDocAE(docAE: docAE)
                    }
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self?.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        getListDocAE(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", pageNumber: pageNumber, actionType: self.jobIndex)
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
    
    private func getListDocB(inventoryId: String?, accountId: String?, model: String?, machineType: String?, lineName: String?, modelCode: String?, pageNumber: Int, actionType: Int?) {
        param["inventoryId"] = inventoryId ?? ""
        param["accountId"] = accountId ?? ""
        param["machineModel"] = model ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineName ?? ""
        param["actionType"] = actionType
        param["stageName"] = ""
        param["modelCode"] = modelCode ?? ""
        param["pageNum"] = pageNumber
        param["pageSize"] = 20
        
        networkManager.getListdocB(param: param) {[weak self] data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self?.listDocB = response.data ?? ListDocB()
                    let docB = response.data?.docBInfoModels ?? []
                    if docB.count > 0 {
                        self?.reloadTableViewDocB(docB: docB)
                    } else {
                        self?.isCheckLoadMore = false
                    }
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self?.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        getListDocB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", model: self.model, machineType: self.machineType, lineName: self.lineCode, modelCode: self.modelCode, pageNumber: self.pageNumber, actionType: self.jobIndex)
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
    
    private func getListDocC(inventoryId: String?, accountId: String?, machineModel: String?, machineType: String?, lineName: String?, stageName: String?, modelCode: String?, actionType: Int?, pageNumber: Int) {
        param["inventoryId"] = inventoryId ?? ""
        param["accountId"] = accountId ?? ""
        param["machineModel"] = machineModel ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineName ?? ""
        param["actionType"] = actionType ?? 0
        param["stageName"] = stageName ?? ""
        param["modelCode"] = modelCode ?? ""
        param["pageNum"] = pageNumber
        param["pageSize"] = 20
        
        networkManager.scanListDocC(param: param) { [weak self] result in
            switch result {
            case .success(let response):
                guard let `self` = self else { return }
                if response.code == 200 {
                    self.listDocC = response.data ?? ArrayData()
                    let docC = response.data?.docCInfoModels ?? []
                    if docC.count > 0 {
                        self.reloadTableViewDocC(docC: docC)
                    } else {
                        self.isCheckLoadMore = false
                    }
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        getListDocC(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, stageName: "", modelCode: "", actionType: self.jobIndex, pageNumber: self.pageNumber)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if docType == "AE" {
            return listDataDocAE.count
        } else if docType == "B"{
            return listDataDocB.count
        } else {
            return listDataDocC.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListAccessoryNotInventoryABECell", for: indexPath) as! ListAccessoryNotInventoryABECell
        guard let cellC = tableView.dequeueReusableCell(withIdentifier: R.nib.inventoryTableViewCell, for: indexPath) else {return UITableViewCell()}
        if docType == "AE" {
            cell.fillDataDocAE(model: listDataDocAE[indexPath.row])
        } else if docType == "B" {
            cell.fillDataDocB(model: listDataDocB[indexPath.row])
        } else {
            cellC.fillData(model: listDataDocC[indexPath.row])
            cellC.titleTypeOfStageLabel.text = "Cụm ảo".localized()
            cellC.valueTypeOfStageLabel.text = listDataDocC[indexPath.row].modelCode
            cellC.statusStackView.isHidden = true
            cellC.selectionStyle = .none
            return cellC
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.isUserInteractionEnabled = false
        if docType == "AE" {
            self.componentCode = listDataDocAE[indexPath.row].componentCode ?? ""
            self.positionCode = listDataDocAE[indexPath.row].positionCode ?? ""
            self.docCode = listDataDocAE[indexPath.row].docCode ?? ""
            self.naviShowDetailDocAE(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", componentCode: self.componentCode, isConfirm: self.isConfirmScan, positionCode: self.positionCode, docCode: self.docCode)
        } else if docType == "B"{
            self.componentCode = listDataDocB[indexPath.row].componentCode ?? ""
            self.naviShowDetailDocB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", componentCode: self.componentCode, machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, modelCode: self.modelCode,  isConfirm: self.jobIndex, isErrorInvestigation: false)
        } else {
            naviShowDetailDocC(docCInfoModels: listDataDocC[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if isCheckLoadMore {
            if docType == "AE" {
                if indexPath.row == self.listDataDocAE.count - 5 {
                    self.pageNumber += 1
                    getListDocAE(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", pageNumber: pageNumber, actionType: self.jobIndex)
                }
            } else if docType == "B" {
                if indexPath.row == self.listDataDocB.count - 5 {
                    self.pageNumber += 1
                    getListDocB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", model: self.model, machineType: self.machineType, lineName: self.lineCode, modelCode: self.modelCode, pageNumber: self.pageNumber, actionType: self.jobIndex)
                }
            } else {
                if indexPath.row == self.listDataDocC.count - 5 {
                    self.pageNumber += 1
                    getListDocC(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, stageName: "", modelCode: "", actionType: self.jobIndex, pageNumber: self.pageNumber)
                }
            }
        }
    }
    
    var listDataTicket = [DetailResponseDataTicket]()
    private func naviShowDetailDocAE(inventoryId: String, accountId: String, componentCode: String, isConfirm: Bool, positionCode: String, docCode: String) {
        self.startLoading()
        guard InternetManager.isConnected() else {
            self.showAlerInternet()
            return
        }
        var param = Dictionary<String, Any>()
        let trimmedPositionCode = positionCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPositionCode.isEmpty {
            param["positionCode"] = trimmedPositionCode
        }
        param["docCode"] = docCode
        param["isErrorInvestigation"] = "false"
        
        let networkManager: NetworkManager = NetworkManager()
        networkManager.getDetailTicket(inventoryId: inventoryId, accountId: accountId, componentCode: componentCode, isConfirm: isConfirm, param: param) { [weak self] result in
            self?.stopLoading()
            switch result {
            case .success(let response):
                guard let `self` = self else { return }
                if response.code == 200 {
                    let responseData = response.data ?? []
                    guard !responseData.isEmpty else {
                        self.showAlertNoti(title: "Thông báo".localized(), message: "Không tìm thấy chi tiết phiếu".localized(), acceptButton: "Đồng ý".localized())
                        return
                    }
                    self.listDataTicket = responseData
                    var arrayString = [String]()
                    var arrayStatus = [Int]()
                    
                    for item in self.listDataTicket {
                        arrayString.append(item.inventoryDoc?.positionCode ?? "")
                        if let status = item.inventoryDoc?.status {
                            arrayStatus.append(status)
                        }
                    }
                    
                    if arrayString.count == 1 {
                        //    old status la chua kiem ke
                        //    new status la cho xac nhan
                        //    ma nhan vien trung vs nguoi tao createdBy
                        
                        let listHistory = self.listDataTicket.first?.histories ?? []
                        let inventoryDoc = self.listDataTicket.first?.inventoryDoc
                        
                        var isShowPopupInventory = false
                        for item in listHistory {
                            if self.isConfirmScan {
                                if item.status == 3 || item.status == 5 {
                                    isShowPopupInventory = true
                                }
                            } else {
                                if item.status == 3 || item.status == 5 {
                                    isShowPopupInventory = true
                                }
                            }
                        }
                        //918257159
                        if isShowPopupInventory {
                            if self.jobIndex == 0 {
                                self.showAlertNoti(title: "Thông báo".localized(), message: "Đã được kiểm kê. Bạn có muốn kiểm kê lại không".localized(), cancelButton: "Hủy bỏ".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                                    self.navigateDetailDocABE(dataTicket: self.listDataTicket.first ?? DetailResponseDataTicket(), resetInventory: true)
                                })
                            } else {
                                if UserDefault.shared.getUserID() == self.listDataTicket.first?.inventoryDoc?.inventoryBy {
                                    self.showAlertNoti(title: "Thông báo".localized(), message: "Bạn không được xác nhận phiếu này".localized(),acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                                    })
                                } else {
                                    self.navigateDetailDocABE(dataTicket: self.listDataTicket.first ?? DetailResponseDataTicket(), resetInventory: false)
                                }
                            }
                        } else {
                            self.navigateDetailDocABE(dataTicket: self.listDataTicket.first ?? DetailResponseDataTicket(), resetInventory: false)
                        }
                    } else {
                        // show popup
                        self.showPopUpAlertTicket(title: "Chọn vị trí".localized(), array: arrayString, status: arrayStatus) {
                        } accept: { indexValue in
                            let listHistory = self.listDataTicket[indexValue].histories ?? []
                            let inventoryDoc = self.listDataTicket[indexValue].inventoryDoc
                            
                            var isShowPopupInventory = false
                            for item in listHistory {
                                if self.isConfirmScan {
                                    if item.status == 3 || item.status == 5 {
                                        isShowPopupInventory = true
                                    }
                                } else {
                                    if item.status == 3 || item.status == 5 {
                                        isShowPopupInventory = true
                                    }
                                }
                            }
                            
                            if isShowPopupInventory {
                                if self.jobIndex == 0 {
                                    self.showAlertNoti(title: "Thông báo".localized(), message: "Đã được kiểm kê. Bạn có muốn kiểm kê lại không".localized(), cancelButton: "Hủy bỏ".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                                        self.navigateDetailDocABE(dataTicket: self.listDataTicket[indexValue], resetInventory: true)
                                    })
                                } else {
                                    if UserDefault.shared.getUserID() == self.listDataTicket.first?.inventoryDoc?.inventoryBy {
                                        self.showAlertNoti(title: "Thông báo".localized(), message: "Bạn không được xác nhận phiếu này".localized(),acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                                        })
                                    } else {
                                        self.navigateDetailDocABE(dataTicket: self.listDataTicket[indexValue], resetInventory: false)
                                    }
                                }
                            } else {
                                self.navigateDetailDocABE(dataTicket: self.listDataTicket[indexValue], resetInventory: false)
                            }
                        }
                    }
                    
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(isLogin: false, code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        self.naviShowDetailDocAE(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", componentCode: self.componentCode, isConfirm: self.isConfirmScan, positionCode: self.positionCode, docCode: self.docCode)
                    }
                } else if response.code == 400 || response.code == 83 {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: response.message ?? "",cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) ,acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0), acceptOnTap: {
                    } ,cancelOnTap:  {
                    })
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0), acceptOnTap: {
                    }, cancelOnTap:  {
                    })
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
    
    func naviShowDetailDocB(inventoryId: String?, accountId: String?, componentCode: String?, machineModel: String?, machineType: String?, lineName: String?, modelCode: String?, isConfirm: Int, isErrorInvestigation: Bool) {
        param["inventoryId"] = inventoryId ?? ""
        param["accountId"] = accountId ?? ""
        param["componentCode"] = componentCode ?? ""
        param["machineModel"] = machineModel ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineName ?? ""
        param["modelCode"] = modelCode ?? ""
        param["actionType"] = isConfirm
        networkManager.scanDocB(isErrorInvestigation: isErrorInvestigation,param: param) { [weak self] result in
            switch result {
            case .success(let response):
                guard let `self` = self else { return }
                if response.code == 200 {
                    let responseData = response.data ?? []
                    self.listDataTicket = responseData
                    var arrayString = [String]()
                    var arrayStatus = [Int]()
                    
                    for item in self.listDataTicket {
                        arrayString.append(item.inventoryDoc?.positionCode ?? "")
                        if let status = item.inventoryDoc?.status {
                            arrayStatus.append(status)
                        }
                    }
                    //    old status la chua kiem ke
                    //    new status la cho xac nhan
                    //    ma nhan vien trung vs nguoi tao createdBy
                    
                    let listHistory = self.listDataTicket.first?.histories ?? []
                    let inventoryDoc = self.listDataTicket.first?.inventoryDoc
                    
                    var isShowPopupInventory = false
                    for item in listHistory {
                        if self.isConfirmScan {
                            if item.status == 3 || item.status == 5 {
                                isShowPopupInventory = true
                            }
                        } else {
                            if item.status == 3 || item.status == 5 {
                                isShowPopupInventory = true
                            }
                        }
                    }
                    //918257159
                    self.navigateDetailDocABE(dataTicket: self.listDataTicket.first ?? DetailResponseDataTicket(), resetInventory: false)
                    //                    if isShowPopupInventory {
                    //                        if self.jobIndex == 0 {
                    //                            self.showAlertNoti(title: "Thông báo".localized(), message: "Đã được kiểm kê. Bạn có muốn kiểm kê lại không?".localized(), cancelButton: "Hủy bỏ".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                    //                                self.navigateDetailDocABE(dataTicket: self.listDataTicket.first ?? DetailResponseDataTicket(), resetInventory: true)
                    //                            })
                    //                        } else {
                    //                            if UserDefault.shared.getUserID() == self.listDataTicket.first?.inventoryDoc?.inventoryBy {
                    //                                self.showAlertNoti(title: "Thông báo".localized(), message: "Bạn không được xác nhận phiếu này".localized(),acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                    //                                })
                    //                            } else {
                    //                                self.navigateDetailDocABE(dataTicket: self.listDataTicket.first ?? DetailResponseDataTicket(), resetInventory: false)
                    //                            }
                    //                        }
                    //                    } else {
                    //                        self.navigateDetailDocABE(dataTicket: self.listDataTicket.first ?? DetailResponseDataTicket(), resetInventory: false)
                    //                    }
                    
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        self.naviShowDetailDocB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", componentCode: self.componentCode, machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, modelCode: self.modelCode,  isConfirm: self.jobIndex, isErrorInvestigation: false)
                    }
                } else if response.code == 400 || response.code == 83 {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: response.message ?? "",cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) ,acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0), acceptOnTap: {
                    } ,cancelOnTap:  {
                    })
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0), acceptOnTap: {
                    }, cancelOnTap:  {
                    })
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
    
    func navigateDetailDocABE(dataTicket: DetailResponseDataTicket, resetInventory: Bool ) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "InventoryDetailViewController") as! InventoryDetailViewController
        if let arrHistory = dataTicket.histories {
            for item in arrHistory {
                if item.evicenceImg != nil {
                    vc.evicenceImg = item.evicenceImg ?? ""
                    break
                }
            }
        }
        vc.dataTicket = dataTicket
        vc.isConfirmScan = self.isConfirmScan
        vc.jobIndex = self.jobIndex
        vc.resetInventory = resetInventory
        self.navigationController?.pushViewController(vc, animated: true)
        vc.reloadDataSubmit = { [weak self] in
            guard let self = self else { return }
            self.pageNumber = 1
            self.listDataDocB = []
            self.listDataDocAE = []
            self.listDataDocC = []
            if docType == "AE" {
                getListDocAE(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", pageNumber: pageNumber, actionType: self.jobIndex)
            } else {
                getListDocB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", model: self.model, machineType: self.machineType, lineName: self.lineCode, modelCode: self.modelCode, pageNumber: self.pageNumber, actionType: self.jobIndex)
            }
        }
    }
    
    func naviShowDetailDocC(docCInfoModels: DocCInfoModels) {
        if jobIndex == 0 {
            if docCInfoModels.confirmedBy == currentUserID {
                guard let vc = Storyboards.waitConfirmationC.instantiate() as? WaitConfirmationViewController else {return}
                vc.isBackThreeSeconds = false
                vc.documentId = docCInfoModels.id ?? ""
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                guard let vc = storyboard?.instantiateViewController(withIdentifier: R.storyboard.ticketC.ballotCountViewController) else {return}
                title = ""
                vc.documentId = docCInfoModels.id
                vc.viewController = 1
                vc.reloadDataSubmit = { [weak self] in
                    guard let self = self else { return }
                    self.pageNumber = 1
                    self.listDataDocC = []
                    getListDocC(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, stageName: "", modelCode: "", actionType: self.jobIndex, pageNumber: self.pageNumber)
                }
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else if jobIndex == 2 {
            if (docCInfoModels.status ?? 0) < 5 {
                self.showAlertError(title: "Lỗi".localized(), message: "Công đoạn này chưa được thực hiện xác nhận kiểm kê. Vui lòng thử lại".localized(), titleButton: "Đồng ý".localized())
                return
            }
            if (docCInfoModels.status ?? 0) != 5 && (docCInfoModels.status ?? 0) != 6 && (docCInfoModels.status ?? 0) != 7 {
                self.showAlertError(title: "Lỗi".localized(), message: "Công đoạn này không nằm trong danh sách giám sát. Vui lòng thử lại".localized(), titleButton: "Đồng ý".localized())
                return
            }
            if docCInfoModels.status == 6 {
                self.showAlertNoti(title: "Thông báo".localized(), message: "Đã được giám sát. Bạn có muốn giám sát lại không".localized(), cancelButton: "Hủy bỏ".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap: {
                    guard let vc = self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.ticketC.ballotCountViewController) else {return}
                    self.title = ""
                    vc.documentId = docCInfoModels.id
                    vc.viewController = 2
                    vc.isMonitorMode = true
                    self.navigationController?.pushViewController(vc, animated: true)
                })
            } else {
                guard let vc = storyboard?.instantiateViewController(withIdentifier: R.storyboard.ticketC.ballotCountViewController) else {return}
                title = ""
                vc.documentId = docCInfoModels.id
                vc.viewController = 2
                vc.isMonitorMode = true
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            if docCInfoModels.status ?? 0 > 2 {
                if docCInfoModels.inventoryBy == currentUserID {
                    guard let vc = Storyboards.waitConfirmationC.instantiate() as? WaitConfirmationViewController else {return}
                    vc.isBackThreeSeconds = false
                    vc.documentId = docCInfoModels.id ?? ""
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let vc = Storyboards.AccepticketC.instantiate() as! AccepticketCController
                    title = ""
                    vc.documentId = docCInfoModels.id
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                self.showAlertError(title: "Lỗi".localized(), message: "Công đoạn này chưa được thực hiện kiểm kê. Vui lòng thử lại".localized(), titleButton: "Đồng ý".localized())
            }
        }
    }
    
    func isHidenLabelErrorData() {
        if docType == "B" {
            if listDataDocB.count == 0 {
                errorDataLabel.isHidden = false
            } else {
                errorDataLabel.isHidden = true
            }
        } else if docType == "C" {
            if listDataDocC.count == 0 {
                errorDataLabel.isHidden = false
            } else {
                errorDataLabel.isHidden = true
            }
        } else {
            errorDataLabel.isHidden = true
        }
    }
}
