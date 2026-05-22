//
//  ViewController2.swift
//  BIVN
//
//  Created by TVO_M1 on 22/11/2023.
//
import AVFoundation
import UIKit
import Moya
import IQKeyboardManagerSwift
import Localize_Swift

private struct Constant {
    static let widthNotificationView = UIScreen.main.bounds.width * 0.7
}
class ScanUserIDController: BaseViewController {
    
    @IBOutlet weak var navBar: CustomNavBar!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var leaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var blurMenu: UIView!
    @IBOutlet weak var edtUserID: UITextField!
    @IBOutlet weak var txtErrorUserID: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var scanView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scanEmployeeTitleLabel: UILabel!
    @IBOutlet weak var enterEmployeeTitleLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    
    
    
    @IBOutlet weak var icScan: UIImageView!
    @objc public weak var delegate: ScannerViewDelegate?
    
    private var isOpenMenu = false
    private var beginPoint: CGFloat = 0
    private var difference: CGFloat = 0
    var layoutString: String = ""
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var pendingWorkItem: DispatchWorkItem?
    var queen = DispatchQueue(label: "CountQueen")
    var isCheckNavigate: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        setupUI()
        setupSlideMenu()
        navBar.delegate = self
        edtUserID.delegate = self
        edtUserID.autocapitalizationType = .allCharacters
        txtErrorUserID.isHidden = true
        setupNavbar()
        self.hideKeyboardWhenTappedAround()
        
