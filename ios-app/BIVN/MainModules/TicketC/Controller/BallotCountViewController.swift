//
//  BallotCountViewController.swift
//  BIVN
//
//  Created by Luyen Dao on 22/11/2023.
//

import UIKit
import DropDown
import AVFoundation
import Moya
import Localize_Swift

struct AccessoryBomModel {
    var quantityPerBOM: String
}

enum EnumBallotCount {
    case InfoTicket
    case TitleInventoryCell
    case RowInventoryTableViewCell
    case TotalItemTableViewCell
    case ErrorTableViewCell
    case SearchCodeTableViewCell
    case ContentSheetTBCell
    case PartCodeTableViewCell
    case PageTBCell
    case TitleHistoryCell
    case HistoryInventoryCell
    case ImageViewCell
    static let all = [InfoTicket, TitleInventoryCell, RowInventoryTableViewCell, TotalItemTableViewCell, ErrorTableViewCell,  SearchCodeTableViewCell, ContentSheetTBCell, PartCodeTableViewCell, PageTBCell, TitleHistoryCell, ImageViewCell, HistoryInventoryCell]
}

class BallotCountViewController: BaseViewController, AddRowCell {
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(R.nib.infoTicketTableViewCell)
            tableView.register(R.nib.titleInventoryCell)
            tableView.register(R.nib.rowInventoryTableViewCell)
            tableView.register(R.nib.totalItemTableViewCell)
            tableView.register(R.nib.searchCodeTableViewCell)
            tableView.register(R.nib.contentSheetTBCell)
            tableView.register(R.nib.partCodeTableViewCell)
            tableView.register(R.nib.pageTBCell)
            tableView.register(R.nib.titleHistoryCell)
            tableView.register(R.nib.historyInventoryCell)
            tableView.register(R.nib.historyInventoryCell)
            tableView.register(R.nib.imageViewCell)
            tableView.register(R.nib.errorTableViewCell)
        }
    }
    @IBOutlet weak var ticketNameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var salesOrderLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var saleOrderView: UIStackView!
    @IBOutlet weak var noteView: UIStackView!
    @IBOutlet weak var buttonSend: UIStackView!
    @IBOutlet weak var updateButton: UIButton!
    
    private var accessoryBomModel: [AccessoryBomModel] = []
    private var arrayData: [DocComponentABEs] = []
    private var docCModelResult: [DocComponentCs] = []
    private var docCModelResult2: [DocComponentCs] = []
    private var resultValueSum: Double = 0.0
    private var imageCapture: UIImage?
    var total: String = ""
    var titleString: String?
    var pageSize = 1
    let networkManager: NetworkManager = NetworkManager()
    var param = Dictionary<String, Any>()
    let myDropDown = DropDown()
    var listDocComponentCs: [DocComponentCs] = []
    var listDocHistories: [DocHistory] = []
    var totalPage: Int = 0
    var listDropdownPage: [String] = []
    var listArray: [Int] = []
    var imagePicker = UIImagePickerController()
    var quantityPerBom: String?
    var isCheck: Bool = false
    private var isCheckPushImage: Bool = false
    private var regionUS: Bool = false
    var idsDeleteDocOutPut : [String] = []
    var dataInfo : ResultData?
    var documentId: String?
    var errorValid: Bool = false
    var isShowPage: Bool = false
    var titleInfo: String = ""
    var hideError: Bool = false
    var defaultSum: Double = 0
    var isReloadDocABE: Bool = false
    var dError: Bool = false
    var vc = UIViewController()
    var reloadDataSubmit: (() -> ())?
    var index: Int = 0
    var viewController = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupUI()
        setupImagePicker()
        hideKeyboardWhenTappedAround()
        getAPIListPartCode(params: [:])
        self.hideKeyboardWhenTappedAround()
        updateNumberFormatter()
        let lockButton = UIButton(type: .system)
        lockButton.setImage(UIImage(named: R.image.icFilter.name), for: .normal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .done, target: self, action: #selector(backToInitial))
        arrayData = [DocComponentABEs(id: "", quantityOfBom: nil, quantityPerBom: nil),
                     DocComponentABEs(id: "", quantityOfBom: nil, quantityPerBom: nil)]
    }
    
    @objc func backToInitial() {
        reloadDataSubmit?()
        showAlertNoti(title: "Xác nhận thoát".localized(), message: "Bạn có chắc chắn muốn thoát không? Nếu bạn thoát khi đã nhập dữ liệu thì dữ liệu đó sẽ không được lưu".localized(), cancelButton: "Không".localized(), acceptButton: "Có".localized(), acceptOnTap: {
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setDisplay()
    }
    
    func setDisplay() {
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
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupUI() {
        updateButton.setTitle("Gửi".localized(), for: .normal)
        let buttonRight = UIBarButtonItem(image:  UIImage(named: R.image.ic_camera.name), style: .plain, target: self, action: #selector(onTapCapture))
        self.navigationItem.rightBarButtonItem = buttonRight
        regionUS = numberFormatter.locale.identifier == "en_US"
        self.setFontTitleNavBar()
    }
    
    private func fillDataTitleNavi() {
        self.navigationItem.title = dataInfo?.docCode
    }
    
    @objc func onTapCapture() {
        self.openCamera()
    }
    
    func setupImagePicker() {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            let alertController = UIAlertController(title: nil, message: "Device has no camera.", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Alright", style: .default, handler: { (alert: UIAlertAction!) in
            })
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        } else {
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
        }
    }
    
    private func openCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // the user has already authorized to access the camera.
            print("the user has already authorized to access the camera.")
            //self.setupCaptureSession()
            self.present(self.imagePicker, animated: true, completion: nil)
            
        case .notDetermined: // the user has not yet asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted { // if user has granted to access the camera.
                    print("the user has granted to access the camera")
                    DispatchQueue.main.async {
                        //self.setupCaptureSession()
                        self.present(self.imagePicker, animated: true, completion: nil)
                    }
                } else {
                    print("the user has not granted to access the camera")
                    //self.handleDismiss()
                }
            }
            
        case .denied:
            print("the user has denied previously to access the camera.")
            //self.handleDismiss()
            
        case .restricted:
            print("the user can't give camera access due to some restriction.")
            //self.handleDismiss()
            
        default:
            print("something has wrong due to we can't access the camera.")
            //self.handleDismiss()
        }
    }

    private func getAPIListPartCode(params: Dictionary<String, Any>, index: Int = 0) {
        self.index = index
        self.startLoading()
        networkManager.getListParCode(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", documentId: self.documentId ?? "", actionId: "0", param: params, completion: { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.stopLoading()
                    self.listArray = []
                    self.listDocComponentCs = []
                    self.defaultSum = 0
                    self.listDocComponentCs = response.data?.docComponentCs ?? []
                    if response.data?.docComponentCs?.count ?? 0 >= 10 {
                        self.isShowPage = true
                    }
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
                    
                    self.titleInfo = "\(response.data?.machineModel ?? "") - \(response.data?.machineType ?? "") - \(response.data?.lineName ?? "") - \(response.data?.stageName ?? "")"
                    self.listDocHistories = response.data?.docHistories ?? []
                    self.listDocHistories.sort(by: {$0.getCreateDate().compare($1.getCreateDate()) == .orderedDescending})
                    self.dataInfo = response.data
                    self.fillDataTitleNavi()
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
                    self.totalPage = response.data?.docCTotalPages ?? 0
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
        let resultContainer = DocComponentABEs(id: "")
        arrayData.append(resultContainer)
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

}

//MARK:- Image Picker
extension BallotCountViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        if let imageCapture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.imageCapture = imageCapture
            self.tableView.reloadData()
        }
    }
}

