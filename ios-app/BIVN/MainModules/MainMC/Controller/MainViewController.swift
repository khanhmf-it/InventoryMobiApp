//
//  ViewController.swift
//  BIVN
//
//  Created by Tinhvan on 11/09/2023.
//

import UIKit
import Moya
import Localize_Swift

private struct Constant {
    static let widthNotificationView = UIScreen.main.bounds.width * 0.7
}

class MainViewController: BaseViewController {
    @IBOutlet weak var navBar: CustomNavBar!
    
    @IBOutlet weak var menuViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var blurMenuView: UIView!
    @IBOutlet private var menuView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var isCheckType: TypeRole?
    private var isOpenMenu = false
    private var beginPoint: CGFloat = 0
    private var difference: CGFloat = 0
    private var dataStorage = [DataStorageModel]()
    private var dataDocType: DocTypeModel? = nil
    private var indexChooseStorage = 0
        
    let networkManager: NetworkManager = NetworkManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSlideMenu()
        setupView()
    }
    
    private func getData(){
        if isCheckType == .pcb || isCheckType == .mc {
            getStorageRequest()
        }
        else {
            getDocType()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getData()
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
    
    func setupView() {
        navBar.type = isCheckType
        navBar.setupView()
        navBar.delegate = self
        navBar.codeNameLabel.text = ""
        navBar.storageLabel.text = ""
        navBar.codeStorageLabel.text = ""
        navBar.userNameLabel.text = UserDefault.shared.getDataLoginModel().username
        navBar.typeRoleLabel.text = UserDefault.shared.getUserID()
        
        
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(R.nib.homeMCTableViewCell)
    }
    
    private func setupSlideMenu() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let slideMenuVC = storyboard.instantiateViewController(identifier: "SideMenuViewController") as? SideMenuViewController else {
            return
        }
        slideMenuVC.delegate = self
        slideMenuVC.view.frame = menuView.bounds
        menuView.addSubview(slideMenuVC.view)
        addChild(slideMenuVC)
        slideMenuVC.didMove(toParent: self)
        
        menuViewLeadingConstraint.constant = -Constant.widthNotificationView
        blurMenuView.isHidden = true
    }
    
    func displayMenu() {
        isOpenMenu.toggle()
        blurMenuView.alpha = isOpenMenu ? 0.5 : 0
        blurMenuView.isHidden = !isOpenMenu
        UIView.animate(withDuration: 0.2) {
            self.menuViewLeadingConstraint.constant = self.isOpenMenu ? 0 : -(UIScreen.main.bounds.width * 0.7)
            self.view.layoutIfNeeded()
        }
    }
    
    private func getStorageRequest() {
        guard InternetManager.isConnected() else {
            self.showAlerInternet()
            return
        }
        
        networkManager.getStorage { [weak self] result in
            switch result {
            case .success(let response):
                guard let `self` = self else { return }
                if response.code == 200 {
                    self.dataStorage = response.data ?? []
                    self.navBar.codeStorageLabel.text = self.dataStorage.count > 0 ? self.dataStorage.first?.layout : "..."
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        self.getStorageRequest()
                    }
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
    
    private func getDocType(){
        guard InternetManager.isConnected() else {
            self.showAlerInternet()
            return
        }
        let accounType = UserDefault.shared.getDataLoginModel().accountType
        if accounType == "TaiKhoanGiamSat" {
            return
        }
        guard let accountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId else {return}
        guard let inventoryId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId else {return}
        networkManager.getDocType(inventoryId: inventoryId, accountId: accountId) { [weak self] result in
            switch result {
            case .success(let response):
                self?.dataDocType = response
                if response.code == 401 || response.code == 403 || response.code == 404 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self?.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        self.getDocType()
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
                    UserDefaults.standard.removeObject(forKey: "nameWifi")
                    let vc : LoginViewController = self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.loginViewController.identifier) as! LoginViewController
                    let navigationController = UINavigationController(rootViewController: vc)
                    navigationController.modalTransitionStyle = .crossDissolve
                    navigationController.modalPresentationStyle = .fullScreen
                    self.present(navigationController, animated: true, completion: nil)
                } else if response.code == 26 {
                    UserDefaults.standard.removeObject(forKey: "dataLoginModel")
                    UserDefaults.standard.removeObject(forKey: "nameWifi")
                    let vc : LoginViewController = self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.loginViewController.identifier) as! LoginViewController
                    let navigationController = UINavigationController(rootViewController: vc)
                    navigationController.modalTransitionStyle = .crossDissolve
                    navigationController.modalPresentationStyle = .fullScreen
                    self.present(navigationController, animated: true, completion: nil)
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
                        self?.showAlertNoti(title: "Thông báo".localized(), message: "Không nhận được phản hồi từ hệ thống, hãy kiểm tra lại server".localized(), acceptButton: "Thoát".localized(), acceptOnTap: {
                            UserDefaults.standard.removeObject(forKey: "dataLoginModel")
                            UserDefaults.standard.removeObject(forKey: "nameWifi")
                            let vc : LoginViewController = self?.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.loginViewController.identifier) as! LoginViewController
                            let navigationController = UINavigationController(rootViewController: vc)
                            navigationController.modalTransitionStyle = .crossDissolve
                            navigationController.modalPresentationStyle = .fullScreen
                            self?.present(navigationController, animated: true, completion: nil)
                        })
                    }
                }
                print(error.localizedDescription)
            }
        }
    }
    
    private func navigateToScancode(jobIndex : Int){
        let vcScancode =  self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.scanCodeMCViewController)
        vcScancode?.titleNavi = jobIndex == 0 ? "Kiểm kê".localized() : isCheckType == .monitor ? "Xác nhận".localized() : ""
        self.navigationController?.pushViewController(vcScancode!, animated: true)
    }
    private func navigateToScancode(isConfirm: Bool = false) {
        let vc = Storyboards.scanCodeMC.instantiate() as? ScanCodeMCViewController
        vc?.isHidenListInventory = false
        if isConfirm {
            vc?.isConfirmScan = true
            vc?.titleNavi = "Xác nhận".localized()
            vc?.jobIndex = 1
        } else {
            vc?.isInventoryScan = true
            vc?.titleNavi = "Kiểm kê".localized()
            vc?.jobIndex = 0
        }
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    private func navigateToFilterDocC(){
        //todo navigate
    }
}
extension MainViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if isOpenMenu {
            if let touch = touches.first {
                let location = touch.location(in: blurMenuView)
                beginPoint = location.x
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if isOpenMenu, let touch = touches.first {
            let location = touch.location(in: blurMenuView)
            let differenceFromBeginPoint = beginPoint - location.x
            if differenceFromBeginPoint > 0, differenceFromBeginPoint < Constant.widthNotificationView {
                difference = differenceFromBeginPoint
                menuViewLeadingConstraint.constant = -differenceFromBeginPoint
                blurMenuView.alpha = 0.5 * (1 - differenceFromBeginPoint / Constant.widthNotificationView)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if isOpenMenu {
            if difference == 0, let touch = touches.first {
                let location = touch.location(in: blurMenuView)
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
        blurMenuView.alpha = isShown ? 0.5 : 0
        blurMenuView.isHidden = !isShown
        UIView.animate(withDuration: 0.2) {
            self.menuViewLeadingConstraint.constant = isShown ? 0 : -Constant.widthNotificationView
            self.view.layoutIfNeeded()
        }
        isOpenMenu = isShown
    }
}

extension MainViewController: SideMenuViewControllerDelegate {
    func selectedCell(_ row: Int) {
        // logout
        let userId: String = UserDefault.shared.getDataLoginModel().userId ?? ""
        logoutRequest(userID: [userId])
    }
}

extension MainViewController: NavigationBarProtocol {
    func dropDownAction() {
        if dataStorage.count > 0 {
            let dropDownWindow = DropDownWindow(frames: navBar.frame, viewSelect: navBar, data: dataStorage, indexChoose: self.indexChooseStorage)
            dropDownWindow.dropDownData = { (data, index) in
                self.navBar.codeStorageLabel.text = data.layout
                self.indexChooseStorage = index
            }
            self.present(dropDownWindow, animated: true)
        }
    }
    
    func menuButtonAction() {
        self.displayMenu()
    }
    
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isCheckType == .mc || isCheckType == .monitor {
            return 1
        } else {
            return 3
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.homeMCTableViewCell, for: indexPath) else {return UITableViewCell()}
        cell.selectionStyle = .none
        
        if isCheckType == .mc {
            if indexPath.row == 0 {
                cell.fillData(title: "Xuất kho".localized(), content: "Thực hiện quét mã linh kiện và nhập số lượng xuất kho".localized())
            } else {
                cell.fillData(title: "Kiểm kê".localized(), content: "Thực hiện kiểm kê số lượng trong kho".localized())
            }
        } else if isCheckType == .pcb {
            cell.fillData(title: indexPath.row == 0 ? "Xuất kho".localized() : "Nhập kho".localized(), content: indexPath.row == 0 ? "Thực hiện quét mã linh kiện và nhập số lượng xuất kho".localized() : "Thực hiện quét mã linh kiện và nhập số lượng nhập kho".localized())
            
            if indexPath.row == 2 {
                cell.fillData(title: "Kiểm kê".localized(), content: "Thực hiện kiểm kê số lượng trong kho".localized())
            }
            if indexPath.row == 3 {
                cell.fillData(title: "Giám sát".localized(), content: "Thực hiện giám sát kiểm kê số lượng linh kiện trong kho".localized())
            }
        } else if isCheckType == .inventory {
            if indexPath.row == 0 {
                cell.fillData(title: "Kiểm kê".localized(), content: "Thực hiện kiểm kê số lượng linh kiện trong kho".localized(), avatarName: R.image.ic_inventory.name)
            } else if indexPath.row == 1 {
                cell.fillData(title: "Xác nhận".localized(), content: "Thực hiện xác nhận kiểm kê số lượng linh kiện trong kho".localized(), avatarName: R.image.ic_accept.name)
            } else {
                cell.fillData(title: "Điều tra sai số".localized(), content: "Thực hiện điều tra sai số linh kiện trong kho.".localized(), avatarName: R.image.ic_monitor.name)
            }
        } else if isCheckType == .monitor {
            cell.fillData(title: "Giám sát".localized(), content: "Thực hiện giám sát kiểm kê số lượng linh kiện trong kho".localized(), avatarName: R.image.ic_monitor.name)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if isCheckType == .mc && indexPath.row == 1 {
            let vc = storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.inventoryDetailViewController)
            navigationController?.pushViewController(vc!, animated: true)
        } else if isCheckType == .mc && indexPath.row == 2 {
            let vc = storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.listMonitoringSheetsVC)
            navigationController?.pushViewController(vc!, animated: true)
        } else if isCheckType == .pcb && indexPath.row == 2 {
            let vc = storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.inventoryDetailViewController)
            navigationController?.pushViewController(vc!, animated: true)
        } else if isCheckType == .pcb && indexPath.row == 3 {
            let vc = storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.listMonitoringSheetsVC)
            navigationController?.pushViewController(vc!, animated: true)
        } else if  isCheckType == .inventory {
            if indexPath.row == 2 {
                guard let vc = Storyboards.listError.instantiate() as? ListErrorController else {return}
                vc.titleString = "Danh sách sai số".localized()
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                checkShopPopupChooseDocType(jobIndex: indexPath.row)
            }
        } else if isCheckType == .monitor {
            guard let vc = Storyboards.scanCodeMC.instantiate() as? ScanCodeMCViewController else {return}
            vc.isHiddenMonitorView = false
            vc.isMonitorScan = true
            vc.titleNavi = "Giám sát".localized()
            navigationController?.pushViewController(vc, animated: true)
            
        } else {
            let vc = storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.scanCodeMCViewController)
            vc?.type = isCheckType
            if isCheckType == .mc {
                vc?.titleNavi = "Xuất kho".localized()
            } else if isCheckType == .pcb {
                vc?.titleNavi = indexPath.row == 0 ? "Xuất kho".localized() : "Nhập kho".localized()
            }
            
            if dataStorage.count > 0 {
                vc?.layoutString = self.dataStorage[self.indexChooseStorage].layout ?? ""
            }
            navigationController?.pushViewController(vc!, animated: true)
        }
        
    }
    
    private func checkShopPopupChooseDocType(jobIndex: Int){
        guard let dataDocType = self.dataDocType else {return}
        let titleJob = jobIndex == 0 ? "Kiểm kê".localized() : "Xác nhận".localized()
        
        if dataDocType.isOutOfDate() {
            let message = jobIndex == 0 ? "Không thể kiểm kê vì đã quá ngày kiểm kê của đợt kiểm kê hiện tại. Vui lòng thử lại sau".localized() : "Không thể xác nhận kiểm kê vì đã quá ngày kiểm kê của đợt kiểm kê hiện tại. Vui lòng thử lại sau".localized()
            self.showAlertNoti(title: "Thông báo".localized(), message: message, acceptButton: "Đồng ý".localized())
            return
        } else if dataDocType.isNotAssignInventory() {
            let message = jobIndex == 0 ? "Không thể kiểm kê vì tài khoản của bạn chưa được phân phát phiếu trong đợt kiểm kê hiện tại. Vui lòng thử lại sau".localized() : "Không thể xác nhận kiểm kê vì tài khoản của bạn chưa được phân phát phiếu trong đợt kiểm kê hiện tại. Vui lòng thử lại sau".localized()
            self.showAlertNoti(title: "Thông báo".localized(), message: message, acceptButton: "Đồng ý".localized())
        }
        
        let chooseDocType = dataDocType.isShowChooseDocType()
        switch chooseDocType {
        case .aebc:
            showPopUpAlertABEC(jobIndex: jobIndex, titleJob: titleJob)
            break
        case .aeb:
            showPopUpAlertAEB(jobIndex: jobIndex, titleJob: titleJob)
            break
        case .aec:
            showPopUpAlertAEC(jobIndex: jobIndex, titleJob: titleJob)
            break
        case .bc:
            showPopUpAlertBC(jobIndex: jobIndex, titleJob: titleJob)
            break
        case .ae:
            self.navigateToScancode(isConfirm: jobIndex == 1 ? true : false)
            break
        case .b:
            self.navigateChooseModelDoc(jobIndex: jobIndex, titleJob: titleJob, docType: "B")
            break
        case .c:
            self.navigateChooseModelDoc(jobIndex: jobIndex, titleJob: titleJob, docType: "C")
            break
        }
    }
    
    func showPopUpAlertABEC(jobIndex: Int, titleJob: String) {
        self.showPopUpAlert(title: "Chọn loại phiếu".localized(), array: ["Loại phiếu A,E".localized(), "Loại phiếu B".localized(), "Loại phiếu C".localized()]) {} accept: { index in
            switch index {
            case 0:
                self.navigateToScancode(isConfirm: jobIndex == 1 ? true : false)
                break
            case 1:
                self.navigateChooseModelDoc(jobIndex: jobIndex, titleJob: titleJob, docType: "B")
                break
            case 2:
                self.navigateChooseModelDoc(jobIndex: jobIndex, titleJob: titleJob, docType: "C")
                break
            default:
                return
            }
        }
    }
    
    func showPopUpAlertAEB(jobIndex: Int, titleJob: String) {
        self.showPopUpAlert(title: "Chọn loại phiếu".localized(), array: ["Loại phiếu A,E".localized(), "Loại phiếu B".localized()]) {} accept: { index in
            switch index {
            case 0:
                self.navigateToScancode(isConfirm: jobIndex == 1 ? true : false)
                break
            case 1:
                self.navigateChooseModelDoc(jobIndex: jobIndex, titleJob: titleJob, docType: "B")
                break
            default:
                return
            }
        }
    }
    
    func showPopUpAlertAEC(jobIndex: Int, titleJob: String) {
        self.showPopUpAlert(title: "Chọn loại phiếu".localized(), array: ["Loại phiếu A,E".localized(), "Loại phiếu C".localized()]) {} accept: { index in
            switch index {
            case 0:
                self.navigateToScancode(isConfirm: jobIndex == 1 ? true : false)
                break
            case 1:
                self.navigateChooseModelDoc(jobIndex: jobIndex, titleJob: titleJob, docType: "C")
                break
            default:
                return
            }
        }
    }
    
    func showPopUpAlertBC(jobIndex: Int, titleJob: String) {
        self.showPopUpAlert(title: "Chọn loại phiếu".localized(), array: ["Loại phiếu B".localized(), "Loại phiếu C".localized()]) {} accept: { index in
            switch index {
            case 0:
                self.navigateChooseModelDoc(jobIndex: jobIndex, titleJob: titleJob, docType: "B")
                break
            case 1:
                self.navigateChooseModelDoc(jobIndex: jobIndex, titleJob: titleJob, docType: "C")
                break
            default:
                return
            }
        }
    }
    
    func navigateChooseModelDoc(jobIndex: Int, titleJob: String, docType: String) {
        guard let vc = Storyboards.chooseModelDoc.instantiate() as? ChooseModelDocViewController else {return}
        self.title = ""
        vc.titleString = UserDefault.shared.getUserID()
        vc.jobIndex = jobIndex
        vc.isAcpect = jobIndex == 0 ? false : true
        vc.docType = docType
        vc.titleJob = titleJob
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
