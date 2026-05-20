//
//  AccessoryController.swift
//  BIVN
//
//  Created by TVO_M1 on 7/1/25.
//

import Foundation
import UIKit
import Moya
class AccessoryController : BaseViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView! {
        didSet{
            tableView.register(R.nib.accessoryCell)
            tableView.register(R.nib.listErrorTableViewCell)
        }
    }
    @IBOutlet weak var emptyDataLabel: UILabel!
    
    let networkManager: NetworkManager = NetworkManager()
    var componentCode: String?
    var accessoryModel: AccessoryModels?
    var resultModel: ResultErrorModel?
    var dataTicket = DetailResponseDataTicket()
    var param = Dictionary<String, Any>()
    var employeeID: String?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        employeeID = UserDefaults.standard.string(forKey: "MANHANVIEN")
        getData()
    }
    
    private func getInventoryID() -> String{
        return UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? ""
        
    }
    private func getData(){
        self.startLoading()
        param["userCode"] = employeeID
        networkManager.getInvestigationDetail(inventoryID: getInventoryID(), componentCode: componentCode ?? "", params: param, completion: { data in
            switch data {
            case .success(let response):
                self.stopLoading()
                if response.code == 200 {
                    self.accessoryModel = response
                    self.tableView.reloadData()
                    if self.accessoryModel?.data?.documentList?.isEmpty ?? true {
                        self.emptyDataLabel.isHidden = false
                    } else {
                        self.emptyDataLabel.isHidden = true
                    }
                    
                } else {
                    self.showAlertNoti(
                        title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                        message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),
                        cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0),
                        acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0)
                    )
                }
            case .failure(let error):
                self.stopLoading()
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self.showAlertConfigTimeOut()
                    }
                }
            }
        })
    }
    
    private func callAPIUpdateStatus(inventoryId: String, componentCode: String) {
        networkManager.updateStatus(inventoryId: inventoryId, componentCode: componentCode, completion: { [weak self] data in
            guard let self = self else { return }
            self.isLoading = false
            switch data {
            case .success(let response):
                if response.code == 200 {
                    navigationController?.popViewController(animated: true)
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self.showAlertConfigTimeOut()
                    }
                }
                print(error.localizedDescription)
            }
        })
    }
    
    private func setupUI() {
        self.tableView.separatorStyle = .none
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.title = "Danh sách phiếu".localized()
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: #selector(onTapBack))
        self.navigationItem.leftBarButtonItem = buttonLeft
        emptyDataLabel.text = "Không có dữ liệu".localized()
        emptyDataLabel.font = fontUtils.size14.medium
    }
    
    @objc private func onTapBack() {
        callAPIUpdateStatus(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", componentCode: componentCode ?? "")
        navigationController?.popViewController(animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.accessoryModel?.data?.documentList?.count ?? -1) + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.listErrorTableViewCell, for:  indexPath) else { return UITableViewCell()}
            resultModel = ResultErrorModel()
            resultModel?.quantity = accessoryModel?.data?.errorQuantity ?? ""
            resultModel?.componentCode = accessoryModel?.data?.componentCode ?? ""
            resultModel?.status = accessoryModel?.data?.status ?? 0
            resultModel?.positionCode = accessoryModel?.data?.position ?? ""
            resultModel?.errorMoneyAbs = accessoryModel?.data?.errorMonyAbs
            cell.fillData(listErrorModel: resultModel)
            cell.hidenButton()
            cell.selectionStyle = .none
            cell.contentViewtotal.backgroundColor = UIColor(named: R.color.grey2.name)
            return cell
            
        default: guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.accessoryCell, for: indexPath) else { return UITableViewCell()}
            let dataItem = self.accessoryModel?.data?.documentList?[indexPath.row - 1]
            let quantityConvert = Int(Double(dataItem?.accountQuantity ?? "0.0") ?? 0.0)
            let bomConvert = Int(Double(dataItem?.bom ?? "0.0") ?? 0.0)
            cell.fillData(billName: dataItem?.docCode ?? "", billQuantity: String(quantityConvert), bom: String(bomConvert))
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row > 0 else { return } 
        let itemData = accessoryModel?.data?.documentList?[indexPath.row - 1]
        if let firstChar = itemData?.docCode?.first {
            switch firstChar {
            case "C":
                guard let vc = Storyboards.detailTicketsC.instantiate() as? DetailTicketCController else {return}
               vc.documentId = accessoryModel?.data?.documentList?[indexPath.row - 1].docId ?? ""
        vc.titleTicket = accessoryModel?.data?.documentList?[indexPath.row - 1].docCode ?? ""
                vc.documentInfo = self.resultModel
                vc.accessoryModel = self.accessoryModel
                navigationController?.pushViewController(vc, animated: true)
            case "A", "E":
        naviShowDetailDocAE(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", componentCode: accessoryModel?.data?.componentCode ?? "", isConfirm: false, positionCode: accessoryModel?.data?.position ?? "", docCode: itemData?.docCode ?? "")
            case "B":
                self.scanDocB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", componentCode: accessoryModel?.data?.componentCode ?? "", machineModel: "", machineType:"", lineName:  "", modelCode: "", actionType: 1, isErrorInvestigation: true, docCode: accessoryModel?.data?.documentList?[indexPath.row].docCode ?? "")
            default:
                break
            }
        }
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row{
        case 0:
            return 100
        default: return 70
        }
    }
    
    func navigateInventoryDetailVC(dataTicket: DetailResponseDataTicket, resetInventory: Bool) {
        guard let vc = Storyboards.ticketDetailA.instantiate() as? TicketDetailAViewController else {return}
        if let arrHistory = dataTicket.histories {
            for item in arrHistory {
                if item.evicenceImg != nil &&  item.evicenceImg != "" {
                    vc.evicenceImg = item.evicenceImg ?? ""
                    break
                }
            }
        }
        vc.dataTicket = dataTicket
        vc.isConfirmScan = false
        vc.resetInventory = resetInventory
        vc.accessoryModel = self.accessoryModel
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func scanDocB(inventoryId: String?, accountId: String?, componentCode: String?, machineModel: String?, machineType: String?, lineName: String?, modelCode: String?, actionType: Int?, isErrorInvestigation: Bool, docCode: String?) {
        self.startLoading()
        param["inventoryId"] = inventoryId ?? ""
        param["accountId"] = accountId ?? ""
        param["componentCode"] = componentCode ?? ""
        param["machineModel"] = machineModel ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineName ?? ""
        param["modelCode"] = modelCode ?? ""
        param["actionType"] = actionType
        param["isErrorInvestigation"] = true
        networkManager.scanDocB(isErrorInvestigation: isErrorInvestigation, param: param) { [weak self] result in
            switch result {
            case .success(let response):
                guard let `self` = self else { return }
                if response.code == 200 {
                    self.stopLoading()
                    let responseData = response.data ?? []
                    var docCodeList = responseData.filter({$0.inventoryDoc?.docCode == docCode})
                    if let docCodeList = docCodeList.first {
                        self.dataTicket = docCodeList
                    }
                    self.navigateInventoryDetailVC(dataTicket: self.dataTicket, resetInventory: true)
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
        
    
    private func naviShowDetailDocAE(inventoryId: String, accountId: String, componentCode: String, isConfirm: Bool, positionCode: String, docCode: String) {
        self.startLoading()
        guard InternetManager.isConnected() else {
            self.showAlerInternet()
            return
        }
        param["positionCode"] = positionCode
        param["docCode"] = docCode
        param["isErrorInvestigation"] = "true"
        
        let networkManager: NetworkManager = NetworkManager()
        networkManager.getDetailTicket(inventoryId: inventoryId, accountId: accountId, componentCode: componentCode, isConfirm: isConfirm, param: param) { [weak self] result in
            self?.stopLoading()
            switch result {
            case .success(let response):
                guard let `self` = self else { return }
                if response.code == 200 {
                    let responseData = response.data ?? []
                    dataTicket = responseData.first!
                    guard let vc = Storyboards.ticketDetailA.instantiate() as? TicketDetailAViewController else {return}
                    if let arrHistory = dataTicket.histories {
                        for item in arrHistory {
                            if item.evicenceImg != nil &&  item.evicenceImg != "" {
                                vc.evicenceImg = item.evicenceImg ?? ""
                                break
                            }
                        }
                    }
                    vc.dataTicket = dataTicket
                    vc.isConfirmScan = false
                    vc.resetInventory = true
                    vc.accessoryModel = self.accessoryModel
                    self.navigationController?.pushViewController(vc, animated: true)
                    
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(isLogin: false, code: response.code) {  _ in
                    }
                } else if response.code == 400 || response.code == 83 {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: response.message ?? "",cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) ,acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0), acceptOnTap: {
                    } ,cancelOnTap:  {
                    })
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
}
