//
//  ScanCodeTicketBViewController.swift
//  BIVN
//
//  Created by TinhVan Software on 08/05/2024.
//

import AVFoundation
import UIKit
import Moya
import IQKeyboardManagerSwift
import Localize_Swift

class ScanCodeTicketBViewController: BaseViewController {

    @IBOutlet weak var errorEmptyComponentLabel: UILabel!
    @IBOutlet weak var scanerView: UIView!
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var imageScanView: UIImageView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var heightStackViewContrain: NSLayoutConstraint!
    @IBOutlet weak var desTextField: UITextField!
    @IBOutlet weak var totalCountView: UIView!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var widthFinishCountConstraint: NSLayoutConstraint!
    @IBOutlet weak var inventoryListLabel: UILabel!
    @IBOutlet weak var titleComponentLabel: UILabel!
    @IBOutlet weak var titlePartNumberLabel: UILabel!
    
    
    let networkManager: NetworkManager = NetworkManager()
    var type: TypeRole?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var titleNavi: String?
    var layoutString: String = ""
    @objc public weak var delegate: ScannerViewDelegate?
    var isInventoryScan: Bool = false
    var isMonitorScan: Bool = false
    var isConfirmScan: Bool = false
    var statusInventory: StatusInventory = .Confirmed
    var listDocB = ListDocB()
    var jobIndex : Int = 0
    var model: String?
    var modelCode: String?
    var machineType: String?
    var lineCode: String = ""
    var param = Dictionary<String, Any>()
    var pendingWorkItem: DispatchWorkItem?
    var queen = DispatchQueue(label: "CountQueen")
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupShowUI()
        setupUI()
        timerAction()
        imageScanView.image = UIImage(named: R.image.ic_scan.name)
        disPlayscanerCode()
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        desTextField.delegate = self
        desTextField.backgroundColor = UIColor(named: R.color.grey1.name)
        desTextField.placeholderColor(color: UIColor(named: R.color.textDefault.name)!)
        desTextField.textColor = UIColor(named: R.color.textDefault.name)
        errorEmptyComponentLabel.isHidden = true
        setupFinishCount()
        if jobIndex == 0 {
            inventoryListLabel.text = "Danh sách LK chưa kiểm kê".localized()
        } else {
            isConfirmScan = true
            inventoryListLabel.text = "Danh sách LK chờ xác nhận".localized()
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        inventoryListLabel.isUserInteractionEnabled = true
        inventoryListLabel.addGestureRecognizer(tapGesture)
        inventoryListLabel.underline()
    }
    
    private func setupShowUI() {
        desTextField.placeholder = "Nhập mã linh kiện...".localized()
        sendButton.setTitle("Gửi".localized(), for: .normal)
        titleComponentLabel.text = "Quét mã linh kiện".localized()
        contentLabel.text = "Đưa camera hướng về mã linh kiện".localized()
        titlePartNumberLabel.text = "Nhập mã linh kiện".localized()
        errorEmptyComponentLabel.text = "Vui lòng nhập mã linh kiện.".localized()
    }
    
