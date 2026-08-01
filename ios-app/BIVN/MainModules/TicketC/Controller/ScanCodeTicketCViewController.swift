//
//  ScanCodeTicketCViewController.swift
//  BIVN
//
//  Created by TinhVan Software on 08/05/2024.
//

import AVFoundation
import UIKit
import Moya
import IQKeyboardManagerSwift
import Localize_Swift

class ScanCodeTicketCViewController: BaseViewController {//
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var errorEmptyComponentLabel: UILabel!
    @IBOutlet weak var scanerView: UIView!
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var imageScanView: UIImageView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var heightStackViewContrain: NSLayoutConstraint!
    @IBOutlet weak var scannerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scannerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageScanViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageScanViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var animationViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var animationViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var stageNameTextField: UITextField!
    @IBOutlet weak var virtualClusterNameTextField: UITextField!
    @IBOutlet weak var totalCountView: UIView!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var widthFinishCountConstraint: NSLayoutConstraint!
    @IBOutlet weak var inventoryListLabel: UILabel!
    private var defaultBottomSpacing: CGFloat = 20.0
    
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
    var model: String?
    var machineType: String?
    var machineModel: String?
    var lineCode: String?
    var lineName: String?
    var param = Dictionary<String, Any>()
    var pendingWorkItem: DispatchWorkItem?
    var queen = DispatchQueue(label: "CountQueen")
    var jobIndex : Int = 0
    var currentUserID = ""
    var listDocC = ArrayData()
    var isCheckAcpecticket: Bool = false
    var isCheckBallotC: Bool = false
    var code: String?
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        timerAction()
        imageScanView.image = UIImage(named: R.image.ic_scan.name)
        disPlayscanerCode()
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        stageNameTextField.delegate = self
        stageNameTextField.placeholder = "Tên công đoạn".localized()
        virtualClusterNameTextField.placeholder = "Tên cụm ảo".localized()
        titleLabel.text = "Quét mã cụm".localized()
        sendButton.setTitle("Gửi".localized(), for: .normal)
        stageNameTextField.backgroundColor = UIColor(named: R.color.grey1.name)
        stageNameTextField.placeholderColor(color: UIColor(named: R.color.textDefault.name)!)
        stageNameTextField.textColor = UIColor(named: R.color.textDefault.name)
        
        virtualClusterNameTextField.delegate = self
        virtualClusterNameTextField.backgroundColor = UIColor(named: R.color.grey1.name)
        virtualClusterNameTextField.placeholderColor(color: UIColor(named: R.color.textDefault.name)!)
        virtualClusterNameTextField.textColor = UIColor(named: R.color.textDefault.name)
        
