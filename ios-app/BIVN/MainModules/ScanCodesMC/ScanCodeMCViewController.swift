//
//  ScanCodeViewController.swift
//  BIVN
//
//  Created by Luyện Đào on 14/09/2023.
//

import AVFoundation
import UIKit
import Moya
import IQKeyboardManagerSwift
import Localize_Swift

enum StatusInventory: Int {
    case NotYetReceived = 0
    case NoInventory = 1
    case NotYetInventoried = 2
    case WaitForConfirmation = 3
    case NeedEditing = 4
    case Confirmed = 5
    case SupervisionAchieved = 6
    case SupervisionFailed = 7
}


@objc protocol ScannerViewDelegate: AnyObject {
    @objc func didFindScannedText(text: String)
}

class ScanCodeMCViewController: BaseViewController {
    
    @IBOutlet weak var errorEmptyComponentLabel: UILabel!
    @IBOutlet weak var monitorButton: UIButton!
    @IBOutlet weak var scanerView: UIView!
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var imageScanView: UIImageView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var heightStackViewContrain: NSLayoutConstraint!
    @IBOutlet weak var desTextField: UITextField!
    @IBOutlet weak var inventoryListLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titlePartNumberLabel: UILabel!
    @IBOutlet weak var scanCodeTitleLabel: UILabel!
    
