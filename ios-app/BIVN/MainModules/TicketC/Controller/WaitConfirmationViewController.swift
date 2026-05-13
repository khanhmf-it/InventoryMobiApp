//
//  WaitConfirmationViewController.swift
//  BIVN
//
//  Created by Luyện Đào on 01/12/2023.
//
enum EnumWaitConfirmation {
    case InfoTicket
    case TitleInventoryCell
    case RowInventoryTableViewCell
    case TotalItemTableViewCell
    case SearchCodeTableViewCell
    case ContentSheetTBCell
    case PartCodeTableViewCell
    case PageTBCell
    case NoteViewCell
    case TitleHistoryTableViewCell
    case HistoryInventoryCell
    static let all = [InfoTicket, TitleInventoryCell,RowInventoryTableViewCell,TotalItemTableViewCell,  SearchCodeTableViewCell,
                      ContentSheetTBCell,
                      PartCodeTableViewCell,
                      PageTBCell,
                      TitleHistoryTableViewCell, HistoryInventoryCell, NoteViewCell ]
}

import UIKit
import DropDown
import Localize_Swift

class WaitConfirmationViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, AddRowCell {
    
    @IBOutlet weak var titlePartCodeLabel: UILabel!
    @IBOutlet weak var titleComponentNameLabel: UILabel!
    @IBOutlet weak var titleLocationLabel: UILabel!
    @IBOutlet weak var titleStatusLabel: UILabel!
    