extension BallotCountViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return EnumBallotCount.all.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch EnumBallotCount.all[indexPath.section] {
        case .TitleInventoryCell, .RowInventoryTableViewCell, .TotalItemTableViewCell, .ContentSheetTBCell, .PartCodeTableViewCell:
            return 60
        case .PageTBCell:
            return 40
        default:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch EnumBallotCount.all[section] {
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
        case .HistoryInventoryCell:
            return listDocHistories.count == 0 ? 0 : listDocHistories.count
        case .TitleHistoryCell:
            return listDocHistories.count > 0 ? 1 : 0
        case .ImageViewCell:
            return imageCapture == nil ? 0 : 1
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch EnumBallotCount.all[section] {
        case .TotalItemTableViewCell, .TitleInventoryCell, .RowInventoryTableViewCell, .ContentSheetTBCell:
            return 0
        case .PartCodeTableViewCell:
            return 16
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
        switch EnumBallotCount.all[indexPath.section] {
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
            cell.setDataToCell(data:arrayData[indexPath.row], index: indexPath.row, isLast: (arrayData.count - 1) == indexPath.row ? true : false, isCheck: false)
            if !self.arrayData.isEmpty {
                for item in self.arrayData {
                    let result = item.quantityPerBom ?? 0
                    let result2 = item.quantityOfBom ?? 0
                    totalValue = (result * result2) + totalValue
                }
                self.resultValueSum = totalValue
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
            }
            cell.selectionStyle = .none
            return cell
        case .TotalItemTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.totalItemTableViewCell, for: indexPath) else {return UITableViewCell()}
            if arrayData.count == 0 {
                resultValueSum = 0
            }
            cell.setDataToCell(totalValue: resultValueSum)
            cell.selectionStyle = .none
            return cell
        case .ErrorTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.errorTableViewCell, for: indexPath) else {return UITableViewCell()}
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
                cell.sttLabel.text = "\((pageSize - 1) * 10 + (indexPath.row + 1))"
                cell.fillDataQuality(valueSum: resultValueSum, quantityOfBom: listDocComponentCs[indexPath.row].quantityOfBom ?? 0, index: indexPath.row, isHighLight: listDocComponentCs[indexPath.row].isHighLight ?? false, isCheck: true, isHightlightLocal: listDocComponentCs[indexPath.row].isHighLightLocal ?? false, defaultSum: self.defaultSum)
                cell.regionUS = self.regionUS
                cell.sumTotal = { index, text, keyboard in
                    let resultTotal = self.resultValueSum * (self.listDocComponentCs[index].quantityOfBom ?? 0)
                    self.listDocComponentCs[index].isCheck = true
                    self.listDocComponentCs[index].quantityPerBom = self.unFormatNumber(stringValue: text, regionUS: self.regionUS) > resultTotal ? resultTotal : self.unFormatNumber(stringValue: text, regionUS: self.regionUS)
                    self.listDocComponentCs[index].isHighLight =  self.unFormatNumber(stringValue: text, regionUS: self.regionUS) >= resultTotal ? false : true
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
                vc.titleInfo = self.titleInfo
                vc.titleString = self.listDocHistories[indexPath.row].createdAt?.formatDateWithInputAndOutputType(inputFormat: TypeFormatDate.ServerFormat.rawValue, outputFormat: TypeFormatDate.DD_MM_YYYY_HH_mm.rawValue)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            cell.selectionStyle = .none
            return cell
        case .ImageViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.imageViewCell, for: indexPath) else {return UITableViewCell()}
            cell.setDataToCell(data: self.imageCapture ?? UIImage())
            cell.deleteAction = {
                if self.imageCapture != nil {
                    self.imageCapture = nil
                    self.tableView.reloadSections([indexPath.section], with: .none)
                }
            }
            cell.containerView.addTapGestureRecognizer(action: {
                guard self.imageCapture != nil else { return }
                let vc = ShowImageDetailVC()
                vc.imageCapture = self.imageCapture ?? UIImage()
                vc.modalPresentationStyle = .fullScreen
                self.navigationController?.present(vc, animated: true)
            })
            cell.selectionStyle = .none
            return cell
        }
    }
    //Action
    @IBAction func ontapSubmitInventory(_ sender: UIButton) {
        let isCheckError1 = arrayData.contains(where: {$0.quantityPerBom != nil || $0.quantityOfBom != nil})
        
        if self.arrayData.count == 0 || !isCheckError1 {
            self.showAlertError(title: "Lỗi".localized(), message: "Không có dữ liệu.Vui lòng nhập dữ liệu Số lượng/thùng và Số thùng".localized(), titleButton: "Đồng ý".localized())
            return
        }
        
        let image = imageCapture?.resizeWithPercent(percentage: 0.3)?.pngData()
        if image != nil {
            isCheckPushImage = true
        } else {
            self.showAlertError(title: "Lỗi".localized(), message: "Không có hình ảnh ki.ểm kê.Vui lòng chọn ảnh để kiểm kê.".localized(), titleButton: "Đồng ý".localized())
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
        if !dError {
            buttonSend.isUserInteractionEnabled = false
            self.arrayData.removeAll(where: { $0.quantityOfBom == nil && $0.quantityPerBom == nil })
            submitInventory(image: image ?? Data())
        } else {
            self.buttonSend.isUserInteractionEnabled = true
            errorValid = true
            tableView.reloadData()
        }
    }
    
    func submitInventory(image: Data) {
        networkManager.submitInventory(userCode: UserDefault.shared.getUserID(), inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", documentId: self.documentId ?? "", containerModel: arrayData, docTypeCModel: docCModelResult, image: image, isCheckPushImage: isCheckPushImage, isCheckDocC: true, idsDeleteDocOutPut: idsDeleteDocOutPut, completion: { data in
            self.buttonSend.isUserInteractionEnabled = true
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.dataInfo?.status = response.data?.status
                    let vc = Storyboards.waitConfirmationC.instantiate() as! WaitConfirmationViewController
                    vc.arrayData = self.arrayData
                    vc.valueSum = self.resultValueSum
                    vc.listDocComponentCs = self.listDocComponentCs
                    vc.listDocHistories = self.listDocHistories
                    vc.titleString = self.dataInfo?.docCode
                    vc.dataInfo = self.dataInfo
                    vc.titleTicket = self.titleInfo
                    vc.note = ""
                    vc.viewController = self.viewController
                    vc.navigationItem.hidesBackButton = false
                    vc.titlePopup = "Đã thực hiện kiểm kê linh kiện thành công!".localized()
                    self.navigationController?.pushViewController(vc, animated: false)
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.submitInventory(image: image)
                        }
                    }
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
                }
            case .failure(let error):
                self.buttonSend.isUserInteractionEnabled = true
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self.showAlertConfigTimeOut()
                        DispatchQueue.main.async {
                            for viewController in self.navigationController?.viewControllers ?? [] where viewController is ScanUserIDController {
                                self.navigationController?.popToViewController(viewController, animated: true)
                                return
                            }
                        }
                    }
                }
                print(error.localizedDescription)
            }
        })
    }
}
