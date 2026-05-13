//
//  FilterTicketViewController.swift
//  BIVN
//
//  Created by Luyện Đào on 24/11/2023.
//

import UIKit
import DropDown
import Moya
import Localize_Swift

class FilterTicketViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var titleSearchNameLabel: UILabel!
    @IBOutlet weak var contentFilterView: UIView!
    @IBOutlet weak var stageTextField: UITextField!
    @IBOutlet weak var sttTextField: UITextField!
    @IBOutlet weak var filtterButton: UIButton!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var machineLabel: UILabel!
    @IBOutlet weak var lineLabel: UILabel!
    @IBOutlet weak var noDataLabel: UILabel!
    @IBOutlet weak var inventoryTicketLabel: UILabel!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(R.nib.inventoryTableViewCell)
        }
    }
    
    var param = Dictionary<String, Any>()
    let networkManager: NetworkManager = NetworkManager()
    var listDataDoc: [DocCInfoModels] = []
    var listDataFilter: [DocCInfoModels] = []
    var listDataFilterSTT: [DocCInfoModels] = []
    let myDropDown = DropDown()
    var listDropdownStage: [String] = []
    var titleString: String?
    let viewcontroller = Storyboards.sheetPresentation.instantiate() as? SheetPresentationViewController
    var jobIndex : Int = 0
    var refreshScreen: Bool?
    var isAcpect: Bool = false
    var currentUserID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationPushFilter()
        setupView()
        addSearch()
        setupTableView()
        self.listDataFilter = listDataDoc
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setDisplay()
        currentUserID = UserDefault.shared.getUserID()
        if UserDefault.shared.getReload() {
            reloadStatus()
            UserDefault.shared.setReload(isReload: false)
        }
    }
    
    private func reloadStatus() {
        self.callAPI(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", modelCode: UserDefault.shared.getModel(), machineType: UserDefault.shared.getMachine(), lineName: UserDefault.shared.getLine())
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewcontroller?.onTapDissmiss()
    }
    
    private func setupUI() {
        if isAcpect {
            titleSearchNameLabel.text = "Đã xác nhận: ".localized()
        } else {
            titleSearchNameLabel.text = "Đã kiểm kê: ".localized()
        }
    }
    
    private func setupView() {
        contentFilterView.addBottomShadow()
    }
    
    func setDisplay() {
        if let titleString = titleString {
            title = titleString
        }
    }
    
    private func addSearch() {
        sttTextField.delegate = self
        stageTextField.delegate = self
        filtterButton.setTitle("", for: .normal)
        modelLabel.text = "_"
        machineLabel.text = "_"
        lineLabel.text = "_"
        noDataLabel.text = "Không có dữ liệu".localized()
        noDataLabel.isHidden = true
    }
    
    private func callAPI(inventoryId: String?, accountId: String?, modelCode: String?, machineType: String?, lineName: String?) {
        param["inventoryId"] = inventoryId ?? ""
        param["accountId"] = accountId ?? ""
        param["machineModel"] = modelCode ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineName ?? ""
        param["actionType"] = 0
        networkManager.getListdocC(param: param) {[weak self] data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self?.listDataDoc = response.data?.docCInfoModels ?? []
                    self?.listDataFilter = response.data?.docCInfoModels ?? []
                    self?.listDataFilter = self?.listDataFilter ?? []
                    var finishCount = response.data?.finishCount
                    if self?.isAcpect == true {
                        finishCount = response.data?.docCInfoModels?.filter({$0.status == 5}).count
                    }
                    self?.inventoryTicketLabel.text = "\(finishCount ?? 0)/\(response.data?.totalCount ?? 0)"
                    if self?.refreshScreen ?? false {
                        UserDefault.shared.removeModel()
                        UserDefault.shared.removeMachine()
                        UserDefault.shared.removeLine()
                    }
                    self?.tableView.reloadData()
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self?.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.callAPI(inventoryId: inventoryId, accountId: accountId, modelCode: modelCode, machineType: machineType, lineName: lineName)
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
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func filterTypeOfStep(text: String?) {
        listDataFilterSTT = []
        guard let text = text?.lowercased() else {return}
        if text == "" {
            listDataFilter = listDataDoc
        } else {
            listDataFilter = listDataDoc.filter { (data: DocCInfoModels) in
                if let name = data.stageName?.lowercased() {
                    if name.range(of: text) != nil {
                        return true
                    }
                }
                return false
            }
        }
        if listDataFilter.count == 0 {
            tableView.isHidden = true
            noDataLabel.isHidden = false
        } else {
            tableView.isHidden = false
            noDataLabel.isHidden = true
        }
        tableView.reloadData()
    }
    
    private func filterSTT(text: String?) {
        guard let text = text?.lowercased() else {return}
        if text == "" {
            listDataFilterSTT = listDataFilter
        } else {
            listDataFilterSTT = listDataFilter.filter { (data: DocCInfoModels) in
                if let name = data.stageNumber?.lowercased() {
                    if name.range(of: text) != nil {
                        return true
                    }
                }
                return false
            }
        }
        if listDataFilterSTT.count == 0 {
            tableView.isHidden = true
            noDataLabel.isHidden = false
        } else {
            tableView.isHidden = false
            noDataLabel.isHidden = true
        }
        tableView.reloadData()
    }
    
    private func navigationPushFilter() {
        if let vc = self.viewcontroller {
            if #available(iOS 15.0, *) {
                if let sheet = vc.sheetPresentationController{
                    sheet.detents = [.medium(), .large()] // Sheet style
                    sheet.prefersScrollingExpandsWhenScrolledToEdge = false // Inside Scrolling
                    sheet.prefersGrabberVisible = true // Grabber button
                    sheet.preferredCornerRadius = 24 // Radius
                    sheet.largestUndimmedDetentIdentifier = .medium //Avoid dismiss
                }
            }
            viewcontroller?.onTapPopup = true
            vc.passDataFilter = { [weak self] model, machine, line in
                guard let self = self else {return}
                self.callAPI(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", modelCode: model, machineType: machine, lineName: line)
                self.modelLabel.text = model
                self.machineLabel.text = machine
                self.lineLabel.text = line
                self.noDataLabel.isHidden = true
                self.tableView.isHidden = false
                self.sttTextField.isUserInteractionEnabled = true
                self.stageTextField.isUserInteractionEnabled = true
                UserDefault.shared.setModel(model: model ?? "")
                UserDefault.shared.setMachine(machine: machine ?? "")
                UserDefault.shared.setLine(line: line ?? "")
            }
            vc.onTapClose = {
                if self.listDataFilter.count == 0 {
                    self.noDataLabel.text = "Không có dữ liệu".localized()
                    self.noDataLabel.isHidden = false
                    self.tableView.isHidden = true
                    self.sttTextField.isUserInteractionEnabled = false
                    self.stageTextField.isUserInteractionEnabled = false
                }
            }
            self.navigationController?.present(vc, animated: true)
        }
    }
    
    @IBAction func onTapFilterAction(_ sender: UIButton) {
        if !viewcontroller!.onTapPopup {
            navigationPushFilter()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listDataFilterSTT.count > 0 ? listDataFilterSTT.count : listDataFilter.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.inventoryTableViewCell, for: indexPath) else {return UITableViewCell()}
        if listDataFilterSTT.count > 0 {
            cell.fillData(model: listDataFilterSTT[indexPath.row])
        } else {
            cell.fillData(model: listDataFilter[indexPath.row])
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if jobIndex == 0 {
            if listDataFilter[indexPath.row].confirmedBy == currentUserID {
                guard let vc = Storyboards.waitConfirmationC.instantiate() as? WaitConfirmationViewController else {return}
                vc.isBackThreeSeconds = false
                vc.documentId = self.listDataFilter[indexPath.row].id ?? ""
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                guard let vc = storyboard?.instantiateViewController(withIdentifier: R.storyboard.ticketC.ballotCountViewController) else {return}
                title = ""
                vc.documentId = self.listDataFilter[indexPath.row].id
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            if self.listDataFilter[indexPath.row].status ?? 0 > 2 {
                if listDataFilter[indexPath.row].inventoryBy == currentUserID {
                    guard let vc = Storyboards.waitConfirmationC.instantiate() as? WaitConfirmationViewController else {return}
                    vc.isBackThreeSeconds = false
                    vc.documentId = self.listDataFilter[indexPath.row].id ?? ""
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let vc = Storyboards.AccepticketC.instantiate() as! AccepticketCController
                    title = ""
                    vc.documentId = self.listDataFilter[indexPath.row].id
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                self.showAlertError(title: "Lỗi".localized(), message: "Công đoạn này chưa được thực hiện kiểm kê. Vui lòng thử lại".localized(), titleButton: "Đồng ý".localized())
            }
        }
    }
}

extension FilterTicketViewController {
    //MARK: UITextField Delegate
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField == stageTextField {
            filterTypeOfStep(text: stageTextField.text)
            if listDataFilterSTT.count == 0 {
                sttTextField.text = ""
            }
        }
        if textField == sttTextField {
            filterSTT(text: sttTextField.text)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == sttTextField {
            guard let text = sttTextField.text else { return true }
            let newLength = text.count + string.count - range.length
            return newLength < 4
        } else {
            guard let text = stageTextField.text else { return true }
            let newLength = text.count + string.count - range.length
            return newLength < 21
        }
        
    }
}
