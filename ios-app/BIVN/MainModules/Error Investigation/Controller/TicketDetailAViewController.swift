//
//  TicketDetailAViewController.swift
//  BIVN
//
//  Created by Bi on 10/1/25.
//

import UIKit
import AVFoundation
import Moya
import IQKeyboardManagerSwift
import Kingfisher
import Localize_Swift

class TicketDetailAViewController: BaseViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    private var rowSelected = -1
    private var arrayAccessory: [AccessoryModel] = []
    private var arrayData: [DocComponentABEs] = []
    private var dataOrigin: [ConvertDocComponentCs] = []
    private var arrayHistoryInventory: [Int] = [1]
    private var valueSumTest: Double = 0
    var imagePicker = UIImagePickerController()
    private var imageCapture: UIImage?
    var evicenceImg: String?
    let networkManager: NetworkManager = NetworkManager()
    var dataTicket = DetailResponseDataTicket()
    var idsDeleteDocOutPut: [String] = []
    var lastRow = -1
    var jobIndex : Int = 0
    var resetInventory: Bool = false
    var reloadDataSubmit: (() -> ())?
    // confirm work
    var isConfirmScan: Bool = false
    @IBOutlet weak var viewBottom: UIView!
    private var successConfirm = false
    private var isHiddenReason: Bool = true
    private var note: String = ""
    private var regionUS = false
    private var isEditPermission = true
    let currentRegion = Locale.current.regionCode
    var urlLink: URL?
    var param = Dictionary<String, Any>()
    var docCode: String?
    var componentCode: String?
    var positionCode: String?
    var listDataTicket = [DetailResponseDataTicket]()
    var accessoryModel: AccessoryModels?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        regionUS = numberFormatter.locale.identifier == "en_VN"
        arrayData = dataTicket.components ?? []
        backButton.setTitle("Quay lại".localized(), for: .normal)
        continueButton.setTitle("Tiếp Tục".localized(), for: .normal)
        for item in self.arrayData {
            let convertData = ConvertDocComponentCs()
            convertData.id = item.id
            convertData.quantityPerBom = item.quantityPerBom
            convertData.quantityOfBom = item.quantityOfBom
            self.dataOrigin.append(convertData)
        }
        
        if arrayData.count == 0 {
            let docABE1 = DocComponentABEs(id: "", inventoryDocId: "")
            let docABE2 = DocComponentABEs(id: "", inventoryDocId: "")
            arrayData.append(docABE1)
            arrayData.append(docABE2)
        }
        
        totalResult()
        setupUI()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        IQKeyboardManager.shared.isEnabled = true
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = self.dataTicket.inventoryDoc?.docCode
        
        if arrayData.count == 0 {
            let docABE1 = DocComponentABEs(id: "", inventoryDocId: "")
            let docABE2 = DocComponentABEs(id: "", inventoryDocId: "")
            arrayData.append(docABE1)
            arrayData.append(docABE2)
        }
        self.tableView.reloadData()
        IQKeyboardManager.shared.isEnabled = false
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
    
    private func setupUI() {
        self.hideKeyboardWhenTappedAround()
        if isConfirmScan {
            if dataTicket.inventoryDoc?.inventoryBy == UserDefault.shared.getUserID() || dataTicket.inventoryDoc?.status == 6 {
                isEditPermission = false
            } else {
                isEditPermission = true
            }
        } else {
            if dataTicket.inventoryDoc?.confirmedBy == UserDefault.shared.getUserID() || dataTicket.inventoryDoc?.status == 6 {
                isEditPermission = false
            } else {
                isEditPermission = true
            }
        }
        self.navigationItem.hidesBackButton = true
        
        self.setFontTitleNavBar()
        
        setupTableView()
    }
    
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(R.nib.infoTicketTableViewCell)
        tableView.register(R.nib.titleInventoryCell)
        tableView.register(R.nib.invenTableViewCell)
        tableView.register(R.nib.totalItemTableViewCell)
        tableView.register(R.nib.noteCell)
        tableView.register(R.nib.historyInventoryCell)
        tableView.register(R.nib.imageViewCell)
        tableView.register(R.nib.titleHistoryCell)
        tableView.contentInset.bottom = 16
        
    }
    
    @objc private func onTapBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func addOnTap() {
        let docABE = DocComponentABEs(id: "", inventoryDocId: "")
        arrayData.append(docABE)
        tableView.reloadData()
    }
    
    private func showImage() {
        guard self.imageCapture != nil else { return }
        let vc = ShowImageDetailVC()
        vc.imageCapture = self.imageCapture ?? UIImage()
        vc.modalPresentationStyle = .fullScreen
        self.navigationController?.present(vc, animated: true)
    }
    
    private func showToast(content: String) {
        let attribute1 = [NSAttributedString.Key.font: fontUtils.size12.regular]
        let attrString1 = NSMutableAttributedString(string: content, attributes: attribute1)
        self.view.showToastCompletion(attrString1, img: UIImage(named: R.image.icTickCircle.name), isSee: false, completion: {
        })
    }
    
}