        edtUserID.attributedPlaceholder = NSAttributedString(
            string: "Nhập mã nhân viên...".localized(),
            attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: R.color.textGray.name)]
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        timerAction()
        disPlayscanerCode()
        self.navigationController?.navigationBar.isHidden = true
        IQKeyboardManager.shared.isEnabled = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeScanCode()
        self.queen.suspend()
        IQKeyboardManager.shared.isEnabled = true
    }
    
    private func setupUI() {
        saveButton.setTitle("Lưu".localized(), for: .normal)
        scanEmployeeTitleLabel.text = "Quét mã nhân viên.".localized()
        enterEmployeeTitleLabel.text = "Nhập mã nhân viên".localized()
        contentLabel.text = "Đưa camera hướng về mã nhân viên".localized()
        txtErrorUserID.text = "Vui lòng nhập mã nhân viên.".localized()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
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
    //
    private func setupNavbar(){
        navBar.viewLayoutPosition.isHidden = true
        navBar.userNameLabel.text = UserDefault.shared.getDataLoginModel().username
        navBar.codeNameLabel.text = ""
    }
    
    private func setupSlideMenu() {
        let storyboard = UIStoryboard(name: "InventoryUser", bundle: nil)
        guard let slideMenuVC = storyboard.instantiateViewController(identifier: "SideMenuViewController") as? SideMenuViewController else {
            return
        }
        slideMenuVC.delegate = self
        slideMenuVC.view.frame = menuView.bounds
        menuView.addSubview(slideMenuVC.view)
        addChild(slideMenuVC)
        slideMenuVC.didMove(toParent: self)
        leaddingConstraint.constant = -Constant.widthNotificationView
        blurMenu.isHidden = true
    }
    
    func displayMenu() {
        isOpenMenu.toggle()
        blurMenu.alpha = isOpenMenu ? 0.5 : 0
        blurMenu.isHidden = !isOpenMenu
        UIView.animate(withDuration: 0.2) {
            self.leaddingConstraint.constant = self.isOpenMenu ? 0 : -(UIScreen.main.bounds.width * 0.7)
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func saveAction(_ sender: Any) {
        guard let userID = edtUserID.text, !userID.isEmpty else {
            txtErrorUserID.isHidden = false
            return
        }
        UserDefaults.standard.set(userID, forKey: "MANHANVIEN")
        // kiểm tra mã nhân viên (Loại trừ với trường hợp user giám sát)
        let isMonitor = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryRoleType == UIViewController.monitor || UserDefault.shared.getDataLoginModel().accountType == AccountType.monitoringAccount.rawValue
        if isMonitor || userID.checkUserId() {
            navBar.userNameLabel.text = userID
            UserDefault.shared.setUserID(userID: userID)
            navigateToMain()
        } else {
            self.showAlertNoti(title: "Lỗi".localized(), message: "Mã nhân viên không đúng định dạng. Vui lòng kiểm tra và thao tác lại.".localized(), acceptButton: "Đồng ý".localized())
        }
    }
    
    private func removeScanCode() {
        if (captureSession?.isRunning == true) {
            self.contentLabel.isHidden = true
            captureSession.stopRunning()
        }
    }
    
    private func timerAction() {
        pendingWorkItem?.cancel()
        let newWork = DispatchWorkItem {
            self.queen.asyncAfter(deadline: .now() + 20, execute: {
                DispatchQueue.main.async {
                    self.showAlertNoti(title: "Thông báo".localized(), message: "Hệ thống không nhận dạng được mã nhân viên.Vui lòng nhập mã nhân viên.".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap: {
                        self.timerAction()
                    })
                }
            })
            
        }
        pendingWorkItem = newWork
        
        queen.async(execute: newWork)
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
        previewLayer.frame = scanView.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        scanView.layer.addSublayer(previewLayer)
        captureSession.startRunning()
    }
    
    private func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    private func requestGetPosition(layout: String, componentCode: String) {
        let isMonitor = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryRoleType == UIViewController.monitor || UserDefault.shared.getDataLoginModel().accountType == AccountType.monitoringAccount.rawValue
        if isMonitor || componentCode.checkUserId() {
            UserDefault.shared.setUserID(userID: componentCode)
            navBar.userNameLabel.text = componentCode
            navigateToMain()
        } else {
            self.showAlertNoti(title: "Lỗi".localized(), message: "Mã nhân viên không đúng định dạng. Vui lòng kiểm tra và thao tác lại.".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap: {
                self.captureSession.startRunning()
            })
        }
    }
    
    private func navigateToMain() {
        removeScanCode()
        queen.suspend()
        guard let vc = Storyboards.main.instantiate() as? MainViewController else {return}
        if UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryRoleType == UIViewController.inventory {
            vc.isCheckType = .inventory
        } else if UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryRoleType == UIViewController.monitor {
            vc.isCheckType = .monitor
        } else if UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryRoleType == UIViewController.promote {
            vc.isCheckType = .inventory
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func logoutRequest(userID: [String]) {
        guard InternetManager.isConnected() else {
            self.showAlerInternet()
            return
        }
        
        let networkManager: NetworkManager = NetworkManager()
        var param = Dictionary<String, Any>()
        param["userId"] = UserDefault.shared.getDataLoginModel().userId ?? ""
        networkManager.logoutDeleteRequest(param: param) { [weak self] result in
            switch result {
            case .success(let response):
                guard let `self` = self else { return }
                if response.code == 200 {
                    UserDefaults.standard.removeObject(forKey: "dataLoginModel")
                    UserDefault.shared.setUserID(userID: "")
                    self.navigationController?.popViewController(animated: true)
                    
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        let userId: String = UserDefault.shared.getDataLoginModel().userId ?? ""
                        self.logoutRequest(userID: [userId])
                    }
                } else if response.code == 500 {
                    self.showAlertNoti(title: "Thông báo".localized(), message: "Không nhận được phản hồi từ hệ thống, hãy kiểm tra lại server".localized(), acceptButton: "Thoát".localized(), acceptOnTap: {
                        UserDefaults.standard.removeObject(forKey: "dataLoginModel")
                        UserDefaults.standard.removeObject(forKey: "nameWifi")
                        let vc : LoginViewController = self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.loginViewController.identifier) as! LoginViewController
                        let navigationController = UINavigationController(rootViewController: vc)
                        navigationController.modalTransitionStyle = .crossDissolve
                        navigationController.modalPresentationStyle = .fullScreen
                        self.present(navigationController, animated: true, completion: nil)
                    })
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
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
    
}

extension ScanUserIDController: SideMenuViewControllerDelegate {
    func selectedCell(_ row: Int) {
        // logout
        let userId: String = UserDefault.shared.getDataLoginModel().userId ?? ""
        logoutRequest(userID: [userId])
    }
}

extension ScanUserIDController: NavigationBarProtocol {
    func dropDownAction() {
    }
    
    func menuButtonAction() {
        self.displayMenu()
    }
    
}

extension ScanUserIDController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if isOpenMenu {
            if let touch = touches.first {
                let location = touch.location(in: blurMenu)
                beginPoint = location.x
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if isOpenMenu, let touch = touches.first {
            let location = touch.location(in: blurMenu)
            let differenceFromBeginPoint = beginPoint - location.x
            if differenceFromBeginPoint > 0, differenceFromBeginPoint < Constant.widthNotificationView {
                difference = differenceFromBeginPoint
                leaddingConstraint.constant = -differenceFromBeginPoint
                blurMenu.alpha = 0.5 * (1 - differenceFromBeginPoint / Constant.widthNotificationView)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if isOpenMenu {
            if difference == 0, let touch = touches.first {
                let location = touch.location(in: blurMenu)
                if !menuView.frame.contains(location) {
                    displayNotification(isShown: false)
                }
            } else if difference > Constant.widthNotificationView / 2 {
                displayNotification(isShown: false)
            } else {
                displayNotification(isShown: true)
            }
        }
        difference = 0
    }
    
    private func displayNotification(isShown: Bool) {
        blurMenu.alpha = isShown ? 0.5 : 0
        blurMenu.isHidden = !isShown
        UIView.animate(withDuration: 0.2) {
            self.leaddingConstraint.constant = isShown ? 0 : -Constant.widthNotificationView
            self.view.layoutIfNeeded()
        }
        isOpenMenu = isShown
    }
}

extension ScanUserIDController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        txtErrorUserID.isHidden = true
        let currentString: NSString = textField.text! as NSString
        let newString: NSString =  currentString.replacingCharacters(in: range, with: string) as NSString
        let isMonitor = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryRoleType == UIViewController.monitor || UserDefault.shared.getDataLoginModel().accountType == AccountType.monitoringAccount.rawValue
        if isMonitor {
            return true
        }
        return newString.length <= 8
    }
}

extension ScanUserIDController: AVCaptureMetadataOutputObjectsDelegate {
    
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
        print(code)
        delegate?.didFindScannedText(text: code)
        self.contentLabel.isHidden = true
        self.requestGetPosition(layout: layoutString, componentCode: code)
    }
    
}