    @IBOutlet weak var valuePartCodeLabel: UILabel!
    @IBOutlet weak var valueComponentNameLabel: UILabel!
    @IBOutlet weak var valueLocationLabel: UILabel!
    @IBOutlet weak var valueStatusLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(R.nib.infoTicketTableViewCell)
            tableView.register(R.nib.titleInventoryCell)
            tableView.register(R.nib.rowInventoryTableViewCell)
            tableView.register(R.nib.totalItemTableViewCell)
            tableView.register(R.nib.titleHistoryTableViewCell)
            tableView.register(R.nib.historyInventoryCell)
            tableView.register(R.nib.searchCodeTableViewCell)
            tableView.register(R.nib.contentSheetTBCell)
            tableView.register(R.nib.partCodeTableViewCell)
            tableView.register(R.nib.noteCell)
            tableView.register(R.nib.pageTBCell)
            
        }
    }
    
    var arrayData: [DocComponentABEs] = []
    var valueSum:Double = 0
    var titleString: String?
    var listDocHistories: [DocHistory] = []
    var listDocComponentCs: [DocComponentCs] = []
    var listArray: [Int] = []
    var totalPage: Int = 0
    var myDropDown = DropDown()
    var note: String = ""
    var pageSize = 1
    var titlePopup: String = ""
    var dataInfo : ResultData?
    var isBackThreeSeconds: Bool = true
    var titleTicket: String = ""
    var isShowPage : Bool = false
    let networkManager: NetworkManager = NetworkManager()
    var documentId: String = ""
    var param = Dictionary<String, Any>()
    var viewController = 0
    // 0 = scanTicketC , 1 = listAccessory
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if dataInfo?.docComponentCs?.count ?? 0 >= 10 {
            isShowPage = true
        }
        
        if !isBackThreeSeconds {
            callAPIToDetail(documentId: documentId, params: [:])
        }
    }
    
    private func setupUI() {
        hideKeyboardWhenTappedAround()
        let backImage = UIImage(named: R.image.ic_back.name)
        self.navigationController?.navigationBar.backIndicatorImage = backImage
        self.navigationItem.setHidesBackButton(true, animated: true)
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: #selector(onTapBack))
        self.navigationItem.leftBarButtonItem = buttonLeft
    }
    
    @objc private func onTapBack() {
        navigationController?.popViewController(animated: true)
    }
    
    func callAPIToDetail(documentId: String, params: Dictionary<String, Any>){
        networkManager.getListParCode(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", documentId: documentId, actionId: "1", param: params, completion: { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.listDocComponentCs = []
                    self.listArray = []
                    var totalValue = 0.0
                    for item in response.data?.docComponentABEs ?? [] {
                       let result = item.quantityPerBom ?? 0
                       let result2 = item.quantityOfBom ?? 0
                        totalValue = (result * result2) + totalValue
                   }
                    if response.data?.docComponentCs?.count ?? 0 >= 10 {
                        self.isShowPage = true
                    }
                    self.arrayData = response.data?.docComponentABEs ?? []
                    self.valueSum = totalValue
                    self.totalPage = response.data?.docCTotalPages ?? 0
                    if self.totalPage != 0 {
                        for i in 1...self.totalPage {
                            self.listArray.append(i)
                        }
                    }
                    self.listDocComponentCs = response.data?.docComponentCs ?? []
                    self.listDocHistories = response.data?.docHistories ?? []
                    self.title = response.data?.docCode ?? ""
                    self.titleTicket = "\(response.data?.machineModel ?? "") - \(response.data?.machineType ?? "") - \(response.data?.lineName ?? "") - \(response.data?.stageName ?? "")"
                    self.dataInfo = response.data ?? ResultData()
                    self.tableView.reloadData()
                    if self.tableView.numberOfRows(inSection: 0) != 0 {
                        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                        }
                    self.navigationItem.hidesBackButton = false
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.callAPIToDetail(documentId: documentId, params: params)
                        }
                    }
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
                }
            default:
                break
            }
        }
    )}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setDisplay()
        if isBackThreeSeconds {
            showToast()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isBackThreeSeconds {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                guard let navigationController = self.navigationController else {
                    return
                }
                UserDefault.shared.setReload(isReload: true)
                if self.viewController == 0 {
                    for viewController in navigationController.viewControllers where viewController is ScanCodeTicketCViewController {
                        UserDefault.shared.setReload(isReload: true)
                        navigationController.popToViewController(viewController, animated: true)
                    }
                } else {
                    for viewController in navigationController.viewControllers where viewController is ListAccessoryNotInventoryViewController {
                        UserDefault.shared.setReload(isReload: true)
                        navigationController.popToViewController(viewController, animated: true)
                    }
                }
            }
        }
    }
    
    func setDisplay() {
        if let titleString = titleString {
            title = titleString
        }
    }
    
    private func showToast() {
        let attribute1 = [NSAttributedString.Key.font: fontUtils.size14.regular]
        let attrString1 = NSMutableAttributedString(string: titlePopup, attributes: attribute1)
        self.view.showToastCompletion(attrString1, numberOfLine: 1, img: UIImage(named: R.image.icTickCircle.name), isSee: false, completion: {
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return EnumWaitConfirmation.all.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch EnumWaitConfirmation.all[section] {
        case .RowInventoryTableViewCell:
            return arrayData.count
        case .PartCodeTableViewCell:
            return listDocComponentCs.count == 0 ? 1: listDocComponentCs.count
        case .HistoryInventoryCell:
            return listDocHistories.count
        case .PageTBCell:
            return isShowPage ? 1 : 0
        case .NoteViewCell:
            return 0
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch EnumWaitConfirmation.all[indexPath.section] {
        case .TitleInventoryCell, .RowInventoryTableViewCell, .TotalItemTableViewCell, .ContentSheetTBCell, .PartCodeTableViewCell:
            return 60
        case .PageTBCell:
            return 40
        case .NoteViewCell: return 120
        default:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch EnumWaitConfirmation.all[indexPath.section] {
        case .InfoTicket:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.infoTicketTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.delegateAddRow = self
            cell.addRowButton.isHidden = true
            cell.fillData(model: dataInfo)
            cell.selectionStyle = .none
            return cell
        case .TitleInventoryCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            return cell
        case .RowInventoryTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.rowInventoryTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.setDataToCell(data: arrayData[indexPath.row], index: indexPath.row, isLast: (arrayData.count - 1) == indexPath.row ? true : false, isCheck: false, isHideTextField: false)
            return cell
        case .TotalItemTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.totalItemTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.setDataToCell(totalValue: valueSum)
            cell.selectionStyle = .none
            return cell
        case .TitleHistoryTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleHistoryTableViewCell, for: indexPath) else {return UITableViewCell()}
            return cell
        case .SearchCodeTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.searchCodeTableViewCell, for: indexPath) else {return UITableViewCell()}
            if !self.isBackThreeSeconds {
                cell.searchTextField.isUserInteractionEnabled = true
            } else {
                cell.searchTextField.isUserInteractionEnabled = false
            }
            cell.onTapSearch = { data in
                self.param["searchTerm"] = data
                self.callAPIToDetail(documentId: self.documentId, params:  self.param)
            }
            cell.selectionStyle = .none
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
                cell.sttLabel.text = "\((pageSize - 1) * 10 + (indexPath.row + 1))"
                cell.fillDataQuality(valueSum: self.valueSum, quantityOfBom: listDocComponentCs[indexPath.row].quantityOfBom ?? 0, index: indexPath.row, isCheckHideTextField: false, isHighLight: listDocComponentCs[indexPath.row].isHighLight ?? false, isHightlightLocal: listDocComponentCs[indexPath.row].isHighLightLocal ?? false, defaultSum: valueSum)
                cell.selectionStyle = .none
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
                self.pageSize += 1
                self.param["page"] = self.pageSize
                self.callAPIToDetail(documentId: self.documentId, params:  self.param)
            }
            cell.leftPage = {
                self.listDocComponentCs = []
                self.pageSize -= 1
                self.param["page"] = self.pageSize
                self.callAPIToDetail(documentId: self.documentId, params:  self.param)
                
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
            cell.isHiddenAddButton = true
            cell.isHiddenReason = false
            cell.setDataToView()
            if self.note != "" {
                cell.isHiddenReason = false
                cell.placeholderLabel.isHidden = true
            } else {
                cell.isHiddenReason = true
            }
            cell.reasonTextView.text = self.note
            return cell
        case .HistoryInventoryCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.historyInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.fillDataDocC(data: listDocHistories[indexPath.row])
            if !self.isBackThreeSeconds {
                cell.containerView.addTapGestureRecognizer(action: {
                    guard let vc = Storyboards.detailHistoryTicketC.instantiate() as? HistoryDetailDocCViewController else {return}
                    vc.historyId = self.listDocHistories[indexPath.row].id
                    vc.titleInfo = self.titleTicket
                    vc.titleString = self.listDocHistories[indexPath.row].createdAt?.formatDateWithInputAndOutputType(inputFormat: TypeFormatDate.ServerFormat.rawValue, outputFormat: TypeFormatDate.DD_MM_YYYY_HH_mm.rawValue)
                    self.navigationController?.pushViewController(vc, animated: true)
                })
            }
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
            self.callAPIToDetail(documentId: self.documentId, params:  self.param)
        }
        myDropDown.show()
    }
    
    func addRowCell() {
    }
    
    
}
