//
//  AccepticketCController.swift
//  BIVN
//

import UIKit
import DropDown
import AVFoundation
import Moya
import Localize_Swift

enum Accepticket {
    case InfoTicket
    case TitleInventoryCell
    case RowInventoryTableViewCell
    case TotalItemTableViewCell
    case ErrorTableViewCell
    case SearchCodeTableViewCell
    case ContentSheetTBCell
    case PartCodeTableViewCell
    case PageTBCell
    case NoteViewCell
    case TitleHistoryCell
    case HistoryInventoryCell
    static let all = [InfoTicket, TitleInventoryCell, RowInventoryTableViewCell, TotalItemTableViewCell, ErrorTableViewCell, SearchCodeTableViewCell, ContentSheetTBCell, PartCodeTableViewCell, PageTBCell, NoteViewCell, TitleHistoryCell,  HistoryInventoryCell]
}


class AccepticketCController: BaseViewController, UITableViewDataSource, UITableViewDelegate, AddRowCell {
    
    private static let ACCEPT : Int = 1
    private static let DENIED : Int = 0
    private static let UPDATE : Int = 4
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(R.nib.infoTicketTableViewCell)
            tableView.register(R.nib.titleInventoryCell)
            tableView.register(R.nib.rowInventoryTableViewCell)
            tableView.register(R.nib.totalItemTableViewCell)
            tableView.register(R.nib.errorTableViewCell)
            tableView.register(R.nib.searchCodeTableViewCell)
            tableView.register(R.nib.contentSheetTBCell)
            tableView.register(R.nib.partCodeTableViewCell)
            tableView.register(R.nib.pageTBCell)
            tableView.register(R.nib.noteCell)
            tableView.register(R.nib.titleHistoryCell)
            tableView.register(R.nib.historyInventoryCell)
        }
    }
    @IBOutlet weak var uiViewAccept: UIStackView!
    @IBOutlet weak var uiViewUpdate: UIStackView!
    @IBOutlet weak var buttonAccept: UIButton!
    @IBOutlet weak var buttonDeined: UIButton!
    @IBOutlet weak var buttonUpdate: UIButton!
    
    private var accessoryBomModel: [AccessoryBomModel] = []
    private var arrayData: [DocComponentABEs] = []
    private var arrayData2: [ConvertDocComponentABEs] = []
    private var docCModelResult: [DocComponentCs] = []
    private var convertDocCModelResult: [ConvertDocComponentCs] = []
    private var resultValueSum: Double = 0
    var currentTotalValueSum: Double = 0
    var pageSize = 1
    let networkManager: NetworkManager = NetworkManager()
    var param = Dictionary<String, Any>()
    let myDropDown = DropDown()
    var listDocComponentCs: [DocComponentCs] = []
    var listDocHistories: [DocHistory] = []
    var totalPage: Int = 0
    var listDropdownPage: [String] = []
    var listArray: [Int] = []
    var quantityPerBom: String?
    var isCheck: Bool = false
    var documentId: String?
    var dataInfo : ResultData?
    var isHidenNote : Bool = true
    var idsDeleteDocOutPut : [String] = []
    var note : String = ""
    private var regionUS: Bool = false
    var titleString: String?
    var titleTicketName: String = ""
    var isShowPage: Bool = false
    var errorValid: Bool = false
    var hideError: Bool = false
    var isShowCheck : Bool = true
    var listDocComponentCsTick: [DocComponentCs] = []
    var countHightlight: Int = 0
    var defaultSum: Double = 0
    var isReloadDocABE: Bool = false
    var dError: Bool = true
    var index: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupUI()
        getAPIListPartCode(params: [:])
        self.hideKeyboardWhenTappedAround()
        let lockButton = UIButton(type: .system)
        lockButton.setImage(UIImage(named: R.image.icFilter.name), for: .normal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .done, target: self, action: #selector(backToInitial))
        buttonAccept.isMultipleTouchEnabled = false
        buttonDeined.isMultipleTouchEnabled = false
        buttonUpdate.isMultipleTouchEnabled = false
        
    }
    
    @objc func backToInitial() {
        showAlertNoti(title: "Xác nhận thoát".localized(), message: "Bạn có chắc chắn muốn thoát không? Nếu bạn thoát khi đã nhập dữ liệu thì dữ liệu đó sẽ không được lưu".localized(), cancelButton: "Không".localized(), acceptButton: "Có".localized(), acceptOnTap: {
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setDisplay()
    }
    
    func setDisplay() {
        regionUS = numberFormatter.locale.identifier == "en_US"
        if let titleString = titleString {
            title = titleString
        } else {
            title = self.dataInfo?.docCode
        }
        if let navigationBar = self.navigationController?.navigationBar {
            var navBarTitleTextAttributes = [NSAttributedString.Key: Any]()
            navBarTitleTextAttributes[.font] = fontUtils.size16.bold
            navBarTitleTextAttributes[.foregroundColor] = UIColor.black
            
            navigationBar.titleTextAttributes = navBarTitleTextAttributes
        }
    }
    
    private func fillDataTitleNavi() {
        self.navigationItem.title = dataInfo?.docCode
    }
    
    private func setupUI() {
        buttonDeined.setTitle("Từ chối".localized(), for: .normal)
        buttonAccept.setTitle("Xác nhận".localized(), for: .normal)
        let origImage = UIImage(named: R.image.ic_tick.name)
        let tintedImage = origImage?.withRenderingMode(.alwaysTemplate)
        self.buttonAccept.setImage(tintedImage, for: .normal)
        self.buttonAccept.tintColor = UIColor(named: R.color.textGray.name)
        self.enableButtionDenied(isEnable: false)
        switch self.dataInfo?.status {
        case 4, 5, 7:
            self.uiViewAccept.isHidden = true
            self.uiViewUpdate.isHidden = false
        default:
            self.uiViewAccept.isHidden = false
            self.uiViewUpdate.isHidden = true
        }
        
    }
    
    private func checkEnableUpdateAndAccept(){
        if self.countHightlight == 0 {
            if self.arrayData.contains(where: {$0.isCheck != true}) || self.arrayData.isEmpty {
                disableButtonAcceptAndUpdate()
            }
            else {
                enableButtonAcceptAndUpdate()
            }
        } else {
            if (self.arrayData.contains(where: {$0.isCheck != true}) || self.arrayData.isEmpty ) || self.listDocComponentCs.filter({$0.isTickCheckBox ?? false}).count != self.countHightlight {
                disableButtonAcceptAndUpdate()
            }
            else {
                enableButtonAcceptAndUpdate()
            }
        }
    }
    
    private func disableButtonAcceptAndUpdate(){
        self.buttonAccept.isEnabled = false
        self.buttonUpdate.isEnabled = false
        self.buttonAccept.backgroundColor = UIColor(named: R.color.tvColor.name)
        self.buttonUpdate.backgroundColor = UIColor(named: R.color.tvColor.name)
        self.buttonAccept.setTitleColor(UIColor(named: R.color.textGray.name), for: .normal)
        self.buttonUpdate.setTitleColor(UIColor(named: R.color.textGray.name), for: .normal)
        self.buttonAccept.tintColor = UIColor(named: R.color.textGray.name)
    }
    
    private func enableButtonAcceptAndUpdate(){
        self.buttonAccept.isEnabled = true
        self.buttonUpdate.isEnabled = true
        self.buttonAccept.backgroundColor = UIColor(named: R.color.greenColor.name)
        self.buttonUpdate.backgroundColor = UIColor(named: R.color.greenColor.name)
        self.buttonAccept.setTitleColor(UIColor(named: R.color.white.name), for: .normal)
        self.buttonUpdate.setTitleColor(UIColor(named: R.color.white.name), for: .normal)
        self.buttonAccept.tintColor = UIColor(named: R.color.white.name)
    }
    
    private func enableButtionDenied(isEnable: Bool){
        self.buttonDeined.setTitleColor(UIColor(named: isEnable ? R.color.textDefault.name: R.color.textGray.name), for: .normal)
        let icDenied = UIImage(named: R.image.ic_close_black.name)
        let tintedImageClose = icDenied?.withRenderingMode(.alwaysTemplate)
        self.buttonDeined.setImage(tintedImageClose, for: .normal)
        self.buttonDeined.tintColor =  UIColor(named:isEnable == true ? R.color.textDefault.name: R.color.textGray.name)
        self.buttonDeined.layer.backgroundColor = UIColor(named:isEnable == true ? R.color.grey2.name : R.color.grey1.name)?.cgColor
        self.buttonDeined.isUserInteractionEnabled = isEnable
    }
    
    private func getAPIListPartCode(params: Dictionary<String, Any>, index: Int = 0) {
        self.index = index
        guard let documentId = self.documentId else {return}
        self.startLoading()
        networkManager.getListParCode(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", documentId: documentId, actionId: "1", param: params, completion: { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.stopLoading()
                    self.listArray = []
                    self.defaultSum = 0
                    self.setDisplay()
                    self.currentTotalValueSum = 0
                    self.titleTicketName = "\(response.data?.machineModel ?? "") - \(response.data?.machineType ?? "") - \(response.data?.lineName ?? "") - \(response.data?.stageName ?? "")"
                    self.listDocComponentCs = []
                    self.listDocComponentCs = response.data?.docComponentCs ?? []
                    self.countHightlight = self.listDocComponentCs.filter({$0.isHighLight ?? false}).count
                    if response.data?.docComponentCs?.count ?? 0 >= 10 {
                        self.isShowPage = true
                    }
                    self.titleTicketName = "\(response.data?.machineModel ?? "") - \(response.data?.machineType ?? "") - \(response.data?.lineName ?? "") - \(response.data?.stageName ?? "")"
                    self.listDocHistories = response.data?.docHistories ?? []
                    self.listDocHistories.sort(by: {$0.getCreateDate().compare($1.getCreateDate()) == .orderedDescending})
                    self.dataInfo = response.data
                    self.fillDataTitleNavi()
                    
                    if !self.isCheck {
                        if response.data?.docComponentABEs?.count ?? 0 > 0 {
                            if !self.isReloadDocABE {
                                self.arrayData = response.data?.docComponentABEs ?? []
                                self.isReloadDocABE = true
                            }
                        } else {
                            self.arrayData = [DocComponentABEs(id: "", quantityOfBom: nil, quantityPerBom: nil),
                                              DocComponentABEs(id: "", quantityOfBom: nil, quantityPerBom: nil)]
                        }
                    }
                    
                    if let docABE = response.data?.docComponentABEs {
                        for item in docABE {
                            self.defaultSum += (item.quantityOfBom ?? 0) * (item.quantityPerBom ?? 0)
                        }
                    }
                    
                    for item in self.arrayData {
                        var convertABE = ConvertDocComponentABEs()
                        convertABE.id = item.id
                        convertABE.inventoryId = item.inventoryId
                        convertABE.inventoryDocId = item.inventoryDocId
                        convertABE.quantityPerBom = item.quantityPerBom
                        convertABE.quantityOfBom = item.quantityOfBom
                        self.arrayData2.append(convertABE)
                        self.currentTotalValueSum += (item.quantityPerBom ?? 0) * (item.quantityOfBom ?? 0)
                    }
                    for (index, item) in self.docCModelResult.enumerated() {
                        for (index2, item2) in self.listDocComponentCs.enumerated() {
                            if item.id == item2.id {
                                self.listDocComponentCs[index2].quantityPerBom = self.docCModelResult[index].quantityPerBom
                                self.listDocComponentCs[index2].quantityOfBom = self.docCModelResult[index].quantityOfBom
                                self.listDocComponentCs[index2].componentCode = self.docCModelResult[index].componentCode
                                self.listDocComponentCs[index2].isHighLight = self.docCModelResult[index].isHighLight
                                self.listDocComponentCs[index2].isHighLightLocal = self.docCModelResult[index].isHighLightLocal
                                self.listDocComponentCs[index2].isCheck = self.docCModelResult[index].isCheck
                            }
                        }
                    }
                    for (index, item) in self.listDocComponentCsTick.enumerated() {
                        for (index2, item2) in self.listDocComponentCs.enumerated() {
                            if item.id == item2.id {
                                self.listDocComponentCs[index2].quantityPerBom = self.listDocComponentCsTick[index].quantityPerBom
                                self.listDocComponentCs[index2].quantityOfBom = self.listDocComponentCsTick[index].quantityOfBom
                                self.listDocComponentCs[index2].componentCode = self.listDocComponentCsTick[index].componentCode
                                self.listDocComponentCs[index2].isHighLight = self.listDocComponentCsTick[index].isHighLight
                                self.listDocComponentCs[index2].isCheck = self.listDocComponentCsTick[index].isCheck
                                self.listDocComponentCs[index2].isHighLightLocal = self.listDocComponentCsTick[index].isHighLightLocal
                                self.listDocComponentCs[index2].isTickCheckBox = self.listDocComponentCsTick[index].isTickCheckBox
                            }
                        }
                    }
                    if self.pageSize == 1 {
                        self.convertDocCModelResult = []
                        if let listDocCs = response.data?.docComponentCs{
                            for item in listDocCs {
                                let convertC = ConvertDocComponentCs()
                                convertC.id = item.id
                                convertC.quantityPerBom = item.quantityPerBom
                                convertC.quantityOfBom = item.quantityOfBom
                                convertC.componentCode = item.componentCode
                                convertC.modelCode = item.modelCode
                                self.convertDocCModelResult.append(convertC)
                            }
                        }
                        
                    }
                    self.totalPage = response.data?.docCTotalPages ?? 0
                    if self.totalPage != 0 {
                        for i in 1...self.totalPage {
                            self.listArray.append(i)
                        }
                    }
                    self.tableView.reloadData()
                    self.setupUI()
                    self.getTickCheckAPI()
                    if self.tableView.numberOfRows(inSection: 0) != 0 {
                        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                    }
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.getAPIListPartCode(params: params, index: self.index)
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
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return EnumBallotCount.all.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch Accepticket.all[indexPath.section] {
        case .TitleInventoryCell, .RowInventoryTableViewCell, .TotalItemTableViewCell, .ContentSheetTBCell, .PartCodeTableViewCell:
            return 60
        case .PageTBCell:
            return 40
        case .NoteViewCell: return self.isHidenNote ? UITableView.automaticDimension : 150
        default:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Accepticket.all[section] {
        case .ErrorTableViewCell:
            return !errorValid ? 0 : 1
        case .TitleInventoryCell, .TotalItemTableViewCell:
            return 1
        case .RowInventoryTableViewCell:
            return arrayData.count
        case .PartCodeTableViewCell:
            return listDocComponentCs.count == 0 ? 1: listDocComponentCs.count
        case .PageTBCell:
            return isShowPage ? 1 : 0
        case .TitleHistoryCell:
            return listDocHistories.count > 0 ? 1 : 0
        case .HistoryInventoryCell:
            return listDocHistories.count == 0 ? 0 : listDocHistories.count
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch Accepticket.all[section] {
        case .TotalItemTableViewCell, .TitleInventoryCell, .RowInventoryTableViewCell, .PartCodeTableViewCell, .ContentSheetTBCell:
            return 0
        default:
            return 5
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0))
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Accepticket.all[indexPath.section] {
        case .InfoTicket:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.infoTicketTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.delegateAddRow = self
            cell.fillData(model: dataInfo)
            cell.selectionStyle = .none
            return cell
        case .TitleInventoryCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            return cell
        case .RowInventoryTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.rowInventoryTableViewCell, for: indexPath) else {return UITableViewCell()}
            var totalValue = 0.0
            cell.isShowCheck = true
            cell.setDataToCell(data: arrayData[indexPath.row], index: indexPath.row, isLast: (arrayData.count - 1) == indexPath.row ? true : false, isCheck: arrayData[indexPath.row].isCheck ?? false)
            if !self.arrayData.isEmpty {
                for item in self.arrayData {
                    let result = item.quantityPerBom ?? 0
                    let result2 = item.quantityOfBom ?? 0
                    totalValue = (result * result2) + totalValue
                }
                self.resultValueSum = totalValue
            }
            cell.checkboxOnclick = {(isCheck, index) in
                self.arrayData[index].isCheck = isCheck
                self.tableView.reloadSections([indexPath.section], with: .none)
                self.checkEnableUpdateAndAccept()
            }
            
            cell.deleteRow = { (index) in
                if self.arrayData[index].id != "" && self.arrayData[index].id != nil {
                    self.idsDeleteDocOutPut.append(self.arrayData[index].id ?? "")
                }
                self.arrayData.remove(at: index)
                for item2 in self.listDocComponentCs {
                    item2.isHighLight = false
                    item2.isHighLightLocal = false
                    item2.isCheck = false
                }
                self.docCModelResult = []
                self.errorValid = false
                self.tableView.reloadData()
                self.countHightlight = 0
                self.checkEnableUpdateAndAccept()
            }
            cell.sumTotal = { (index, soluong, sothung) in
                for item in self.listDocComponentCs {
                    item.isCheck = false
                    item.isHighLight = false
                    self.docCModelResult.removeAll()
                }
                totalValue = 0
                self.arrayData[index].quantityOfBom = sothung == "" ? nil : self.unFormatNumber(stringValue: sothung, regionUS: self.regionUS)
                self.arrayData[index].quantityPerBom = soluong == "" ? nil : self.unFormatNumber(stringValue: soluong, regionUS: self.regionUS)
                for item in self.arrayData {
                    if let quantityOfBom = item.quantityOfBom, let quantityPerBom = item.quantityPerBom {
                        totalValue = (quantityOfBom * quantityPerBom) + totalValue
                    }
                }
                if self.defaultSum != totalValue {
                    for item in self.listDocComponentCs {
                        item.isHighLightLocal = false
                    }
                }
                self.resultValueSum = totalValue
                self.tableView.beginUpdates()
                self.tableView.reloadSections([indexPath.section + 1, indexPath.section + 5], with: .none)
                self.tableView.endUpdates()
                self.hideError = self.arrayData.contains(where: { $0.quantityOfBom == nil || $0.quantityPerBom == nil })
                if !self.hideError {
                    self.errorValid = false
                    tableView.reloadSections([4], with: .none)
                }
                self.countHightlight = 0
                self.checkEnableUpdateAndAccept()
                
            }
            cell.selectionStyle = .none
            return cell
        case .TotalItemTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.totalItemTableViewCell, for: indexPath) else {return UITableViewCell()}
            if arrayData.count == 0 {
                self.resultValueSum = 0
            }
            cell.setDataToCell(totalValue: resultValueSum)
            cell.selectionStyle = .none
            return cell
        case .SearchCodeTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.searchCodeTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.onTapSearch = { data in
                self.param["searchTerm"] = data
                self.getAPIListPartCode(params: self.param)
            }
            cell.selectionStyle = .none
            return cell
        case .ContentSheetTBCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.contentSheetTBCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            return cell
        case .PartCodeTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.partCodeTableViewCell, for: indexPath) else {return UITableViewCell()}
            if self.listDocComponentCs.count == 0 {
                cell.emptyDataLabel.isHidden = false
                cell.containerView.isHidden = true
                cell.emptyDataLabel.text = "Không có dữ liệu".localized()
            } else {
                cell.emptyDataLabel.isHidden = true
                cell.containerView.isHidden = false
                cell.dataTest = listDocComponentCs[indexPath.row]
                cell.valueSum = self.resultValueSum
                cell.isShowCheck =  self.listDocComponentCs[indexPath.row].isHighLight ?? false
                cell.sttLabel.text = "\((pageSize - 1) * 10 + (indexPath.row + 1))"
                cell.fillDataQuality(valueSum: resultValueSum, quantityOfBom: listDocComponentCs[indexPath.row].quantityOfBom ?? 0, index: indexPath.row, isHighLight: listDocComponentCs[indexPath.row].isHighLight ?? false, isCheck: listDocComponentCs[indexPath.row].isCheck ?? false, isHightlightLocal: listDocComponentCs[indexPath.row].isHighLightLocal ?? false, isTickCheckBox: listDocComponentCs[indexPath.row].isTickCheckBox ?? false, defaultSum: self.defaultSum)
                cell.regionUS = self.regionUS
                cell.sumTotal = { index, text, keyboard in
                    let resultTotal = self.resultValueSum * (self.listDocComponentCs[index].quantityOfBom ?? 0)
                    self.listDocComponentCs[index].isCheck = true
                    self.listDocComponentCs[index].quantityPerBom = self.unFormatNumber(stringValue: text, regionUS: self.regionUS) > resultTotal ? resultTotal : self.unFormatNumber(stringValue: text, regionUS: self.regionUS)
                    self.isShowCheck = self.unFormatNumber(stringValue: text, regionUS: self.regionUS) >= resultTotal ? true : false
                    self.listDocComponentCs[index].isHighLightLocal =  self.unFormatNumber(stringValue: text, regionUS: self.regionUS) >= resultTotal ? false : true
                    self.tableView.reloadRows(at: [IndexPath(row: index, section: indexPath.section)], with: .automatic)
                }
                cell.passDataClosure = { data1, isCheck in
                    if isCheck {
                        self.docCModelResult.append(data1)
                    } else {
                        self.docCModelResult.removeAll(where: { $0.id == data1.id })
                    }
                }
            }
            cell.selectionStyle = .none
            cell.isShowCheck = true
            cell.checkboxOnclick = {isTick, index in
                self.listDocComponentCs[index].isTickCheckBox = isTick
                if isTick {
                    self.listDocComponentCsTick.append( self.listDocComponentCs[index])
                    if self.listDocComponentCs.filter({$0.isTickCheckBox ?? false}).count == self.countHightlight && !self.arrayData.contains(where: {$0.isCheck != true}){
                        self.getTickCheckAPI()
                    }
                    
                } else {
                    self.listDocComponentCsTick.removeAll(where: {$0.id == self.listDocComponentCs[index].id})
                    self.disableButtonAcceptAndUpdate()
                }
                self.tableView.reloadData()
                
            }
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
                self.listDocComponentCs = []
                self.isCheck = true
                self.pageSize += 1
                self.param["page"] = self.pageSize
                self.getAPIListPartCode(params: self.param, index: indexPath.row)
            }
            cell.leftPage = {
                self.listDocComponentCs = []
                self.isCheck = true
                self.pageSize -= 1
                self.param["page"] = self.pageSize
                self.getAPIListPartCode(params: self.param, index: indexPath.row)
            }
            cell.textPageLabel.text = "of \(totalPage) pages"
            cell.onTapShowDropDown = { value, button in
                self.showDropdown(text: value, size: button)
            }
            cell.numberPageLabel.text = "\(self.pageSize)"
            cell.selectionStyle = .none
            return cell
            
        case .NoteViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.noteCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.isHiddenAddButton = false
            cell.setDataToView()
            cell.hiddenReason = { (hiddenReason) in
                self.isHidenNote = hiddenReason
                UIView.performWithoutAnimation {
                    tableView.reloadSections([indexPath.row], with: .none)
                }
                
            }
            cell.callBackListener = {note in
                self.note = note
                self.enableButtionDenied(isEnable: !note.isEmpty)
            }
            return cell
        case .TitleHistoryCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleHistoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setTitleHistory()
            return cell
        case .HistoryInventoryCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.historyInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.fillDataDocC(data: listDocHistories[indexPath.row])
            cell.containerView.addTapGestureRecognizer(action: {
                guard let vc = Storyboards.detailHistoryTicketC.instantiate() as? HistoryDetailDocCViewController else {return}
                vc.historyId = self.listDocHistories[indexPath.row].id
                vc.titleInfo = self.titleTicketName
                vc.titleString = self.listDocHistories[indexPath.row].createdAt?.formatDateWithInputAndOutputType(inputFormat: TypeFormatDate.ServerFormat.rawValue, outputFormat: TypeFormatDate.DD_MM_YYYY_HH_mm.rawValue)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            cell.selectionStyle = .none
            return cell
        case .ErrorTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.errorTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            return cell
        }
    }
    
    private func checShowConfirmExits() -> Bool {
        return self.arrayData.contains(where: {$0.isCheck != false})
        
        
    }
    
    private func disableAllButton(){
        buttonAccept.isUserInteractionEnabled = false
        buttonDeined.isUserInteractionEnabled = false
        buttonUpdate.isUserInteractionEnabled = false
    }
    private func enableAllButton(){
        buttonAccept.isUserInteractionEnabled = true
        buttonDeined.isUserInteractionEnabled = true
        buttonUpdate.isUserInteractionEnabled = true
    }
    
    private func submitData(type: Int, docABEModel: [DocComponentABEs], docCModel : [DocComponentCs], deleteOutPut : [String], total: Double){
        
        let isCheckError1 = arrayData.contains(where: {$0.quantityPerBom != nil || $0.quantityOfBom != nil})
        
        if self.arrayData.count == 0 || !isCheckError1 {
            self.showAlertError(title: "Lỗi".localized(), message: "Không có dữ liệu.Vui lòng nhập dữ liệu Số lượng/thùng và Số thùng".localized(), titleButton: "Đồng ý".localized())
            self.enableAllButton()
            return
        }
        
        let isCheckError2 = arrayData.contains(where: {$0.quantityPerBom == nil && $0.quantityOfBom != nil})
        let isCheckError3 = arrayData.contains(where: {$0.quantityPerBom != nil && $0.quantityOfBom == nil})
        
        if isCheckError1 {
            if isCheckError2 || isCheckError3 {
                dError = true
            } else {
                dError = false
            }
        }
        self.disableAllButton()
        if (!dError && type == AccepticketCController.ACCEPT) || (type == AccepticketCController.DENIED) || (!dError && type == AccepticketCController.UPDATE) {
            submitTicketDocC(type: type, docABEModel: docABEModel, docCModel: docCModel, deleteOutPut: deleteOutPut, total: total)
        } else {
            self.enableAllButton()
            errorValid = true
            tableView.reloadSections([4], with: .none)
        }
    }
    
    func submitTicketDocC(type: Int, docABEModel: [DocComponentABEs], docCModel : [DocComponentCs], deleteOutPut : [String], total: Double) {
        guard let documentId = self.documentId else {return}
        networkManager.submitTicketCDoc(userCode: UserDefault.shared.getUserID(), comment: self.note, actionType: "\(type)", inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", documentId: documentId, containerModel: docABEModel, docTypeCModel: docCModel, image: Data(), isCheckPushImage: false, idsDeleteDocOutPut: deleteOutPut, completion: { data in
            self.enableAllButton()
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dataInfo?.status = response.data?.status
                    let vc = Storyboards.waitConfirmationC.instantiate() as! WaitConfirmationViewController
                    vc.arrayData = docABEModel
                    vc.valueSum = total
                    vc.listDocComponentCs = type == AccepticketCController.DENIED ? docCModel : self.listDocComponentCs
                    vc.listDocHistories = self.listDocHistories
                    vc.titleString = self.dataInfo?.docCode
                    vc.dataInfo = self.dataInfo
                    vc.totalPage = self.totalPage
                    vc.titleTicket = self.titleTicketName
                    vc.navigationItem.hidesBackButton = true
                    self.title = ""
                    vc.note = self.note
                    switch type {
                    case AccepticketCController.ACCEPT:
                        vc.titlePopup = "Đã xác nhận kiểm kê linh kiện thành công".localized()
                    case AccepticketCController.DENIED:
                        vc.titlePopup = "Đã từ chối xác nhận kiểm kê linh kiện".localized()
                    case AccepticketCController.UPDATE:
                        vc.titlePopup = "Đã cập nhật chi tiết phiếu".localized()
                    default: break
                    }
                    self.navigationController?.pushViewController(vc, animated: true)
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.submitTicketDocC(type: type, docABEModel: docABEModel, docCModel: docCModel, deleteOutPut: deleteOutPut, total: total)
                        }
                    }
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self.showAlertConfigTimeOut()
                        DispatchQueue.main.async {
                            self.switchToInventoryUserFlow()
                        }
                    }
                }
                print(error.localizedDescription)
            }
        })
    }
    
    private func getTickCheckAPI(){
        guard let documentId = self.documentId else {return}
        var listId: [String] = []
        for item in self.listDocComponentCsTick {
            listId.append(item.id ?? "")
        }
        var params = Dictionary<String, Any>()
        params["inventoryId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? ""
        params["docId"] = documentId
        params["ids"] = listId
        networkManager.getHightlight(param: params, completion: { data in
            switch data {
            case .success(let response):
                if response.data?.docTypeCIsHightLights ?? false {
                    self.checkEnableUpdateAndAccept()
                } else {
                    self.disableButtonAcceptAndUpdate()
                }
            default: break
            }
        })
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
            self.getAPIListPartCode(params: self.param)
        }
        myDropDown.show()
    }
    
    func addRowCell() {
        let resultContainer = DocComponentABEs()
        arrayData.append(resultContainer)
        checkEnableUpdateAndAccept()
        let indexPath = IndexPath(row: arrayData.count - 1, section: SectionInventory.rowInventory.rawValue)
           tableView.insertRows(at: [indexPath], with: .automatic)
        updateCellBackgroundColors()
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
    
    @IBAction func ontapSubmitInventory(_ sender: UIButton) {
        submitData(type: AccepticketCController.ACCEPT, docABEModel: arrayData, docCModel: docCModelResult, deleteOutPut: idsDeleteDocOutPut, total: self.resultValueSum)
    }
    @IBAction func deniedTicket(_ sender: Any) {
        arrayData = []
        docCModelResult = []
        for item in arrayData2 {
            let convertABE = DocComponentABEs()
            convertABE.id = item.id
            convertABE.inventoryId = item.inventoryId
            convertABE.inventoryDocId = item.inventoryDocId
            convertABE.quantityPerBom = item.quantityPerBom
            convertABE.quantityOfBom = item.quantityOfBom
            arrayData.append(convertABE)
        }
        
        for item in convertDocCModelResult {
            let convertC = DocComponentCs()
            convertC.id = item.id
            convertC.modelCode = item.modelCode
            convertC.componentCode = item.componentCode
            convertC.quantityPerBom = item.quantityPerBom
            convertC.quantityOfBom = item.quantityOfBom
            docCModelResult.append(convertC)
        }
        submitData(type: AccepticketCController.DENIED, docABEModel: arrayData, docCModel: docCModelResult, deleteOutPut: [], total: currentTotalValueSum)
    }
    @IBAction func onTapUpdate(_ sender: Any) {
        submitData(type: AccepticketCController.UPDATE, docABEModel: arrayData, docCModel: docCModelResult, deleteOutPut: idsDeleteDocOutPut, total: resultValueSum )
    }
}