    func setupFinishCount() {
        if let finishCount = listDocB.finishCount, let totalCount = listDocB.totalCount {
            let percent: Double = Double(finishCount) / Double(totalCount)
            percentLabel.text = "\(finishCount) / \(totalCount)"
            let percentWidth = totalCountView.frame.width
            widthFinishCountConstraint.constant = CGFloat(percent) * percentWidth
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeScanCode()
        self.queen.suspend()
        IQKeyboardManager.shared.isEnabled = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        desTextField.text = ""
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
        IQKeyboardManager.shared.isEnabled = false
        getListDocB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", model: self.model, machineType: self.machineType, lineName: self.lineCode, modelCode: self.modelCode, actionType: self.jobIndex)
    }
    private func getListDocB(inventoryId: String?, accountId: String?, model: String?, machineType: String?, lineName: String?, modelCode: String?, actionType: Int?) {
        param["inventoryId"] = inventoryId ?? ""
        param["accountId"] = accountId ?? ""
        param["machineModel"] = model ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineName ?? ""
        param["actionType"] = actionType ?? 0
        param["stageName"] = ""
        param["modelCode"] = modelCode ?? ""
        param["pageNum"] = 1
        param["pageSize"] = 20
        
        networkManager.getListdocB(param: param) {[weak self] data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self?.listDocB = response.data ?? ListDocB()
                    self?.setupFinishCount()
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self?.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            getListDocB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", model: self.model, machineType: self.machineType, lineName: self.lineCode, modelCode: self.modelCode, actionType: self.jobIndex)
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
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        self.removeScanCode()
        self.queen.suspend()
        guard let vc = Storyboards.accessoryNotInventory.instantiate() as? ListAccessoryNotInventoryViewController else {return}
        if self.jobIndex == 0 {
            vc.listDataDocB = self.listDocB.docBInfoModels?.filter({ $0.status == 2}) ?? []
        } else {
            vc.listDataDocB = self.listDocB.docBInfoModels?.filter({ $0.status == 3}) ?? []
        }
        vc.titleString = self.titleNavi
        vc.model = self.model
        vc.modelCode = self.modelCode
        vc.machineType = self.machineType
        vc.lineCode = self.lineCode
        vc.jobIndex = self.jobIndex
        vc.docType = "B"
        vc.reloadListDocB = { [weak self] listDocB in
            guard let self = self else { return }
            if listDocB.finishCount != nil {
                self.listDocB = listDocB
                setupFinishCount()
            }
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func keyBoardWillShow(notification: Notification){
        if let userInfo = notification.userInfo as? Dictionary<String, AnyObject>{
            let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey]
            let keyBoardRect = frame?.cgRectValue
            if let keyBoardHeight = keyBoardRect?.height {
                self.heightStackViewContrain.constant = keyBoardHeight + 10
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    @objc func keyBoardWillHide(notification: Notification){
        self.heightStackViewContrain.constant = 60.0
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    private func setupUI() {
        self.hideKeyboardWhenTappedAround()
        sendButton.layer.cornerRadius = 4
        sendButton.layer.borderWidth = 1
        sendButton.layer.borderColor = UIColor(named: R.color.buttonBlue.name)?.cgColor
        let yourBackImage = UIImage(named: R.image.ic_back.name)
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.tintColor = UIColor.gray
        self.navigationItem.setHidesBackButton(true, animated: true)
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: #selector(onTapNotification))
        self.navigationItem.leftBarButtonItem = buttonLeft
        self.title = titleNavi
        
        setFontTitleNavBar()
        sendButton.addTarget(self, action: #selector(sendOnTap), for: .touchUpInside)
    }
    
    @objc private func onTapNotification() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func sendOnTap() {
        self.view.endEditing(true)
        let hasSpecialCharacters =  self.desTextField.text?.range(of: ".*[^A-Za-z0-9 ].*", options: .regularExpression) != nil
        if hasSpecialCharacters {
            self.showAlertNoti(title: "Lỗi".localized(), message: "Mã linh kiện không đúng định dạng. Vui lòng thử lại".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap: {
                self.captureSession.startRunning()
            },cancelOnTap: {
                self.captureSession.startRunning()
            })
            return
        }
        
        self.sendButton.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sendButton.isUserInteractionEnabled = true
            if ((self.desTextField.text?.count ?? 0) == 0) {
                self.errorEmptyComponentLabel.isHidden = false
            } else if (self.desTextField.text?.count ?? 0) > 0 {
                self.errorEmptyComponentLabel.isHidden = true
                self.scanDocB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", componentCode: self.desTextField.text ?? "", machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, modelCode: self.modelCode, actionType: self.jobIndex, isErrorInvestigation: false)
            }
        }
    }
    
    private func disPlayscanerCode() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr, .code39]
        } else {
            failed()
            return
        }
        let layer = createScannerGradientLayer(for: animationView)
        animationView.layer.insertSublayer(layer, at: 0)
        let animation = createAnimation(for: layer)
        layer.removeAllAnimations()
        layer.add(animation, forKey: nil)
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = scanerView.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        scanerView.layer.addSublayer(previewLayer)
        captureSession.startRunning()
    }
    
    private func removeScanCode() {
        if (captureSession?.isRunning == true) {
            self.contentLabel.isHidden = true
            captureSession.stopRunning()
        }
    }
    
    private func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    private func timerAction() {
        pendingWorkItem?.cancel()
        let newWork = DispatchWorkItem {
            self.queen.asyncAfter(deadline: .now() + 20, execute: {
                DispatchQueue.main.async {
                    self.showAlertNoti(title: "Thông báo".localized(), message: "Hệ thống không nhận dạng được mã linh kiện. Vui lòng nhập mã linh kiện".localized(), acceptButton: "Đồng ý".localized())
                }
            })
            
        }
        pendingWorkItem = newWork
        queen.async(execute: newWork)
    }
    
    private func requestGetPosition(layout: String, componentCode: String) {
        guard InternetManager.isConnected() else {
            self.showAlerInternet()
            return
        }
        
        let networkManager: NetworkManager = NetworkManager()
        networkManager.getPosition(layout: layout, componentCode: componentCode) { [weak self] result in
            switch result {
            case .success(let response):
                guard let `self` = self else { return }
                if response.code == 200 {
                    var arrayString: [String] = []
                    let responseData = response.data ?? []
                    for item in responseData {
                        arrayString.append(item.positionCode ?? "")
                    }
                    
                    self.removeScanCode()
                    self.queen.suspend()
                    
                    if arrayString.count == 1 {
                        let vc = self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.detailViewController)
                        if self.type == .mc {
                            vc?.type = self.type
                        } else {
                            vc?.typePCB = self.titleNavi
                        }
                        vc?.componentDetailModels = responseData.first?.componentDetails ?? []
                        self.navigationController?.pushViewController(vc!, animated: true)
                    } else {
                        self.contentLabel.isHidden = true
                        self.showPopUpAlert(title: "Chọn vị trí".localized(), array: arrayString) {
                            self.captureSession.startRunning()
                        } accept: { indexValue in
                            let vc = self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.detailViewController)
                            if self.type == .mc {
                                vc?.type = self.type
                            } else {
                                vc?.typePCB = self.titleNavi
                            }
                            vc?.componentDetailModels = responseData[indexValue].componentDetails ?? []
                            self.navigationController?.pushViewController(vc!, animated: true)
                        }
                    }
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.requestGetPosition(layout: layout, componentCode: componentCode)
                        }
                    }
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0), acceptOnTap:  {
                        self.captureSession.startRunning()
                    })
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self?.showAlertConfigTimeOut()
                    }
                }
                print(error.localizedDescription)
                self?.captureSession.startRunning()
            }
        }
    }
    
    // MARK: - Call API ABE Ticket
    var listDataTicket = [DetailResponseDataTicket]()
    private func scanDocB(inventoryId: String?, accountId: String?, componentCode: String?, machineModel: String?, machineType: String?, lineName: String?, modelCode: String?, actionType: Int?, isErrorInvestigation: Bool) {
        param["inventoryId"] = inventoryId ?? ""
        param["accountId"] = accountId ?? ""
        param["componentCode"] = componentCode ?? ""
        param["machineModel"] = machineModel ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineName ?? ""
        param["modelCode"] = modelCode ?? ""
        param["actionType"] = actionType
        param["isErrorInvestigation"] = false

        networkManager.scanDocB(isErrorInvestigation: isErrorInvestigation, param: param) { [weak self] result in
            switch result {
            case .success(let response):
                guard let `self` = self else { return }
                if response.code == 200 {
                    
                    self.removeScanCode()
                    self.queen.suspend()
                    
                    let responseData = response.data ?? []
                    self.listDataTicket = responseData
                    var arrayString = [String]()
                    var arrayStatus = [Int]()
                    
                    for item in self.listDataTicket {
                        arrayString.append(item.inventoryDoc?.positionCode ?? "")
                        if let status = item.inventoryDoc?.status {
                            arrayStatus.append(status)
                        }
                    }
                    
                    if arrayString.count == 1 {
                    //    old status la chua kiem ke
                    //    new status la cho xac nhan
                    //    ma nhan vien trung vs nguoi tao createdBy
                        
                        let listHistory = self.listDataTicket.first?.histories ?? []
                        let inventoryDoc = self.listDataTicket.first?.inventoryDoc
                        
                        var isShowPopupInventory = false
                        for item in listHistory {
                            if self.isConfirmScan {
                                if item.status == 3 || item.status == 5 {
                                    isShowPopupInventory = true
                                }
                            } else {
                                if item.status == 3 || item.status == 5 {
                                    isShowPopupInventory = true
                                }
                            }
                        }
                        //918257159
                        if isShowPopupInventory {
                            if self.jobIndex == 0 {
                                self.showAlertNoti(title: "Thông báo".localized(), message: "Đã được kiểm kê. Bạn có muốn kiểm kê lại không".localized(), cancelButton: "Hủy bỏ", acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                                    self.navigateInventoryDetailVC(dataTicket: self.listDataTicket.first ?? DetailResponseDataTicket(), resetInventory: true)
                                }) {
                                    self.captureSession.startRunning()
                                }
                            } else {
                                if UserDefault.shared.getUserID() == self.listDataTicket.first?.inventoryDoc?.inventoryBy {
                                    self.showAlertNoti(title: "Thông báo".localized(), message: "Bạn không được xác nhận phiếu này".localized(),acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                                        self.captureSession.startRunning()
                                    })
                                } else {
                                    self.navigateInventoryDetailVC(dataTicket: self.listDataTicket.first ?? DetailResponseDataTicket(), resetInventory: false)
                                }
                            }
                        } else {
                            self.navigateInventoryDetailVC(dataTicket: self.listDataTicket.first ?? DetailResponseDataTicket(), resetInventory: false)
                        }
                    } else {
                        // show popup
                        self.showPopUpAlert(title: "Chọn vị trí".localized(), array: arrayString, status: arrayStatus) {
                            self.captureSession.startRunning()
                        } accept: { indexValue in
                            let listHistory = self.listDataTicket[indexValue].histories ?? []
                            let inventoryDoc = self.listDataTicket[indexValue].inventoryDoc
                            
                            var isShowPopupInventory = false
                            for item in listHistory {
                                if self.isConfirmScan {
                                    if item.status == 3 || item.status == 5 {
                                        isShowPopupInventory = true
                                    }
                                } else {
                                    if item.status == 3 || item.status == 5 {
                                        isShowPopupInventory = true
                                    }
                                }
                            }
                            
                            if isShowPopupInventory {
                                if self.jobIndex == 0 {
                                    self.showAlertNoti(title: "Thông báo".localized(), message: "Đã được kiểm kê. Bạn có muốn kiểm kê lại không".localized(), cancelButton: "Hủy bỏ".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                                        // go to detail
                                        self.navigateInventoryDetailVC(dataTicket: self.listDataTicket[indexValue], resetInventory: true)
                                    }) {
                                        self.captureSession.startRunning()
                                    }
                                } else {
                                    if UserDefault.shared.getUserID() == self.listDataTicket.first?.inventoryDoc?.inventoryBy {
                                        self.showAlertNoti(title: "Thông báo".localized(), message: "Bạn không được xác nhận phiếu này".localized(),acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                                            self.captureSession.startRunning()
                                        })
                                    } else {
                                        self.navigateInventoryDetailVC(dataTicket: self.listDataTicket[indexValue], resetInventory: false)
                                    }
                                }
                            } else {
                                self.navigateInventoryDetailVC(dataTicket: self.listDataTicket[indexValue], resetInventory: false)
                            }
                        }
                    }
                    
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.scanDocB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", componentCode: self.desTextField.text ?? "", machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, modelCode: self.modelCode, actionType: self.jobIndex, isErrorInvestigation: false)
                        }
                    }
                } else if response.code == 400 || response.code == 83 {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: response.message ?? "",cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) ,acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0), acceptOnTap: {
                        self.captureSession.startRunning()
                    } ,cancelOnTap:  {
                        self.captureSession.startRunning()
                    })
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0), acceptOnTap: {
                        self.captureSession.startRunning()
                    }, cancelOnTap:  {
                        self.captureSession.startRunning()
                    })
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self?.showAlertConfigTimeOut()
                    }
                }
                self?.captureSession.startRunning()
            }
        }
    }
    
    func navigateInventoryDetailVC(dataTicket: DetailResponseDataTicket, resetInventory: Bool) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "InventoryDetailViewController") as! InventoryDetailViewController
        if let arrHistory = dataTicket.histories {
            for item in arrHistory {
                if item.evicenceImg != nil &&  item.evicenceImg != "" {
                    vc.evicenceImg = item.evicenceImg ?? ""
                    break
                }
            }
        }
        if let data = dataTicket.inventoryDoc, (data.status == 5 || data.status == 4) {
            self.showAlertNoti(title: "Thông báo".localized(), message: "Đã được xác nhận. Bạn có muốn xác nhận lại không".localized(), cancelButton: "Hủy bỏ", acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                vc.dataTicket = dataTicket
                vc.isConfirmScan = self.isConfirmScan
                vc.jobIndex = self.jobIndex
                vc.resetInventory = resetInventory
                self.navigationController?.pushViewController(vc, animated: true)
            }) {
                self.captureSession.startRunning()
            }
        } else {
            vc.dataTicket = dataTicket
            vc.isConfirmScan = self.isConfirmScan
            vc.jobIndex = self.jobIndex
            vc.resetInventory = resetInventory
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

}

extension ScanCodeTicketBViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        errorEmptyComponentLabel.isHidden = true
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength < 21
    }
}

extension ScanCodeTicketBViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
    }
    
    private func found(code: String) {
        var codeResult: String = ""
        codeResult = code
        let occurrencies = codeResult.filter( {$0 == "&"}).count
        if occurrencies > 2 {
            let splits = code.components(separatedBy: "&")
            
            codeResult = splits[3]
        } else {
            let hasSpecialCharacters =  code.range(of: ".*[^A-Za-z0-9 ].*", options: .regularExpression) != nil
            if hasSpecialCharacters {
                self.showAlertNoti(title: "Lỗi".localized(), message: "Mã linh kiện không đúng định dạng. Vui lòng thử lại".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap: {
                    self.captureSession.startRunning()
                },cancelOnTap:  {
                    self.captureSession.startRunning()
                })
                return
            }
        }
        self.scanDocB(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", componentCode: codeResult, machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, modelCode: self.modelCode, actionType: self.jobIndex,isErrorInvestigation: false)
    }
}
