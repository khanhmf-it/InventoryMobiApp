//
//  HistoryDetailDocCViewController.swift
//  BIVN
//
//  Created by Luyện Đào on 08/12/2023.
//

import UIKit
import Moya
import DropDown
import Kingfisher
import Localize_Swift

enum EnumHistoryDetailDocC {
    case TitleInventoryCell
    case RowInventoryTableViewCell
    case TotalItemTableViewCell
    case SearchCodeTableViewCell
    case ContentSheetTBCell
    case PartCodeTableViewCell
    case PageTBCell
    case NoteCell
    case HistoryInventoryCell
    case ImageViewCell
    static let all = [TitleInventoryCell,RowInventoryTableViewCell,TotalItemTableViewCell, SearchCodeTableViewCell, ContentSheetTBCell, PartCodeTableViewCell, PageTBCell, NoteCell, HistoryInventoryCell, ImageViewCell]
}

class HistoryDetailDocCViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var titleVoucherNameLabel: UILabel!
    @IBOutlet weak var valueVoucherNameLabel: UILabel!
    @IBOutlet weak var stackVoucher: UIStackView!
    @IBOutlet weak var stackITicketInfo: UIStackView!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var itemCodeLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(R.nib.titleInventoryCell)
            tableView.register(R.nib.rowInventoryTableViewCell)
            tableView.register(R.nib.totalItemTableViewCell)
            tableView.register(R.nib.searchCodeTableViewCell)
            tableView.register(R.nib.contentSheetTBCell)
            tableView.register(R.nib.partCodeTableViewCell)
            tableView.register(R.nib.pageTBCell)
            tableView.register(R.nib.historyInventoryCell)
            tableView.register(R.nib.imageViewCell)
            tableView.register(R.nib.noteCell)
        }
    }
    
    var valueSum: Double = 0
    var titleString: String?
    let networkManager: NetworkManager = NetworkManager()
    var historyId: String?
    var arrayData: [DocComponentABEs] = []
    var listDocComponentCs: [DocComponentCs] = []
    var urlImage: String?
    var resultDataHistory: ResultDataHistory?
    var param = Dictionary<String, Any>()
    var isTicketABE: Bool = false
    var componentCode = ""
    var componentName = ""
    var titleInfo: String = ""
    var totalPage: Int = 0
    var listArray: [Int] = []
    var pageSize = 1
    let myDropDown = DropDown()
    var isCheck: Bool = false
    var titleImage: String = ""
    var isShowPage: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        getDetailHistory(params: [:])
    }
    
    private func setupUI() {
        self.hideKeyboardWhenTappedAround()
        let backImage = UIImage(named: R.image.ic_back.name)
        self.navigationController?.navigationBar.backIndicatorImage = backImage
        self.navigationItem.setHidesBackButton(true, animated: true)
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: #selector(onTapBack))
        self.navigationItem.leftBarButtonItem = buttonLeft
    }
    
    @objc private func onTapBack() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setDisplay()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setDisplay() {
        if let titleString = titleString {
            title = titleString
        }
        
        stackVoucher.isHidden = isTicketABE
        stackITicketInfo.isHidden = !isTicketABE
        itemCodeLabel.text = componentCode
        itemNameLabel.text = componentName
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
            self.getDetailHistory(params: self.param)
        }
        myDropDown.show()
    }
    
    private func getDetailHistory(params: Dictionary<String, Any>) {
        self.startLoading()
        networkManager.getHistoryDetail(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", historyId: historyId ?? "", param: params, completion: { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.stopLoading()
                    self.valueSum = 0
                    self.listArray = []
                    self.listDocComponentCs = response.data?.historyDetailCs ?? []
                    self.arrayData = response.data?.historyOutputs ?? []
                    self.urlImage = response.data?.evicenceImg ?? ""
                    self.valueVoucherNameLabel.text = self.titleInfo
                    self.resultDataHistory = response.data
                    self.titleImage = response.data?.evicenceImgTitle ?? ""
                    self.totalPage = response.data?.docCTotalPages ?? 0
                    if response.data?.historyDetailCs?.count ?? 0 >= 10 {
                        self.isShowPage = true
                    }
                    for item in self.arrayData {
                        self.valueSum += (item.quantityOfBom ?? 0) * (item.quantityPerBom ?? 0)
                    }
                    if self.totalPage != 0 {
                        for i in 1...self.totalPage {
                            self.listArray.append(i)
                        }
                    }
                    self.tableView.reloadData()
                    if self.tableView.numberOfRows(inSection: 0) != 0 {
                        self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                    }
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.getDetailHistory(params: params)
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
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch EnumHistoryDetailDocC.all[indexPath.section] {
        case .TitleInventoryCell, .RowInventoryTableViewCell, .TotalItemTableViewCell, .ContentSheetTBCell, .PartCodeTableViewCell:
            return 60
        case .PageTBCell:
            return isTicketABE ? 0 : 40
        case .NoteCell:
            if resultDataHistory?.comment?.count ?? 0 > 0 {
                return UITableView.automaticDimension
            } else {
                return 0
            }
        default:
            return UITableView.automaticDimension
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return EnumHistoryDetailDocC.all.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch EnumHistoryDetailDocC.all[section] {
        case .RowInventoryTableViewCell:
            return arrayData.count
        case .PartCodeTableViewCell:
            return isTicketABE ? 0 : listDocComponentCs.count > 0 ? listDocComponentCs.count : 1
        case .SearchCodeTableViewCell, .ContentSheetTBCell:
            return isTicketABE ? 0 : 1
        case .NoteCell:
            if resultDataHistory?.comment?.count ?? 0 > 0 {
                return 1
            } else {
                return 0
            }
        case .ImageViewCell:
            if urlImage?.count ?? 0 > 0 {
                return 1
            } else {
                return 0
            }
        case .PageTBCell:
            return isTicketABE ? 0 : isShowPage ? 1 : 0
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch EnumHistoryDetailDocC.all[indexPath.section] {
        case .TitleInventoryCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            return cell
        case .RowInventoryTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.rowInventoryTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.setDataToCell(data: arrayData[indexPath.row], index: indexPath.row, isLast: (arrayData.count - 1) == indexPath.row ? true : false, isCheck: false ,isHideTextField: false)
            cell.selectionStyle = .none
            return cell
        case .TotalItemTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.totalItemTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.setDataToCell(totalValue: valueSum)
            cell.selectionStyle = .none
            return cell
        case .SearchCodeTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.searchCodeTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.onTapSearch = { data in
                self.param["searchTerm"] = data
                self.getDetailHistory(params: self.param)
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
                cell.sttLabel.text = "\(indexPath.row + 1)"
                cell.fillDataQuality(valueSum: valueSum, quantityOfBom: Double(Int(listDocComponentCs[indexPath.row].quantityOfBom ?? 0.0)), index: indexPath.row, isCheckHideTextField: false, isHighLight: listDocComponentCs[indexPath.row].isHighLight ?? false, defaultSum: valueSum, isDetailHistoryScreen: true)
            }
            cell.selectionStyle = .none
            return cell
        case .HistoryInventoryCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.historyInventoryCell, for: indexPath) else {return UITableViewCell()}
            if let resultDataHistory = resultDataHistory {
                cell.fillDataHistoryDetail(resultDataHistory: resultDataHistory)
            }
            cell.clearShadowBorder()
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
                self.listDocComponentCs = []
                self.pageSize += 1
                self.param["page"] = self.pageSize
                self.getDetailHistory(params: self.param)
            }
            cell.leftPage = {
                self.listDocComponentCs = []
                self.pageSize -= 1
                self.param["page"] = self.pageSize
                self.getDetailHistory(params: self.param)
                
            }
            cell.textPageLabel.text = "of \(totalPage) pages"
            cell.onTapShowDropDown = { value, button in
                self.showDropdown(text: value, size: button)
            }
            cell.numberPageLabel.text = "\(self.pageSize)"
            cell.selectionStyle = .none
            return cell
        case .ImageViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.imageViewCell, for: indexPath) else {return UITableViewCell()}
            cell.fillDataHistoryDetail(url: urlImage?.replacingOccurrences(of: "\\", with: "/") ?? "")
            cell.containerView.addTapGestureRecognizer(action: {
                guard self.urlImage != nil else { return }
                let vc = ShowImageDetailVC()
                vc.disPlayDetailHistory = true
                vc.titleString = self.titleImage
                vc.url = "\(Environment.rootURL)/\(self.urlImage ?? "")"
                vc.modalPresentationStyle = .fullScreen
                self.navigationController?.present(vc, animated: true)
            })
            cell.selectionStyle = .none
            return cell
        case .NoteCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.noteCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.isHiddenAddButton = false
            cell.cellDelegate = self
            cell.setDataForHistory(note: resultDataHistory?.comment ?? "")
            return cell
        }
    }
    
}

extension HistoryDetailDocCViewController: NoteCellProtocol {
    func updateHeightNote(_ cell: NoteCell, _ textView: UITextView) {
        let size = textView.bounds.size
        let newSize = tableView.sizeThatFits(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude))
        if size.height != newSize.height {
            UITableView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            tableView.endUpdates()
            UITableView.setAnimationsEnabled(true)
            if let indexPath = tableView.indexPath(for: cell) {
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
        }
    }
}