extension TicketDetailAViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 12
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SectionInventory(rawValue: section) {
        case .infoSheet:
            return 1
        case .titleInventory:
            return 1
        case .sumInventory:
            return arrayData.count > 0 ? 1 : 0
        case .rowInventory:
            return arrayData.count
        case .titleHistory:
            return dataTicket.histories?.count ?? 0 > 0 ? 1 : 0
        case .historyInventory:
            return dataTicket.histories?.count ?? 0
        case .imageViewCell:
            if evicenceImg != nil {
                return 1
            } else {
                if imageCapture != nil {
                    return 1
                } else {
                    return 0
                }
            }
        case .errorTable:
            return 1
        case .noteInventory:
            guard isEditPermission else { return 0 }
            if isConfirmScan {
                if self.dataTicket.inventoryDoc?.status == 6 || self.dataTicket.inventoryDoc?.status == 5 {
                    return (self.dataTicket.inventoryDoc?.note == nil || (self.dataTicket.inventoryDoc?.note ?? "").isEmpty) ? 0 : 1
                } else {
                    return 1
                }
            } else {
                return 0
            }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch SectionInventory(rawValue: indexPath.section) {
        case .infoSheet:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.infoTicketTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.setDataToCell(model: dataTicket.inventoryDoc, isConfirmScan: isConfirmScan)
            cell.stackAddButton.isHidden = true
            cell.selectionStyle = .none
            return cell
        case .titleInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            return cell
        case .rowInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.invenTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.regionUS = self.regionUS
            cell.setEditView(isHidden: isEditPermission)
            cell.setDataToCell(data: arrayData[indexPath.row], index: indexPath.row, isLast: (arrayData.count - 1) == indexPath.row ? true : false)
            cell.sumTotal = { (index, quantityPerBom, quantityOfBom, isCheckBox) in
                self.arrayData[index].quantityOfBom = quantityOfBom == "" ? nil : self.unFormatNumber2(stringValue: quantityOfBom, regionUS: self.regionUS, currentRegion: self.currentRegion ?? "")
                self.arrayData[index].quantityPerBom = quantityPerBom == "" ? nil : self.unFormatNumber2(stringValue: quantityPerBom, regionUS: self.regionUS, currentRegion: self.currentRegion ?? "")
                self.arrayData[index].isCheckBox = isCheckBox
                
                var totalValue: Double = 0.0
                for item in self.arrayData {
                    if let quantityOfBom = item.quantityOfBom, let quantityPerBom = item.quantityPerBom {
                        totalValue = (quantityOfBom * quantityPerBom) + totalValue
                    }
                }
                
                self.valueSumTest = totalValue
                if self.tableView.indexPathsForVisibleRows?.contains(indexPath) != nil {
                    self.tableView.beginUpdates()
                    self.tableView.reloadSections(IndexSet(integer: SectionInventory.sumInventory.rawValue), with: .none)
                    self.tableView.reloadSections(IndexSet(integer: SectionInventory.errorTable.rawValue), with: .none)
                    self.tableView.endUpdates()
                }
            }
            cell.numberTextField.isUserInteractionEnabled = false
            cell.binsTextField.isUserInteractionEnabled = false
            return cell
        case .sumInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.totalItemTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            
            cell.setDataToCell(totalValue: valueSumTest)
            
            return cell
        case .errorTable:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleHistoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setTitleError(content: "Vui lòng nhập số lượng và số thùng.".localized())
            return cell
        case .noteInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.noteCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            if self.dataTicket.inventoryDoc?.status != 6 || self.dataTicket.inventoryDoc?.status != 5 {
                cell.isHiddenAddButton = false
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
                }
                if isConfirmScan {
                    cell.reasonTextView.isUserInteractionEnabled = isEditPermission
                }
            } else {
                cell.setDataForHistory(note: self.dataTicket.inventoryDoc?.note ?? "")
            }
            return cell
        case .titleHistory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleHistoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setTitleHistory()
            return cell
        case .historyInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.historyInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            if let dataHis = self.dataTicket.histories?[indexPath.row] {
                cell.fillDataHistoryDetail(resultDataHistory: dataHis)
            }
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
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch SectionInventory(rawValue: indexPath.section) {
        case .historyInventory:
            guard let vc = Storyboards.detailHistoryTicketC.instantiate() as? HistoryDetailDocCViewController else {return}
            vc.historyId = self.dataTicket.histories?[indexPath.row].id
            self.arrayData.removeAll(where: {
                ($0.quantityOfBom == 0 || $0.quantityOfBom == nil) && ($0.quantityPerBom == 0 || $0.quantityPerBom == nil)
            })
            vc.isTicketABE = true
            vc.componentName = dataTicket.inventoryDoc?.componentName ?? ""
            vc.componentCode = dataTicket.inventoryDoc?.componentCode ?? ""
            self.title = ""
            vc.titleString = self.dataTicket.histories?[indexPath.row].createdAt?.formatDateWithInputAndOutputType(inputFormat: TypeFormatDate.ServerFormat.rawValue, outputFormat: TypeFormatDate.DD_MM_YYYY_HH_mm.rawValue)
            self.navigationController?.pushViewController(vc, animated: true)
        case .imageViewCell:
            showImage()
        default:
            print(indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch SectionInventory(rawValue: indexPath.section) {
        case .infoSheet:
            return UITableView.automaticDimension
        case .noteInventory:
            if  !isEditPermission {
                return 0
            }
            return isHiddenReason ? UITableView.automaticDimension : 130
        case .titleHistory:
            return 40
        case .historyInventory:
            return 100
        case .imageViewCell:
            return 200
        case .errorTable:
            return 0
        default:
            return 60
        }
    }
    
    @IBAction func ontapBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func ontapContinue(_ sender: UIButton) {
        guard let vc = Storyboards.errorCorrection.instantiate() as? ErrorCorrectionViewController else {return}
        vc.componentCode = dataTicket.inventoryDoc?.componentCode ?? ""
        vc.accessoryModel = self.accessoryModel
        vc.titleString = "Điều chỉnh sai số".localized()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension TicketDetailAViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        if let imageCapture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.imageCapture = imageCapture
            self.evicenceImg = nil
            self.tableView.reloadData()
        }
    }
}
