//
//  DetailTicketCController.swift
//  BIVN
//
//  Created by TVO_M1 on 9/1/25.
//

import Foundation
import UIKit
import DropDown
import Moya

enum TypeCell {
    case TitleInventoryCell
    case RowInventoryTableViewCell
    case TotalItemTableViewCell
    case TitleDetailTableViewCell
    case ContentSheetTBCell
    case ItemTicketCCell
    case PageTBCell
    case TitleHistoryCell
    case HistoryInventoryCell
    static let all = [TitleInventoryCell, RowInventoryTableViewCell, TotalItemTableViewCell, TitleDetailTableViewCell, ContentSheetTBCell, ItemTicketCCell, PageTBCell, TitleHistoryCell, HistoryInventoryCell]
}

class DetailTicketCController : BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var lblCodeLabel: UILabel!
    @IBOutlet weak var lblNameLabel: UILabel!
    @IBOutlet weak var lblPositionLabel: UILabel!
    @IBOutlet weak var lblStatusLabel: UILabel!
    @IBOutlet weak var lblCodeValue: UILabel!
    @IBOutlet weak var lblNameValue: UILabel!
    @IBOutlet weak var lblPositionValue: UILabel!
    @IBOutlet weak var lblStatusValue: UILabel!
    @IBOutlet weak var lblEmpty: UILabel!
    @IBOutlet weak var btnContinue: UIButton!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var tableView: UITableView!{
        didSet {
            tableView.register(R.nib.titleInventoryCell)
            tableView.register(R.nib.rowInventoryTableViewCell)
            tableView.register(R.nib.totalItemTableViewCell)
            tableView.register(R.nib.titleDetailTableViewCell)
            tableView.register(R.nib.contentSheetTBCell)
            tableView.register(R.nib.itemTicketCTableCell)
            tableView.register(R.nib.pageTBCell)
            tableView.register(R.nib.titleHistoryCell)
            tableView.register(R.nib.historyInventoryCell)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        self.param["isErrorInvestigation"] = "true"
        getDataDetail(params: self.param)
    }
    
    let networkManager = NetworkManager()
    var documentId: String = ""
    var documentName: String = ""
    var titleTicketName: String = ""
    var defaultSum: Double = 0
    var accessoryModel : AccessoryModels?
    var currentTotalValueSum: Double = 0
    var isShowPage: Bool = false
    var dataInfo : ResultData?
    var titleTicket : String?
    private var arrayData: [DocComponentABEs] = []
    var documentInfo: ResultErrorModel?
    private var regionUS: Bool = false
    var pageSize = 1
    private var resultValueSum: Double = 0
    var totalPage: Int = 0
    var param = Dictionary<String, Any>()
    let myDropDown = DropDown()
    var listArray: [Int] = []
    
    func setUpUI(){
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationItem.title = titleTicket
        regionUS = numberFormatter.locale.identifier == "en_US"
        
        lblCodeLabel.text = "Mã linh kiện:".localized()
        lblNameLabel.text = "Tên linh kiện:".localized()
        lblPositionLabel.text = "Vị trí:".localized()
        lblStatusLabel.text = "Trạng thái:".localized()
        lblEmpty.text = "Không có dữ liệu".localized()
        lblEmpty.isHidden = true
        
        lblCodeValue.text = documentInfo?.componentCode
        lblNameValue.text = documentInfo?.componentCode
        lblPositionValue.text = documentInfo?.positionCode
        
        if let status = StatusDisplayError(rawValue: Int(documentInfo?.status ?? 0)) {
            lblStatusValue.text = status.displayName
            lblStatusValue.textColor = status.color
        }
        
        lblCodeLabel.font = fontUtils.size14.regular
        lblNameLabel.font = fontUtils.size14.regular
        lblPositionLabel.font = fontUtils.size14.regular
        lblStatusLabel.font = fontUtils.size14.regular
        lblCodeValue.font = fontUtils.size24.bold
        lblNameValue.font = fontUtils.size14.medium
        lblPositionValue.font = fontUtils.size14.medium
        lblStatusValue.font = fontUtils.size12.medium
        
        lblCodeValue.textColor = UIColor(named: R.color.textDarkBlue.name)
        lblStatusValue.textColor = UIColor(named: R.color.greenColor.name)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        
        btnContinue.setTitle("Tiếp tục".localized(), for: .normal)
        btnBack.setTitle("Quay lại".localized(), for: .normal)
        
    }
    
    func setTitle(title: String){
        lblNameValue.text = title
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return TypeCell.all.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TypeCell.all[section] {
        case .TitleInventoryCell, .TotalItemTableViewCell, .TitleDetailTableViewCell, .ContentSheetTBCell, .PageTBCell, .TitleHistoryCell:
            return 1
        case .RowInventoryTableViewCell:
            return dataInfo?.docComponentABEs?.count ?? 0
        case .ItemTicketCCell:
            return (dataInfo?.docComponentCs?.count ?? -1)
        case .HistoryInventoryCell:
            return dataInfo?.docHistories?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch TypeCell.all[indexPath.section] {
        case .TitleInventoryCell, .RowInventoryTableViewCell, .TotalItemTableViewCell, .ContentSheetTBCell, .ItemTicketCCell, .TitleDetailTableViewCell:
            return 60
        case .PageTBCell:
            return 40
        default:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch TypeCell.all[indexPath.section] {
        case .TitleInventoryCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.numberOfBoxLabel.text = "Số lượng".localized()
            cell.qualityPerBoxLabel.text = "Thiết bị".localized()
            cell.selectionStyle = .none
            return cell
        case .RowInventoryTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.rowInventoryTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            var totalValue = 0.0
            if !(dataInfo?.docComponentABEs?.isEmpty ?? false) {
                for item in dataInfo?.docComponentABEs  ?? []{
                    let result = item.quantityPerBom ?? 0
                    let result2 = item.quantityOfBom ?? 0
                    totalValue = (result * result2) + totalValue
                }
                self.resultValueSum = totalValue
            }
            cell.setDataToCell(data: dataInfo?.docComponentABEs?[indexPath.row] ?? DocComponentABEs(), index: indexPath.row, isLast: ((dataInfo?.docComponentABEs?.count ?? 0) - 1) == indexPath.row ? true : false, isCheck: false, isHideTextField: false)
            return cell
        case .TotalItemTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.totalItemTableViewCell, for: indexPath) else {return UITableViewCell()}
            var totalValue = 0.0
            if !(dataInfo?.docComponentABEs?.isEmpty ?? true) {
                for item in self.dataInfo?.docComponentABEs ?? [] {
                    let result = (item.quantityPerBom ?? 0) * (item.quantityOfBom ?? 0)
                    totalValue += result
                }
            }
            
            cell.setDataToCell(totalValue: totalValue)
            cell.selectionStyle = .none
            return cell
        case .ContentSheetTBCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.contentSheetTBCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.containerView.backgroundColor = UIColor(named: indexPath.row == 0 ? R.color.grey1.name : R.color.white.name)
            return cell
        case .ItemTicketCCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.itemTicketCTableCell, for: indexPath)else {return UITableViewCell()}
            cell.selectionStyle = .none
            if self.dataInfo?.docComponentCs?.count == 0 {
                cell.emptyDataLabel.isHidden = false
                cell.containerView.isHidden = true
                cell.emptyDataLabel.text = "Không có dữ liệu".localized()
            } else {
                cell.emptyDataLabel.isHidden = true
                cell.containerView.isHidden = false
                cell.dataTest = dataInfo?.docComponentCs?[indexPath.row]
                cell.sttLabel.text = "\((pageSize - 1) * 10 + (indexPath.row + 1))"
                cell.fillDataQuality()
                cell.regionUS = self.regionUS
            }
            cell.selectionStyle = .none
            return cell
        case .PageTBCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.pageTBCell, for: indexPath) else {return UITableViewCell()}
            if self.pageSize >= totalPage {
                cell.isCheckNext = false
                cell.rightButton.isEnabled = false
                cell.rightButton.alpha = 0.2
            } else {
                cell.isCheckNext = true
                cell.rightButton.isEnabled = true
                cell.rightButton.alpha = 1
            }
            if self.pageSize <= 1 {
                cell.isCheckPrevious = false
                cell.leftButton.isEnabled = false
                cell.leftButton.alpha = 0.2
            } else {
                cell.isCheckPrevious = true
                cell.leftButton.isEnabled = true
                cell.leftButton.alpha = 1
            }
            cell.rightPage = {
                self.pageSize += 1
                self.param["page"] = self.pageSize
                self.getDataDetail(params: self.param, index: indexPath.row)
            }
            cell.leftPage = {
                self.pageSize -= 1
                self.param["page"] = self.pageSize
                self.getDataDetail(params: self.param, index: indexPath.row)
            }
            cell.textPageLabel.text = "of \(totalPage) pages"
            cell.onTapShowDropDown = { value, button in
                self.showDropdown(text: value, size: button)
            }
            cell.numberPageLabel.text = "\(self.pageSize)"
            cell.selectionStyle = .none
            return cell
        case .TitleDetailTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleDetailTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            return cell
        case .TitleHistoryCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleHistoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setTitleHistory()
            return cell
        case .HistoryInventoryCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.historyInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.fillDataDocC(data: dataInfo?.docHistories?[indexPath.row] ?? DocHistory())
            cell.containerView.addTapGestureRecognizer(action: {
                guard let vc = Storyboards.detailHistoryTicketC.instantiate() as? HistoryDetailDocCViewController else {return}
                vc.historyId = self.dataInfo?.docHistories?[indexPath.row].id
                vc.titleInfo = self.titleTicketName
                vc.titleString = self.dataInfo?.docHistories?[indexPath.row].createdAt?.formatDateWithInputAndOutputType(inputFormat: TypeFormatDate.ServerFormat.rawValue, outputFormat: TypeFormatDate.DD_MM_YYYY_HH_mm.rawValue)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            cell.selectionStyle = .none
            return cell
        }
    }
    
    private func showDropdown(text: UILabel, size: UIButton) {
        myDropDown.dataSource = self.listArray.map { $0.description }
        myDropDown.anchorView = size
        myDropDown.bottomOffset = CGPoint(x: 0, y: (text.frame.size.height))
        myDropDown.topOffset = CGPoint(x: 0, y: -(myDropDown.anchorView?.plainView.bounds.height)!)
        myDropDown.dismissMode = .onTap
        myDropDown.direction = .bottom
        myDropDown.selectionAction = { (index: Int, item: String) in
            text.text = "\(self.listArray[index])"
            text.textColor = .black
            self.pageSize = index + 1
            self.param["page"] = self.pageSize
            self.getDataDetail(params: self.param)
        }
        myDropDown.show()
    }
    
    func getDataDetail(params: Dictionary<String, Any>, index: Int = 0){
        if(documentId.isEmpty == true){ return } else {
            self.startLoading()
            networkManager.getListParCode(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", documentId: documentId, actionId: "1", param: params, completion: {data in
                self.stopLoading()
                switch data{
                case .success(let response):
                    if response.code == 200 {
                        self.listArray = []
                        self.dataInfo = response.data
                        self.lblEmpty.isHidden = (response.data?.docComponentCs?.count ?? 0) > 0 ? true : false
                        let titleTicketName = "\(response.data?.machineModel ?? "") - \(response.data?.machineType ?? "") - \(response.data?.lineName ?? "") - \(response.data?.stageName ?? "")"
                        if response.data?.docComponentCs?.count ?? 0 >= 10 {
                            self.isShowPage = true
                        }
                        self.setTitle(title: titleTicketName)
                        self.totalPage = response.data?.docCTotalPages ?? 0
                        if self.totalPage != 0 {
                            for i in 1...self.totalPage {
                                self.listArray.append(i)
                            }
                        }
                        
                        self.tableView.reloadData()
                    } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                        self.showAlertExpiredToken(code: response.code) { [weak self] result in
                            guard let self = self else { return }
                            if result {
                                self.getDataDetail(params: params, index: index)
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
            )}
    }
    
    @IBAction func onBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    @IBAction func onContinue(_ sender: Any) {
        guard let vc = Storyboards.errorCorrection.instantiate() as? ErrorCorrectionViewController else {return}
        vc.componentCode = documentInfo?.componentCode ?? ""
        vc.accessoryModel = self.accessoryModel
        vc.titleString = "Điều chỉnh sai số".localized()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
