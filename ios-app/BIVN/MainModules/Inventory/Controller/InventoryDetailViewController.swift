//
//  InventoryDetailViewController.swift
//  BIVN
//
//  Created by Tinhvan on 01/11/2023.
//

import UIKit
import AVFoundation
import Moya
import IQKeyboardManagerSwift
import Kingfisher
import Localize_Swift

enum SectionInventory: Int {
    case infoSheet = 0
    case titleInventory = 1
    case rowInventory = 2
    case sumInventory = 3
    case errorTable = 4
    case noteInventory = 5
    case imageViewCell = 6
    case titleHistory = 7
    case historyInventory = 8
    case titleTableInventory = 9
    case tableInventory = 10
    case pageTableInventory = 11
}

extension UITableView {
    func setBottomInset(to value: CGFloat) {
        let edgeInset = UIEdgeInsets(top: 0, left: 0, bottom: value, right: 0)
        self.contentInset = edgeInset
        self.scrollIndicatorInsets = edgeInset
    }
}

class InventoryDetailViewController: BaseViewController {
    
    @IBOutlet weak var sendButton: UIButton!
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
    var isShowError = false
    var lastRow = -1
    var jobIndex : Int = 0
    var resetInventory: Bool = false
    var reloadDataSubmit: (() -> ())?
    // confirm work
    var isConfirmScan: Bool = false
    @IBOutlet weak var stackConfirmBottom: UIStackView!
    @IBOutlet weak var reInstallButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var viewBottom: UIView!
    private var successConfirm = false
    private var isHiddenReason: Bool = true
    private var note: String = ""
    private var regionUS = false
    private var isEditPermission = true
    let currentRegion = Locale.current.regionCode
    var urlLink: URL?

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    @objc func keyBoardWillShow(notification: Notification) {
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            print("Notification: Keyboard will show")
            tableView.setBottomInset(to: keyboardHeight)
        }
    }
    
    @objc func keyBoardWillHide(notification: Notification) {
        print("Notification: Keyboard will hide")
        tableView.setBottomInset(to: 0.0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        regionUS = numberFormatter.locale.identifier == "en_VN"
        arrayData = dataTicket.components ?? []
        
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        setupUI()
        setupImagePicker()
        
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
    
    private func setupUI() {
        self.hideKeyboardWhenTappedAround()
        sendButton.setTitle("Gửi".localized(), for: .normal)
        sendButton.layer.cornerRadius = 4
        sendButton.layer.borderWidth = 1
        sendButton.layer.borderColor = UIColor(named: R.color.buttonBlue.name)?.cgColor
        reInstallButton.setTitle("Từ chối".localized(), for: .normal)
        updateButton.setTitle("Cập nhật".localized(), for: .normal)
        confirmButton.setTitle("Xác nhận".localized(), for: .normal)
        reInstallButton.tag = 0
        confirmButton.tag = 1
        updateButton.tag = 2
        reInstallButton.isUserInteractionEnabled = self.note.isEmpty != true
        
        // permission edit
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
        
        let iconBack = UIImage(named: R.image.ic_back.name)
        self.navigationController?.navigationBar.backIndicatorImage = iconBack
        self.navigationController?.navigationBar.tintColor = UIColor.gray
        self.navigationItem.setHidesBackButton(true, animated: true)
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: #selector(onTapBack))
        self.navigationItem.leftBarButtonItem = buttonLeft
        let buttonRight = UIBarButtonItem(image:  UIImage(named: R.image.ic_camera.name), style: .plain, target: self, action: #selector(onTapCapture))
        
        if isConfirmScan || dataTicket.inventoryDoc?.status == 6 || !isEditPermission {
            self.navigationItem.rightBarButtonItem = nil
        } else {
            if jobIndex == 0 {
                self.navigationItem.rightBarButtonItem = buttonRight
            } else {
                self.navigationItem.rightBarButtonItem = nil
            }
        }
        
        self.setFontTitleNavBar()
        
        sendButton.addTarget(self, action: #selector(sendOnTap), for: .touchUpInside)
        
        setupTableView()
        
        // MARK: setup data
        //        QRCodeButton.isHidden = isConfirmScan
        if isConfirmScan {
            sendButton.isHidden = true
        } else {
            sendButton.isHidden = !isEditPermission
        }
        stackConfirmBottom.isHidden = !isConfirmScan
        
        changeColorButton()
        
        if isConfirmScan {
            switch dataTicket.inventoryDoc?.status {
            case 0: // "Chưa tiếp nhận"
                self.viewBottom.isHidden = true
            case 1: // "Không kiểm kê"
                self.viewBottom.isHidden = true
            case 2: // "Chưa kiểm kê"
                self.viewBottom.isHidden = true
            case 3: // "Chờ xác nhận"
                self.updateButton.isHidden = true
                self.reInstallButton.isHidden = false
                self.confirmButton.isHidden = false
            case 4: // "Cần chỉnh sửa"
                self.updateButton.isHidden = false
                self.reInstallButton.isHidden = true
                self.confirmButton.isHidden = true
            case 5: // "Đã xác nhận"
                self.updateButton.isHidden = false
                self.reInstallButton.isHidden = true
                self.confirmButton.isHidden = true
                if !isConfirmScan {
                    self.viewBottom.isHidden = true
                }
            case 6: // "Đã đạt giám sát"
                self.viewBottom.isHidden = true
            case 7: // "Không đạt giám sát"
                self.updateButton.isHidden = false
                self.reInstallButton.isHidden = true
                self.confirmButton.isHidden = true
            default:
                break
            }
        } else {
            self.viewBottom.isHidden = false
        }
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
        showAlertNoti(title: "Xác nhận thoát".localized(), message: "Bạn có chắc chắn muốn thoát không? Nếu bạn thoát khi đã nhập dữ liệu thì dữ liệu đó sẽ không được lưu".localized(), cancelButton: "Không".localized(), acceptButton: "Có".localized(), acceptOnTap: {
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    @objc private func onTapCapture() {
        self.openCamera()
    }
    
    @objc private func QRCodeTap() {
        self.isShowError = false
        
        let vc = Storyboards.qrInventory.instantiate() as? QRInventoryVC
        vc?.arrayAccessory = self.arrayAccessory
        vc?.componentCodeABE = self.dataTicket.inventoryDoc?.componentCode ?? ""
        if resetInventory == false {
            if arrayData.count == 0 {
                let docABE1 = DocComponentABEs(id: "", inventoryDocId: "")
                let docABE2 = DocComponentABEs(id: "", inventoryDocId: "")
                arrayData.append(docABE1)
                arrayData.append(docABE2)
            }
        }
        vc?.delegateQR = self
//        vc?.checkDuplicateQR = { [weak self] arrayAccessory in
//            guard let self = self else { return }
//            self.arrayAccessory = arrayAccessory
//        }
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    @objc private func addOnTap() {
        let docABE = DocComponentABEs(id: "", inventoryDocId: "")
        arrayData.append(docABE)
        
        let indexPath = IndexPath(row: arrayData.count - 1, section: SectionInventory.rowInventory.rawValue)
           tableView.insertRows(at: [indexPath], with: .automatic)
        updateCellBackgroundColors()
        
        self.changeColorButton()
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
    
    @objc private func sendOnTap() {
        let isCheckError1 = arrayData.contains(where: {$0.quantityPerBom != nil || $0.quantityOfBom != nil})
        
        if self.arrayData.count == 0 || !isCheckError1 {
            self.showAlertError(title: "Lỗi".localized(), message: "Không có dữ liệu.Vui lòng nhập dữ liệu Số lượng/thùng và Số thùng".localized(), titleButton: "Đồng ý".localized())
            return
        }
        
        let image = imageCapture?.resizeWithPercent(percentage: 0.3)?.pngData()
        var isCheckPushImage = false
        if image != nil {
            isCheckPushImage = true
        } else {
            self.showAlertError(title: "Lỗi".localized(), message: "Không có hình ảnh kiểm kê.Vui lòng chọn ảnh để kiểm kê.".localized(), titleButton: "Đồng ý".localized())
            return
        }
        
        let isCheckError2 = arrayData.contains(where: {$0.quantityPerBom == nil && $0.quantityOfBom != nil})
        let isCheckError3 = arrayData.contains(where: {$0.quantityPerBom != nil && $0.quantityOfBom == nil})

        if isCheckError1 {
            if isCheckError2 || isCheckError3 {
                isShowError = true
            }
        }
        
        if !isShowError {
            submitTicket(image: image ?? Data(), isCheckPushImage: isCheckPushImage)
        } else {
            self.tableView.reloadData()
        }
    }
    
    func submitTicket(image: Data, isCheckPushImage: Bool) {
        self.arrayData.removeAll(where: { $0.quantityOfBom == nil && $0.quantityPerBom == nil })
        for item in self.arrayData {
            if(item.quantityOfBom == nil  || item.quantityOfBom == nil) {
                self.idsDeleteDocOutPut.append(item.id ?? "")
            }
        }
        print(self.arrayData.count)
        self.sendButton.isUserInteractionEnabled = false
        networkManager.submitInventory(userCode: UserDefault.shared.getUserID(), inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", documentId: dataTicket.inventoryDoc?.id ?? "", containerModel: arrayData, docTypeCModel: [], image: image, isCheckPushImage: isCheckPushImage, isCheckDocC: false, idsDeleteDocOutPut: idsDeleteDocOutPut, completion: { data in
            
            self.sendButton.isUserInteractionEnabled = true
            switch data {
            case .success(let response):
                if response.code == 200 {
                    let dataResponse: DataResponseSubmit = response.data ?? DataResponseSubmit()
                    self.dataTicket.inventoryDoc?.status = dataResponse.status
                    self.isEditPermission = false
                    self.tableView.reloadData()
                    self.showToast(content: "Đã thực hiện kiểm kê linh kiện thành công!".localized())
                    self.viewBottom.isHidden = true
                    self.navigationItem.rightBarButtonItem = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.reloadDataSubmit?()
                        self.navigationController?.popViewController(animated: true)
                    }
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            let image = imageCapture?.resizeWithPercent(percentage: 0.3)?.pngData()
                            var isCheckPushImage = false
                            if image != nil {
                                isCheckPushImage = true
                            } else {
                                self.showAlertError(title: "Lỗi".localized(), message: "Không có hình ảnh kiểm kê.Vui lòng chọn ảnh để kiểm kê.".localized(), titleButton: "Đồng ý".localized())
                                return
                            }
                            submitTicket(image: image ?? Data(), isCheckPushImage: isCheckPushImage)
                        }
                    }
                } else if response.code == 400 {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: response.message ?? "",cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
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
    
    @IBAction func confirmActionButton(_ sender: UIButton) {
        
        let isCheckError1 = arrayData.contains(where: {$0.quantityPerBom != nil || $0.quantityOfBom != nil})
        
        if self.arrayData.count == 0 || !isCheckError1 {
            self.showAlertError(title: "Lỗi".localized(), message: "Không có dữ liệu.Vui lòng nhập dữ liệu Số lượng/thùng và Số thùng".localized(), titleButton: "Đồng ý".localized())
            return
        }
        
        let isCheckError2 = arrayData.contains(where: {$0.quantityPerBom == nil && $0.quantityOfBom != nil})
        let isCheckError3 = arrayData.contains(where: {$0.quantityPerBom != nil && $0.quantityOfBom == nil})

        if isCheckError1 {
            if isCheckError2 || isCheckError3 {
                isShowError = true
            }
        }
        
        if !isShowError {
            submitTicketDocC(sender: sender)
        } else {
            self.tableView.reloadData()
        }
        
    }
    
    func submitTicketDocC(sender: UIButton) {
        for item in self.arrayData {
            if(item.quantityOfBom == nil  || item.quantityOfBom == nil) {
                self.idsDeleteDocOutPut.append(item.id ?? "")
            }
        }
        self.arrayData.removeAll(where: { $0.quantityOfBom == nil && $0.quantityPerBom == nil })
        self.sendButton.isUserInteractionEnabled = false
        let image = imageCapture?.resizeWithPercent(percentage: 0.3)?.pngData()
        var isCheckPushImage = false
        if image != nil {
            isCheckPushImage = true
        } else {
            isCheckPushImage = false
        }
        
        var actionType = ""
        var contentToast = ""
        //        actionType
        //        Từ chối: 0
        //        Xác nhận: 1
        //        Đồng ý giám sát: 2
        //        Từ chối giám sát: 3
        //        Cập nhật: 4
        
        switch sender.tag {
        case 0: // 0 reInstall
            
            self.arrayData.removeAll()
            for item in self.dataOrigin {
                let convertData = DocComponentABEs()
                convertData.id = item.id
                convertData.quantityPerBom = item.quantityPerBom
                convertData.quantityOfBom = item.quantityOfBom
                self.arrayData.append(convertData)
            }
            
            var totalValue: Double = 0.0
            for item in self.arrayData {
                if let quantityOfBom = item.quantityOfBom, let quantityPerBom = item.quantityPerBom {
                    totalValue = (quantityOfBom * quantityPerBom) + totalValue
                }
            }
            
            self.valueSumTest = totalValue
            
            actionType = "0"
            contentToast = "Đã từ chối xác nhận kiểm kê linh kiện".localized()
        case 1: // 1 confirm
            actionType = "1"
            contentToast = "Đã xác nhận kiểm kê linh kiện thành công".localized()
        case 2: // 2 update
            actionType = "4"
            contentToast = "Đã cập nhật chi tiết phiếu".localized()
        default:
            break
        }
        
        networkManager.submitTicketCDoc(userCode: UserDefault.shared.getUserID(), comment: self.note, actionType: actionType, inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", documentId: dataTicket.inventoryDoc?.id ?? "", containerModel: arrayData, docTypeCModel: [], image: image ?? Data(), isCheckPushImage: isCheckPushImage, idsDeleteDocOutPut: idsDeleteDocOutPut, completion: { data in
            self.sendButton.isUserInteractionEnabled = true
            switch data {
            case .success(let response):
                if response.code == 200 {
                    let dataResponse: DataResponseSubmit = response.data ?? DataResponseSubmit()
                    self.dataTicket.inventoryDoc?.status = dataResponse.status
                    var totalValue: Double = 0.0
                    for item in self.arrayData {
                        if let quantityOfBom = item.quantityOfBom, let quantityPerBom = item.quantityPerBom {
                            totalValue = (quantityOfBom * quantityPerBom) + totalValue
                        }
                    }
                    self.valueSumTest = totalValue
                    self.isEditPermission = false
                    self.viewBottom.isHidden = true
                    self.tableView.reloadData()
                    self.navigationItem.rightBarButtonItem = nil
                    self.showToast(content: contentToast)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.reloadDataSubmit?()
                        self.navigationController?.popViewController(animated: true)
                    }
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        self.submitTicketDocC(sender: sender)
                    }
                } else if response.code == 400 {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: response.message ?? "",cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
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
    
    private func changeColorButton() {
        let arrayValidate = arrayData
        if arrayValidate.isEmpty {
            self.updateButton.layer.backgroundColor = UIColor(named: R.color.grey1.name)?.cgColor
            self.updateButton.isUserInteractionEnabled = false
            self.confirmButton.layer.backgroundColor = UIColor(named: R.color.grey1.name)?.cgColor
            self.setupColorButton(color: UIColor(named: R.color.textGray.name) ?? .white)
            self.confirmButton.isUserInteractionEnabled = false
            self.successConfirm = false
        } else {
            if !arrayValidate.contains(where: { item in
                item.isCheckBox == false || item.isCheckBox == nil
            }) {
                self.updateButton.layer.backgroundColor = UIColor(named: R.color.greenColor.name)?.cgColor
                self.updateButton.isUserInteractionEnabled = true
                self.confirmButton.layer.backgroundColor = UIColor(named: R.color.greenColor.name)?.cgColor
                self.setupColorButton(color: UIColor(named: R.color.white.name) ?? .white)
                self.confirmButton.isUserInteractionEnabled = true
                self.successConfirm = true
            } else {
                self.updateButton.layer.backgroundColor = UIColor(named: R.color.grey1.name)?.cgColor
                self.updateButton.isUserInteractionEnabled = false
                self.confirmButton.layer.backgroundColor = UIColor(named: R.color.grey1.name)?.cgColor
                self.setupColorButton(color: UIColor(named: R.color.textGray.name) ?? .white)
                self.confirmButton.isUserInteractionEnabled = false
                self.successConfirm = false
            }
        }
        
        // permission confirm edit
        if dataTicket.inventoryDoc?.inventoryBy == UserDefault.shared.getUserID() && isConfirmScan {
            viewBottom.isHidden = true
        }
    }
    private func setupColorButton(color: UIColor) {
        let updateImage = UIImage(named: R.image.ic_update.name)
        let tintedUpdateImage = updateImage?.withRenderingMode(.alwaysTemplate)
        let origImage = UIImage(named: R.image.ic_tick.name)
        let tintedImage = origImage?.withRenderingMode(.alwaysTemplate)
        confirmButton.setImage(tintedImage, for: .normal)
        confirmButton.tintColor = color
        confirmButton.setTitleColor(color, for: .normal)
        
        updateButton.setImage(tintedUpdateImage, for: .normal)
        updateButton.tintColor = color
        updateButton.setTitleColor(color, for: .normal)
        
        reInstallButton.setTitleColor(UIColor(named: note.isEmpty == true ? R.color.textGray.name: R.color.textDefault.name), for: .normal)
        let icDenied = UIImage(named: R.image.ic_close_black.name)
        let tintedImageClose = icDenied?.withRenderingMode(.alwaysTemplate)
        reInstallButton.setImage(tintedImageClose, for: .normal)
        reInstallButton.tintColor =  UIColor(named: note.isEmpty == true ? R.color.textGray.name: R.color.textDefault.name)
        reInstallButton.layer.backgroundColor = UIColor(named: note.isEmpty == true ? R.color.grey1.name : R.color.grey2.name)?.cgColor
        
    }
    
}

extension InventoryDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
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
            cell.delegateAddRow = self
            cell.setDataToCell(model: dataTicket.inventoryDoc, isConfirmScan: isConfirmScan)
            cell.stackAddButton.isHidden = !isEditPermission
            cell.selectionStyle = .none
            cell.onTapQR = { [weak self] in
                guard let self = self else { return }
                self.QRCodeTap()
            }
            return cell
        case .titleInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            return cell
        case .rowInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.invenTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.regionUS = self.regionUS
//            updateCellBackgroundColor(indexPath: indexPath)
            if isConfirmScan {
                cell.setDataToCellMonitor(data: arrayData[indexPath.row],index: indexPath.row, isLast: (arrayData.count - 1) == indexPath.row ? true : false, isHiddenCheckBox: false, isHideTextField: self.dataTicket.inventoryDoc?.status != 6)
                cell.setEditView(isHidden: isEditPermission)
            } else {
                cell.setEditView(isHidden: isEditPermission)
                cell.setDataToCell(data: arrayData[indexPath.row], index: indexPath.row, isLast: (arrayData.count - 1) == indexPath.row ? true : false)
            }
            cell.deleteRow = { (index) in
                self.isShowError = false
                if self.arrayData[index].id != "" && self.arrayData[index].id != nil {
                    self.idsDeleteDocOutPut.append(self.arrayData[index].id ?? "")
                }
                
                self.arrayData.remove(at: index)
                self.changeColorButton()
                
                if self.arrayData.count > 0 {
                    self.tableView.reloadSections(IndexSet(integer: SectionInventory.rowInventory.rawValue), with: .none)
                    self.totalResult()
                } else {
                    self.valueSumTest = 0
                    tableView.reloadData()
                }
            }
            cell.sumTotal = { (index, quantityPerBom, quantityOfBom, isCheckBox) in
                self.isShowError = false
                self.arrayData[index].quantityOfBom = quantityOfBom == "" ? nil : self.unFormatNumber3(stringValue: quantityOfBom)
                self.arrayData[index].quantityPerBom = quantityPerBom == "" ? nil : self.unFormatNumber3(stringValue: quantityPerBom)
                self.arrayData[index].isCheckBox = isCheckBox
                
                var totalValue: Double = 0.0
                for item in self.arrayData {
                    if let quantityOfBom = item.quantityOfBom, let quantityPerBom = item.quantityPerBom {
                        totalValue = (quantityOfBom * quantityPerBom) + totalValue
                    }
                }
                
                self.changeColorButton()
                self.valueSumTest = totalValue
                if self.tableView.indexPathsForVisibleRows?.contains(indexPath) != nil {
                    self.tableView.beginUpdates()
                    self.tableView.reloadSections(IndexSet(integer: SectionInventory.sumInventory.rawValue), with: .none)
                    self.tableView.reloadSections(IndexSet(integer: SectionInventory.errorTable.rawValue), with: .none)
                    self.tableView.endUpdates()
                }
            }
            cell.isCheckMonitor = { index, isCheck in
                self.arrayData[index].isCheckBox = isCheck
                self.changeColorButton()
            }
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
                    self.changeColorButton()
                    self.reInstallButton.isUserInteractionEnabled = self.note.isEmpty != true
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
            return isShowError ? 40 : 0
        default:
            return 60
        }
    }
    
}

extension InventoryDetailViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        if let imageCapture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.imageCapture = imageCapture
            self.evicenceImg = nil
            self.tableView.reloadData()
        }
    }
}

extension InventoryDetailViewController: AddRowCell {
    func addRowCell() {
        addOnTap()
    }
}

extension InventoryDetailViewController: QRInventoryVCProtocol {
    func senDataQR(arrayData: [DocComponentABEs]) {
        if resetInventory {
            for item in self.arrayData {
                idsDeleteDocOutPut.append(item.id ?? "")
            }
        }
        self.arrayData = arrayData
        var totalValue:Double = 0.0
        for item in self.arrayData {
            if let quantityOfBom = item.quantityOfBom, let quantityPerBom = item.quantityPerBom {
                totalValue = (quantityOfBom * quantityPerBom) + totalValue
            }
        }
        
        self.isShowError = false
        self.valueSumTest = totalValue
        self.tableView.reloadData()
    }
}
