//
//  FilterMonitorSheetsViewController.swift
//  BIVN
//
//  Created by tinhvan on 28/11/2023.
//

import UIKit
import DropDown
import Moya
import Localize_Swift

class FilterMonitorSheetsViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, TestDelegate {
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var filtterButton: UIButton!
    @IBOutlet weak var contentFilterView: UIView!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(R.nib.monitoringSheetsCell)
        }
    }
    
    var param = Dictionary<String, Any>()
    let networkManager: NetworkManager = NetworkManager()
    var listDataAudit: [AuditInfoModels] = []
    var listDataFilter: [AuditInfoModels] = []
    let myDropDown = DropDown()
    let viewcontroller = Storyboards.sheetsInventory.instantiate() as? SheetsInventoryViewController
    var countTotal: String = ""
    private var selectedIsDocC: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        addSearch()
        setupTableView()
        loadMonitorDataBySelectedDocType()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewcontroller?.close()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParent,
           let previousVC = self.navigationController?.viewControllers.last,
           (previousVC is ScanCodeMCViewController || previousVC is MainViewController) {
            UserDefault.shared.removeMonitorDocType()
        }
    }
    
    private func setupView() {
        emptyLabel.isHidden = true
        contentFilterView.addBottomShadow()
        let yourBackImage = UIImage(named: R.image.ic_back.name)
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationItem.setHidesBackButton(true, animated: true)
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: #selector(onTapNotification))
        self.navigationItem.leftBarButtonItem = buttonLeft
        self.statusLabel.text = "Đã giám sát:".localized()
        self.setFontTitleNavBar()
        self.title = "Danh sách phiếu cần giám sát".localized()
    }
    
    private func countSheets(finishCount: Int?, totalCount: Int?) {
        self.countLabel.attributedText = self.setAtribute(message1: "\(finishCount?.description ?? "")/", message2: totalCount?.description ?? "", message3: " phiếu".localized(), textColor1: UIColor(named: R.color.greenColor.name)!, textColor2: UIColor(named: R.color.greenColor.name)!, textColor3: UIColor(named: R.color.greenColor.name)!)
    }
    
    func setAtribute(message1: String, message2: String, message3: String, textColor1: UIColor, textColor2: UIColor, textColor3: UIColor)  -> NSAttributedString {
        
        let attributedText = NSMutableAttributedString()
        let str1 = message1
        let str2 = message2
        let str3 = message3
        let attr1 = [NSAttributedString.Key.foregroundColor: textColor1, NSAttributedString.Key.font: fontUtils.size12.regular]
        let attr2 = [NSAttributedString.Key.foregroundColor: textColor2, NSAttributedString.Key.font: fontUtils.size12.regular]
        let attr3 = [NSAttributedString.Key.foregroundColor: textColor3, NSAttributedString.Key.font: fontUtils.size12.regular]
        attributedText.append(NSAttributedString(string: str1, attributes: attr1 as [NSAttributedString.Key : Any]))
        attributedText.append(NSAttributedString(string: str2, attributes: attr2 as [NSAttributedString.Key : Any]))
        attributedText.append(NSAttributedString(string: str3, attributes: attr3 as [NSAttributedString.Key : Any]))
        
        return attributedText
    }
    
    @objc private func onTapNotification(){
        self.navigationController?.popViewController(animated: true)
    }
    
    private func addSearch() {
        filtterButton.setTitle("", for: .normal)
        roomLabel.text = "Tất cả".localized()
        areaLabel.text = "Tất cả".localized()
        codeLabel.text = "Tất cả".localized()
    }

    private func loadMonitorDataBySelectedDocType() {
        if let savedIsDocC = UserDefault.shared.getMonitorDocType() {
            selectedIsDocC = savedIsDocC
            self.callAPI(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId,
                         accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId,
                         departmentName: "-1",
                         locationName: "-1",
                         componentCode: "-1",
                         isDocC: savedIsDocC)
            return
        }
        showChooseMonitorDocTypePopup()
    }
    
    private func showChooseMonitorDocTypePopup() {
        let inventoryId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId
        let accountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId

        loadMonitorDocTypeCounts(inventoryId: inventoryId, accountId: accountId) { [weak self] countABE, countC in
            guard let self = self else { return }
            let popupData = [
                self.monitorDocTypeOptionTitle(baseTitle: "Loại phiếu A,B,E".localized(), count: countABE),
                self.monitorDocTypeOptionTitle(baseTitle: "Loại phiếu C".localized(), count: countC)
            ]
            self.showPopUpAlert(title: "Chọn loại phiếu".localized(), array: popupData) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            } accept: { [weak self] index in
                guard let self = self else { return }
                let isDocC = index == 1
                self.selectedIsDocC = isDocC
                UserDefault.shared.setMonitorDocType(isDocC: isDocC)
                self.callAPI(inventoryId: inventoryId,
                             accountId: accountId,
                             departmentName: "-1",
                             locationName: "-1",
                             componentCode: "-1",
                             isDocC: isDocC)
            }
        }
    }

    private func loadMonitorDocTypeCounts(inventoryId: String?, accountId: String?, completion: @escaping (String?, String?) -> Void) {
        callAPICount(inventoryId: inventoryId,
                     accountId: accountId,
                     departmentName: "-1",
                     locationName: "-1",
                     componentCode: "-1",
                     isDocC: false,
                     completion: completion)
    }

    private func monitorDocTypeOptionTitle(baseTitle: String, count: String?) -> String {
        guard let count = count else { return baseTitle }
        return "\(baseTitle) (\(count))"
    }

    func callAPI(inventoryId: String?, accountId: String?, departmentName: String?, locationName: String?, componentCode: String?, isDocC: Bool? = nil) {
        let monitorDocC = isDocC ?? selectedIsDocC
        selectedIsDocC = monitorDocC
        param["inventoryId"] = inventoryId ?? ""
        param["accountId"] = accountId ?? ""
        param["departmentName"] = departmentName ?? "-1"
        param["locationName"] = locationName ?? "-1"
        param["componentCode"] = componentCode ?? "-1"
        param["IsDocC"] = monitorDocC
        networkManager.getListAudit(param: param) {[weak self] data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self?.listDataAudit = response.data?.auditInfoModels ?? []
                    self?.listDataFilter = response.data?.auditInfoModels ?? []
                    self?.sortMonitorList()
                    self?.emptyData(listData: self?.listDataFilter ?? [])
                    if let finishCount = response.data?.finishCount, let totalCount = response.data?.totalCount {
                        self?.countSheets(finishCount: finishCount, totalCount: totalCount)
                    }
                    self?.setupView()
                    self?.tableView.reloadData()
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self?.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.callAPI(inventoryId: inventoryId, accountId: accountId, departmentName: departmentName, locationName: locationName, componentCode: componentCode,isDocC: isDocC)
                        }
                    }
                } else {
                    self?.listDataAudit = []
                    self?.listDataFilter = []
                    self?.tableView.reloadData()
                    self?.emptyData(listData: self?.listDataFilter ?? [])
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
    // Lấy dữ liệu count cho từng loại phiếu để hiển thị khi chọn loại phiếu//
    func callAPICount(inventoryId: String?, accountId: String?, departmentName: String?, locationName: String?, componentCode: String?, isDocC: Bool? = nil, completion: ((String?, String?) -> Void)? = nil) {
        let monitorDocC = isDocC ?? selectedIsDocC
        var countParam = Dictionary<String, Any>()
        countParam["inventoryId"] = inventoryId ?? ""
        countParam["accountId"] = accountId ?? ""
        countParam["departmentName"] = departmentName ?? "-1"
        countParam["locationName"] = locationName ?? "-1"
        countParam["componentCode"] = componentCode ?? "-1"
        countParam["IsDocC"] = monitorDocC
        networkManager.getCountListAudit(param: countParam) {[weak self] data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    completion?(response.data?.docABECount, response.data?.docCCount)
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self?.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.callAPICount(inventoryId: inventoryId,
                                              accountId: accountId,
                                              departmentName: departmentName,
                                              locationName: locationName,
                                              componentCode: componentCode,
                                              isDocC: isDocC,
                                              completion: completion)
                        } else {
                            completion?(nil, nil)
                        }
                    }
                } else {
                    completion?(nil, nil)
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self?.showAlertConfigTimeOut()
                    }
                }
                print(error.localizedDescription)
                completion?(nil, nil)
            }
        }
    }
    private func emptyData(listData: [AuditInfoModels]) {
        if listData.count == 0 {
            self.emptyLabel.isHidden = false
            self.lineView.isHidden = true
        } else {
            self.emptyLabel.isHidden = true
            self.lineView.isHidden = false
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }

    // Sort list so that unmonitored items appear first, then monitored items; within groups sort by positionCode
    func sortMonitorList() {
        self.listDataFilter.sort { lhs, rhs in
            let lhsMonitored = (lhs.status == 6 || lhs.status == 7)
            let rhsMonitored = (rhs.status == 6 || rhs.status == 7)
            if lhsMonitored != rhsMonitored {
                return !lhsMonitored && rhsMonitored
            }
            return (lhs.positionCode ?? "") < (rhs.positionCode ?? "")
        }
    }
    
    func passData(room: String?, area: String?, partCode: String?) {
        self.roomLabel.text = room
        self.areaLabel.text = area
        self.codeLabel.text = partCode
        self.callAPI(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId, accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId, departmentName: room == "Tất cả".localized() ? "-1" : room, locationName: area == "Tất cả".localized() ? "-1" : area, componentCode: partCode == "Tất cả".localized() ? "-1" : partCode, isDocC: selectedIsDocC)
    }
    
    @IBAction func onTapFilter(_ sender: UIButton) {
        if viewcontroller?.isEnable != true {
            if let vc = viewcontroller {
                if #available(iOS 15.0, *) {
                    if let sheet = vc.sheetPresentationController{
                        sheet.detents = [.medium(), .large()] // Sheet style
                        sheet.prefersScrollingExpandsWhenScrolledToEdge = false // Inside Scrolling
                        sheet.prefersGrabberVisible = true // Grabber button
                        sheet.preferredCornerRadius = 24 // Radius
                        sheet.largestUndimmedDetentIdentifier = .medium //Avoid dismiss
                    }
                }
                vc.delegate = self
                vc.isEnable = true
                self.navigationController?.present(vc, animated: true)
            }
        }
    }
    
    func getDetailSheetsMonitor(inventoryId: String, accountId: String, documentId: String, actionType: Int) {
        networkManager.getDetailSheetsMonitor(inventoryId: inventoryId, accountId: accountId, documentId: documentId, actionType: 2) {data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    guard let vc = Storyboards.acctionInventory.instantiate() as? ActionInventoryViewController else {return}
                    vc.documentId = documentId
                    vc.dataDetailSheets = response.data
                    vc.dataHistory = response.data?.docHistories ?? []
                    vc.arrayData = response.data?.docComponentABEs ?? []
                    vc.titleNav = response.data?.docCode ?? ""
                    self.navigationController?.pushViewController(vc, animated: true)
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.getDetailSheetsMonitor(inventoryId: inventoryId, accountId: accountId, documentId: documentId, actionType: actionType)
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.listDataFilter[indexPath.row].status == 2 {
            self.showAlertNoti(title: "Lỗi".localized(), message: "Phiếu này chưa được thực hiện kiểm kê. Vui lòng thử lại".localized(), acceptButton: "Đồng ý".localized())
        } else if self.listDataFilter[indexPath.row].status == 3 || self.listDataFilter[indexPath.row].status == 4 {
            self.showAlertNoti(title: "Lỗi".localized(), message: "Phiếu này chưa được thực hiện xác nhận kiểm kê. Vui lòng thử lại".localized(), acceptButton: "Đồng ý".localized())
        } else {
            getDetailSheetsMonitor(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", documentId: listDataFilter[indexPath.row].id ?? "", actionType: 2)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listDataFilter.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.monitoringSheetsCell, for: indexPath) else {return UITableViewCell()}
        cell.setDataToCell(status: listDataFilter[indexPath.row].status ?? 0, model: listDataFilter[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }
}