    var type: TypeRole?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var titleNavi: String?
    var layoutString: String = ""
    @objc public weak var delegate: ScannerViewDelegate?
    var isInventoryScan: Bool = false
    var isMonitorScan: Bool = false
    var isConfirmScan: Bool = false
    var isHiddenMonitorView: Bool = true
    var isHidenListInventory: Bool = true
    var statusInventory: StatusInventory = .Confirmed
    var jobIndex = 0
    var documentId: String?
    var pendingWorkItem: DispatchWorkItem?
    var queen = DispatchQueue(label: "CountQueen")
    var code: String?
    var isKeyboardVisible: Bool = false
    var activeTextField: UITextField?
    var isNavigating = false

    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        IQKeyboardManager.shared.isEnabled = false
        setupUI()
        timerAction()
        imageScanView.image = UIImage(named: R.image.ic_scan.name)
        disPlayscanerCode()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        desTextField.delegate = self
        desTextField.backgroundColor = UIColor(named: R.color.grey1.name)
        desTextField.placeholderColor(color: UIColor(named: R.color.textDefault.name)!)
        desTextField.textColor = UIColor(named: R.color.textDefault.name)
        errorEmptyComponentLabel.isHidden = true
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.isEnabled = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.isEnabled = false
        isNavigating = false
        self.sendButton.isUserInteractionEnabled = true
        desTextField.text = ""
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        scrollView.scrollIndicatorInsets = scrollView.contentInset
    }

    @objc func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    
    private func setupUI() {
        self.hideKeyboardWhenTappedAround()
        type = UserDefault.shared.getDataLoginModel().mobileAccess == TypeRole.mc.value ? .mc : .pcb
        desTextField.placeholder = "Nhập mã linh kiện...".localized()
        scanCodeTitleLabel.text = "Quét mã linh kiện".localized()
        errorEmptyComponentLabel.text = "Vui lòng nhập mã linh kiện.".localized()
        titlePartNumberLabel.text = "Nhập mã linh kiện".localized()
        contentLabel.text = "Đưa camera hướng về mã linh kiện".localized()
        sendButton.setTitle("Gửi".localized(), for: .normal)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: fontUtils.size14.medium,
        ]
        let attributedText = NSAttributedString(string: "Danh sách phiếu cần giám sát".localized(), attributes: attributes)
        monitorButton.setAttributedTitle(attributedText, for: .normal)
        monitorButton.isHidden = isHiddenMonitorView
        inventoryListLabel.isHidden = isHidenListInventory
        if jobIndex == 0 {
            inventoryListLabel.text = "Danh sách LK chưa kiểm kê".localized()
        } else {
            inventoryListLabel.text = "Danh sách LK chờ xác nhận".localized()
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        inventoryListLabel.isUserInteractionEnabled = true
        inventoryListLabel.addGestureRecognizer(tapGesture)
        inventoryListLabel.underline()
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
        desTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let vc = Storyboards.accessoryNotInventory.instantiate() as? ListAccessoryNotInventoryViewController else {return}
        vc.titleString = UserDefault.shared.getUserID()
        vc.docType = "AE"
        if isConfirmScan {
            vc.jobIndex = 1
        } else {
            vc.jobIndex = 0
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func onTapNotification() {
        navigationController?.popViewController(animated: true)
    }
    
    private func resetNavigationState() {
        DispatchQueue.main.async {
            self.isNavigating = false
            self.sendButton.isUserInteractionEnabled = true
        }
    }
    
    @objc private func sendOnTap() {
        guard !isNavigating else { return }
        guard sendButton.isUserInteractionEnabled else { return }
        isNavigating = true
        sendButton.isUserInteractionEnabled = false
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else {return}
            if ((self.desTextField.text?.count ?? 0) == 0) {
                self.errorEmptyComponentLabel.isHidden = false
                self.resetNavigationState()
            } else if (self.desTextField.text?.count ?? 0) > 0 {
                self.errorEmptyComponentLabel.isHidden = true
                if self.isInventoryScan {
                    self.getDetailTicket(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", componentCode: self.desTextField.text ?? "", isConfirm: false)
                } else if self.isMonitorScan {
                    self.getDetailMonitor(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", componentCode: self.desTextField.text ?? "")
                } else if self.isConfirmScan {
                    self.getDetailTicket(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", componentCode: self.desTextField.text ?? "", isConfirm: true)
                } else {
                    self.requestGetPosition(layout: self.layoutString, componentCode: self.desTextField.text ?? "")
                }
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
        self.startLoading()
        guard InternetManager.isConnected() else {
            self.showAlerInternet()
            return
        }
        
        let networkManager: NetworkManager = NetworkManager()
        networkManager.getPosition(layout: layout, componentCode: componentCode) { [weak self] result in
            switch result {
            case .success(let response):
                guard let `self` = self else { return }
                self.stopLoading()
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
                        self.requestGetPosition(layout: layoutString, componentCode: self.code ?? "")
                    }
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
                print(error.localizedDescription)
                self?.captureSession.startRunning()
            }
        }
    }
    
    // MARK: - Call API ABE Ticket
    var listDataTicket = [DetailResponseDataTicket]()
    private func getDetailTicket(inventoryId: String, accountId: String, componentCode: String, isConfirm: Bool) {
        guard InternetManager.isConnected() else {
            self.showAlerInternet()
            return
        }
        self.startLoading()
        var param = Dictionary<String, Any>()
        param["positionCode"] = ""
        param["docCode"] = ""
        param["isErrorInvestigation"] = "false"

        let networkManager: NetworkManager = NetworkManager()
        networkManager.getDetailTicket(inventoryId: inventoryId, accountId: accountId, componentCode: componentCode, isConfirm: isConfirm, param: param) { [weak self] result in
            switch result {
            case .success(let response):
                self?.stopLoading()
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
                            if jobIndex == 0 {
                                if self.listDataTicket.first?.inventoryDoc?.status ?? 0 >= 3 {
                                    self.showAlertNoti(title: "Thông báo".localized(), message: "Đã được kiểm kê. Bạn có muốn kiểm kê lại không".localized(), cancelButton: "Hủy bỏ".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                                        self.navigateInventoryDetailVC(dataTicket: self.listDataTicket.first ?? DetailResponseDataTicket(), resetInventory: true)
                                    }) {
                                        self.captureSession.startRunning()
                                    }
                                }
                            } else {
                                print(self.listDataTicket.first?.inventoryDoc?.status ?? 0)
                                if self.listDataTicket.first?.inventoryDoc?.status ?? 0 >= 5 {
                                    self.showAlertNoti(title: "Thông báo".localized(), message: "Đã được xác nhận. Bạn có muốn xác nhận lại không".localized(), cancelButton: "Hủy bỏ".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                                        self.navigateInventoryDetailVC(dataTicket: self.listDataTicket.first ?? DetailResponseDataTicket(), resetInventory: false)
                                    }) {
                                        self.captureSession.startRunning()
                                    }
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
                            self.handleSelectedTicket(indexValue: indexValue)
                        }
                    }
                    
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.recursiveData(inventoryId: inventoryId, accountId: accountId, componentCode: componentCode, isConfirm: isConfirm, code: response.code)
                } else if response.code == 400 {
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
                print(error.localizedDescription)
                self?.captureSession.startRunning()
            }
        }
    }

    private func shouldShowPopupInventory(ticket: DetailResponseDataTicket) -> Bool {
        let histories = ticket.histories ?? []
        return histories.contains { $0.status == 3 || $0.status == 5 }
    }

    private func handleSelectedTicket(indexValue: Int) {
        guard self.listDataTicket.indices.contains(indexValue) else { return }
        let selectedTicket = self.listDataTicket[indexValue]

        if shouldShowPopupInventory(ticket: selectedTicket) {
            if self.jobIndex == 0 {
                self.showAlertNoti(title: "Thông báo".localized(), message: "Đã được kiểm kê. Bạn có muốn kiểm kê lại không".localized(), cancelButton: "Hủy bỏ".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                    self.navigateInventoryDetailVC(dataTicket: selectedTicket, resetInventory: true)
                }) {
                    self.captureSession.startRunning()
                }
            } else {
                if UserDefault.shared.getUserID() == selectedTicket.inventoryDoc?.inventoryBy {
                    self.showAlertNoti(title: "Thông báo".localized(), message: "Bạn không được xác nhận phiếu này".localized(),acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                        self.captureSession.startRunning()
                    })
                } else {
                    self.navigateInventoryDetailVC(dataTicket: selectedTicket, resetInventory: false)
                }
            }
        } else {
            self.navigateInventoryDetailVC(dataTicket: selectedTicket, resetInventory: false)
        }
    }
    
    func navigateInventoryDetailVC(dataTicket: DetailResponseDataTicket, resetInventory: Bool) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.inventoryDetailViewController)
        if let arrHistory = dataTicket.histories {
            for item in arrHistory {
                if item.evicenceImg != nil && item.evicenceImg != "" {
                    vc?.evicenceImg = item.evicenceImg ?? ""
                    break
                }
            }
        }
        vc?.dataTicket = dataTicket
        vc?.isConfirmScan = self.isConfirmScan
        vc?.jobIndex = self.jobIndex
        vc?.resetInventory = resetInventory
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    private func callApiDetailMonitor(documentId: String, assignedAccountId: String? = nil) {
        self.startLoading()
        self.documentId = documentId
        let networkManager: NetworkManager = NetworkManager()
        networkManager.getDetailSheetsMonitor(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", documentId: documentId, actionType: 2) {data in
            switch data {
            case .success(let response):
                self.stopLoading()
                if response.code == 200 {
                    if response.data?.status == StatusInventory(rawValue: 2)?.rawValue {
                        self.showAlertNoti(title: "Lỗi".localized(), message: "Mã linh kiện này chưa được thực hiện kiểm kê. Vui lòng thử lại".localized(), acceptButton: "Đồng ý".localized())
                    } else if response.data?.status == StatusInventory(rawValue: 3)?.rawValue || response.data?.status == StatusInventory(rawValue: 4)?.rawValue {
                        self.showAlertNoti(title: "Lỗi".localized(), message: "Mã linh kiện này chưa được thực hiện xác nhận kiểm kê. Vui lòng thử lại".localized(), acceptButton: "Đồng ý".localized())
                    }
                    self.removeScanCode()
                    self.queen.suspend()
                    guard let vc = Storyboards.acctionInventory.instantiate() as? ActionInventoryViewController else {return}
//                    // If sheet is free (no assigned account) and someone else already monitored it,
//                    // show specific message and resume scanning.
//                    let currentUser = UserDefault.shared.getUserID()
//                    let isFreeSheet = (assignedAccountId ?? "").isEmpty
//                    if isFreeSheet, let histories = response.data?.docHistories {
//                        if histories.contains(where: { $0.status == StatusInventory.SupervisionAchieved.rawValue && ($0.createdBy ?? "") != currentUser }) {
//                            self.showAlertNoti(title: "Thông báo".localized(), message: "Linh kiện người khác đã giám sát".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap: {
//                                self.captureSession.startRunning()
//                            })
//                            return
//                        }
//                    }

                    if response.data?.status == 6 {
                        self.showAlertNoti(title: "Thông báo".localized(), message: "Đã được giám sát. Bạn có muốn xem lại thông tin giám sát không".localized(), cancelButton: "Hủy bỏ".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                            vc.documentId = documentId
                            vc.dataDetailSheets = response.data
                            vc.dataHistory = response.data?.docHistories ?? []
                            vc.arrayData = response.data?.docComponentABEs ?? []
                            vc.titleNav = response.data?.docCode ?? ""
                            self.navigationController?.pushViewController(vc, animated: true)
                        }) {
                            self.captureSession.startRunning()
                        }

                    } else {
                        vc.documentId = documentId
                        vc.dataDetailSheets = response.data
                        vc.dataHistory = response.data?.docHistories ?? []
                        vc.arrayData = response.data?.docComponentABEs ?? []
                        vc.titleNav = response.data?.docCode ?? ""
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        self.callApiDetailMonitor(documentId: self.documentId ?? "")
                    }
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
                        self.showAlertConfigTimeOut()
                    }
                }
                print(error.localizedDescription)
                self.captureSession.startRunning()
            }
        }
    }
    
    private func getDetailMonitor(inventoryId: String, accountId: String, componentCode: String) {
        self.startLoading()
        var listData = [AuditInfoModels()]
        guard InternetManager.isConnected() else {
            self.showAlerInternet()
            return
        }
        
        let networkManager: NetworkManager = NetworkManager()
        networkManager.getDetailMonitor(inventoryId: inventoryId, accountId: accountId, componentCode: componentCode) { [weak self] result in
            switch result {
            case .success(let response):
                guard let `self` = self else { return }
                self.stopLoading()
                if response.code == 200 {
                    let responseData = response.data ?? []
                    listData = responseData
                    var arrayString = [String]()
                    var arrayStatus = [Int]()
                    
                    for item in listData {
                        arrayString.append(item.positionCode ?? "")
                        if let status = item.status {
                            arrayStatus.append(status)
                        }
                    }
                    
                    if listData.count == 1 {
//                        // If this audit item is assigned to another account, inform the user.
//                        let assignedAccountId = listData.first?.accountId ?? ""
//                        let currentAccountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? ""
//                        if !assignedAccountId.isEmpty && assignedAccountId != currentAccountId {
//                            self.showAlertNoti(title: "Thông báo".localized(), message: "Linh kiện thuộc danh sách giám sát của người khác".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap: {
//                                self.captureSession.startRunning()
//                            })
//                        } else {
//                            self.callApiDetailMonitor(documentId: listData.first?.id ?? "", assignedAccountId: assignedAccountId)
//                        }
                        self.callApiDetailMonitor(documentId: listData.first?.id ?? "")
                    } else {
//                        self.showPopUpAlert(title: "Chọn vị trí".localized(), array: arrayString, status: arrayStatus) {
//                            self.captureSession.startRunning()
//                        } accept: { indexValue in
//                            let assignedAccountId = listData[indexValue].accountId ?? ""
//                            let currentAccountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? ""
//                            if !assignedAccountId.isEmpty && assignedAccountId != currentAccountId {
//                                self.showAlertNoti(title: "Thông báo".localized(), message: "Linh kiện thuộc danh sách giám sát của người khác".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap: {
//                                    self.captureSession.startRunning()
//                                })
//                            } else {
//                                self.callApiDetailMonitor(documentId: listData[indexValue].id ?? "", assignedAccountId: assignedAccountId)
//                            }
//                        }
                        self.showPopUpAlert(title: "Chọn vị trí".localized(), array: arrayString, status: arrayStatus) {
                              self.captureSession.startRunning()
                        } accept: { indexValue in
                            self.callApiDetailMonitor(documentId: listData[indexValue].id ?? "")
                        }
                    }
                    
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.recursiveData(inventoryId: inventoryId, accountId: accountId, componentCode: componentCode, isConfirm: false, code: response.code)
                } else  {
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
                print(error.localizedDescription)
                self?.captureSession.startRunning()
            }
        }
    }
    
    func recursiveData(inventoryId: String, accountId: String, componentCode: String, isConfirm: Bool, code: Int?) {
        self.showAlertExpiredToken(code: code) { [weak self] result in
            guard let self = self else {return}
            getDetailTicket(inventoryId: inventoryId, accountId: accountId, componentCode: componentCode, isConfirm: isConfirm)
        }
    }
    
    @IBAction func onTapListMOnitor(_sender: UIButton) {
        
        self.removeScanCode()
        self.queen.suspend()
        
        let vc = Storyboards.filterInventory.instantiate() as? FilterMonitorSheetsViewController
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
}

extension ScanCodeMCViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // Ẩn bàn phím khi nhấn "Return"
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        errorEmptyComponentLabel.isHidden = true
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength < 21 // Giới hạn 20 ký tự
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("TextField did begin editing: \(textField)")
        activeTextField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("TextField did end editing: \(textField)")
        activeTextField = nil
    }
}

extension ScanCodeMCViewController: AVCaptureMetadataOutputObjectsDelegate {
    
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
        if self.isInventoryScan {
            self.getDetailTicket(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", componentCode: codeResult, isConfirm: false)
        } else if self.isMonitorScan {
            self.getDetailMonitor(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", componentCode: codeResult)
        } else if self.isConfirmScan {
            self.getDetailTicket(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", componentCode: codeResult, isConfirm: true)
        } else {
            delegate?.didFindScannedText(text: code)
            self.contentLabel.isHidden = true
            self.requestGetPosition(layout: layoutString, componentCode: codeResult)
        }
    }
    
}