        errorEmptyComponentLabel.isHidden = true
        errorEmptyComponentLabel.text = "Vui lòng nhập tên cụm ảo.".localized()
        contentLabel.text = "Đưa camera hướng về mã linh kiện".localized()
        inventoryListLabel.numberOfLines = 0
        inventoryListLabel.textAlignment = .center
        defaultBottomSpacing = heightStackViewContrain.constant
        adjustLayoutForSmallScreen()
        setupFinishCount()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = scanerView.bounds
    }
    
    func setupFinishCount() {
        if let finishCount = listDocC.finishCount, let totalCount = listDocC.totalCount {
            let percent: Double = Double(finishCount) / Double(totalCount)
            percentLabel.text = "\(finishCount) / \(totalCount)"
            let percentWidth = totalCountView.frame.width
            widthFinishCountConstraint.constant = CGFloat(percent) * percentWidth
        }
    }

    private func adjustLayoutForSmallScreen() {
        let screenHeight = UIScreen.main.bounds.height
        let isCompactScreen = screenHeight <= 736

        if isCompactScreen {
            applyScanAreaSize(220)
            contentLabel.numberOfLines = 2
            contentLabel.font = UIFont.systemFont(ofSize: 13)
            titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
            sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            stageNameTextField.font = UIFont.systemFont(ofSize: 13)
            virtualClusterNameTextField.font = UIFont.systemFont(ofSize: 13)
            inventoryListLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            inventoryListLabel.numberOfLines = 2
        }
    }

    private func applyScanAreaSize(_ size: CGFloat) {
        scannerViewHeightConstraint.constant = size
        scannerViewWidthConstraint.constant = size
        imageScanViewHeightConstraint.constant = size
        imageScanViewWidthConstraint.constant = size
        animationViewHeightConstraint.constant = size
        animationViewWidthConstraint.constant = size
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeScanCode()
        self.queen.suspend()
        IQKeyboardManager.shared.isEnabled = true
        currentUserID = UserDefault.shared.getUserID()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentUserID = UserDefault.shared.getUserID()
        stageNameTextField.text = ""
        virtualClusterNameTextField.text = ""
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
        IQKeyboardManager.shared.isEnabled = false
        getListDocC(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, stageName: "", modelCode: "", actionType: self.jobIndex)
    }
    
    @objc func keyBoardWillShow(notification: Notification){
        if let userInfo = notification.userInfo as? Dictionary<String, AnyObject>{
            let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey]
            let keyBoardRect = frame?.cgRectValue
            if let keyBoardHeight = keyBoardRect?.height {
                self.heightStackViewContrain.constant = defaultBottomSpacing + keyBoardHeight + 10
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    @objc func keyBoardWillHide(notification: Notification){
        self.heightStackViewContrain.constant = defaultBottomSpacing
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    private func setupUI() {
        self.hideKeyboardWhenTappedAround()
        sendButton.layer.cornerRadius = 4
        sendButton.layer.borderWidth = 1
        sendButton.layer.borderColor = UIColor(named: R.color.buttonBlue.name)?.cgColor
        if jobIndex == 0 {
            inventoryListLabel.text = "Danh sách phiếu chưa kiểm kê".localized()
        } else if jobIndex == 2 {
            inventoryListLabel.text = "Danh sách phiếu cần giám sát".localized()
            titleLabel.text = "Quét mã cụm giám sát".localized()
        } else {
            isConfirmScan = true
            inventoryListLabel.text = "Danh sách phiếu chờ xác nhận".localized()
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        inventoryListLabel.isUserInteractionEnabled = true
        inventoryListLabel.addGestureRecognizer(tapGesture)
        inventoryListLabel.underline()
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
    
    private func getListDocC(inventoryId: String?, accountId: String?, machineModel: String?, machineType: String?, lineName: String?, stageName: String?, modelCode: String?, actionType: Int?) {
        param["inventoryId"] = inventoryId ?? ""
        param["accountId"] = accountId ?? ""
        param["machineModel"] = machineModel ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineName ?? ""
        param["actionType"] = actionType ?? 0
        param["stageName"] = stageName ?? ""
        param["modelCode"] = modelCode ?? ""
        param["pageNum"] = 1
        param["pageSize"] = 20

        networkManager.scanListDocC(param: param) { [weak self] result in
            switch result {
            case .success(let response):
                guard let `self` = self else { return }
                if response.code == 200 {
                    self.listDocC = response.data ?? ArrayData()
                    self.setupFinishCount()
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            getListDocC(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, stageName: "", modelCode: "", actionType: self.jobIndex)
                        }
                    }
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
            vc.listDataDocC = self.listDocC.docCInfoModels?.filter({ $0.status == 2}) ?? []
            print(self.listDocC.docCInfoModels?.filter({ $0.status == 2}) ?? [].count)
        } else if self.jobIndex == 2 {
            vc.listDataDocC = self.listDocC.docCInfoModels?.filter({ ($0.status ?? 0) >= 5 }) ?? []
        } else {
            vc.listDataDocC = self.listDocC.docCInfoModels?.filter({ $0.status == 3}) ?? []
        }
        vc.titleString = self.titleNavi
        vc.model = self.model
        vc.machineType = self.machineType
        vc.lineCode = self.lineCode ?? ""
        vc.jobIndex = self.jobIndex
        vc.docType = "C"
        vc.reloadListDocC = { [weak self] listDocC in
            guard let self = self else { return }
            if listDocC.finishCount != nil {
                self.listDocC = listDocC
                setupFinishCount()
            }
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func sendOnTap() {
        self.view.endEditing(true)
        let hasSpecialCharacters =  self.virtualClusterNameTextField.text?.range(of: ".*[^A-Za-z0-9 ].*", options: .regularExpression) != nil
        if hasSpecialCharacters {
            self.showAlertNoti(title: "Lỗi".localized(), message: "Tên cụm không đúng định dạng. Vui lòng thử lại.".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap: {
                self.captureSession.startRunning()
            },cancelOnTap: {
                self.captureSession.startRunning()
            })
            return
        }

        self.sendButton.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sendButton.isUserInteractionEnabled = true
            if ((self.virtualClusterNameTextField.text?.count ?? 0) == 0) {
                self.errorEmptyComponentLabel.isHidden = false
            } else if (self.virtualClusterNameTextField.text?.count ?? 0) > 0 {
                self.errorEmptyComponentLabel.isHidden = true
                self.scanListDocC(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, stageName: self.stageNameTextField.text ?? "", modelCode: self.virtualClusterNameTextField.text ?? "", actionType: self.jobIndex)
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
                    }) {
                    }
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
    private func scanListDocC(inventoryId: String?, accountId: String?, machineModel: String?, machineType: String?, lineName: String?, stageName: String?, modelCode: String?, actionType: Int?) {
        param["inventoryId"] = inventoryId ?? ""
        param["accountId"] = accountId ?? ""
        param["machineModel"] = machineModel ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineName ?? ""
        param["actionType"] = actionType
        param["stageName"] = stageName ?? ""
        param["modelCode"] = modelCode ?? ""
        
        networkManager.scanListDocC(param: param) { [weak self] result in
            switch result {
            case .success(let response):
                guard let `self` = self else { return }
                isCheckBallotC = false
                if response.code == 200 {
                    self.removeScanCode()
                    self.queen.suspend()
                    let listDocC = response.data?.docCInfoModels
                    for item in listDocC ?? [] {
                        if item.status == 5 || item.status == 4  {
                            isCheckAcpecticket = true
                            isCheckBallotC = true
                        }
                        if item.status == 3 {
                            isCheckBallotC = true
                            isCheckAcpecticket = false
                        }
                    }
                    if listDocC?.count ?? 0 > 1 {
                        guard let vc = Storyboards.accessoryNotInventory.instantiate() as? ListAccessoryNotInventoryViewController else {return}
                        if self.jobIndex == 2 {
                            vc.listDataDocC = (listDocC ?? []).filter({ ($0.status ?? 0) >= 5 })
                        } else {
                            vc.listDataDocC = listDocC ?? []
                        }
                        vc.titleString = self.titleNavi
                        vc.model = self.model
                        vc.machineType = self.machineType
                        vc.lineCode = self.lineCode ?? ""
                        vc.jobIndex = self.jobIndex
                        vc.docType = "C"
                        self.navigationController?.pushViewController(vc, animated: true)
                    } else if listDocC?.count ?? 0 == 1 {
                        if self.jobIndex == 0 {
                            if isCheckBallotC {
                                self.showAlertNoti(title: "Thông báo".localized(), message: "Đã được kiểm kê. Bạn có muốn kiểm kê lại không".localized(), cancelButton: "Hủy bỏ", acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                                    self.naviShowDetailDocC(docCInfoModels: listDocC?.first ?? DocCInfoModels())
                                }) {
                                    self.captureSession.startRunning()
                                }
                            } else {
                                naviShowDetailDocC(docCInfoModels: listDocC?.first ?? DocCInfoModels())
                            }
                        } else if self.jobIndex == 2 {
                            let status = listDocC?.first?.status ?? 0
                            if status == 2 {
                                self.showAlertError(title: "Lỗi".localized(), message: "Công đoạn này chưa được thực hiện kiểm kê. Vui lòng thử lại".localized(), titleButton: "Đồng ý".localized())
                            } else if status == 3 || status == 4 {
                                self.showAlertError(title: "Lỗi".localized(), message: "Công đoạn này chưa được thực hiện xác nhận kiểm kê. Vui lòng thử lại".localized(), titleButton: "Đồng ý".localized())
                            } else if status == 6 {
                                self.showAlertNoti(title: "Thông báo".localized(), message: "Đã được giám sát. Bạn có muốn giám sát lại không".localized(), cancelButton: "Hủy bỏ", acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                                    self.naviShowDetailDocC(docCInfoModels: listDocC?.first ?? DocCInfoModels())
                                }) {
                                    self.captureSession.startRunning()
                                }
                            } else {
                                naviShowDetailDocC(docCInfoModels: listDocC?.first ?? DocCInfoModels())
                            }
                        } else {
                            if isCheckAcpecticket {
                                self.showAlertNoti(title: "Thông báo".localized(), message: "Đã được xác nhận. Bạn có muốn xác nhận lại không".localized(), cancelButton: "Hủy bỏ", acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                                    self.naviShowDetailDocC(docCInfoModels: listDocC?.first ?? DocCInfoModels())
                                }) {
                                    self.captureSession.startRunning()
                                }
                            } else {
                                naviShowDetailDocC(docCInfoModels: listDocC?.first ?? DocCInfoModels())
                            }
                        }
                    }
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        self.scanListDocC(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, stageName: "", modelCode: self.code, actionType: self.jobIndex)
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
                self?.captureSession.startRunning()
            }
        }
    }
    
    func naviShowDetailDocC(docCInfoModels: DocCInfoModels) {
        if jobIndex == 0 {
            if docCInfoModels.confirmedBy == currentUserID {
                guard let vc = Storyboards.waitConfirmationC.instantiate() as? WaitConfirmationViewController else {return}
                vc.documentId = docCInfoModels.id ?? ""
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                guard let vc = storyboard?.instantiateViewController(withIdentifier: R.storyboard.ticketC.ballotCountViewController) else {return}
                title = ""
                vc.documentId = docCInfoModels.id
                vc.viewController = 0
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else if jobIndex == 2 {
            if (docCInfoModels.status ?? 0) < 5 {
                self.showAlertError(title: "Lỗi".localized(), message: "Công đoạn này chưa được thực hiện xác nhận kiểm kê. Vui lòng thử lại".localized(), titleButton: "Đồng ý".localized())
                return
            }
            if (docCInfoModels.status ?? 0) != 5 && (docCInfoModels.status ?? 0) != 6 && (docCInfoModels.status ?? 0) != 7 {
                self.showAlertError(title: "Lỗi".localized(), message: "Công đoạn này không nằm trong danh sách giám sát. Vui lòng thử lại".localized(), titleButton: "Đồng ý".localized())
                return
            }
            guard let vc = storyboard?.instantiateViewController(withIdentifier: R.storyboard.ticketC.ballotCountViewController) else {return}
            title = ""
            vc.documentId = docCInfoModels.id
            vc.viewController = 2
            vc.isMonitorMode = true
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            if docCInfoModels.status ?? 0 > 2 {
                if docCInfoModels.inventoryBy == currentUserID {
                    guard let vc = Storyboards.waitConfirmationC.instantiate() as? WaitConfirmationViewController else {return}
                    vc.isBackThreeSeconds = false
                    vc.documentId = docCInfoModels.id ?? ""
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let vc = Storyboards.AccepticketC.instantiate() as! AccepticketCController
                    title = ""
                    vc.documentId = docCInfoModels.id
                    vc.returnScreenType = 0
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                self.showAlertError(title: "Lỗi".localized(), message: "Công đoạn này chưa được thực hiện kiểm kê. Vui lòng thử lại".localized(), titleButton: "Đồng ý".localized())
            }
        }
    }
}

extension ScanCodeTicketCViewController: UITextFieldDelegate {
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

extension ScanCodeTicketCViewController: AVCaptureMetadataOutputObjectsDelegate {
    
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
        self.scanListDocC(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", machineModel: self.model, machineType: self.machineType, lineName: self.lineCode, stageName: "", modelCode: codeResult, actionType: self.jobIndex)
    }
}
