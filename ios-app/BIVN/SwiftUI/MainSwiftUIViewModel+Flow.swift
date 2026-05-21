import UIKit
import SwiftUI
import Localize_Swift

extension MainSwiftUIViewModel {
    func didSelectFeature(index: Int) {
        guard index < features.count else { return }

        if role == .monitor {
            flowDestination = LegacyFlowDestination {
                let view = ScanCodeMCSwiftUIView(role: .monitor, titleNavi: "Giám sát".localized(), layoutString: "", mode: .monitor)
                return UIHostingController(rootView: view)
            }
            return
        }

        if role == .inventory {
            if index == 2 {
                flowDestination = LegacyFlowDestination {
                    guard let vc = Storyboards.listError.instantiate() as? ListErrorController else { return UIViewController() }
                    vc.titleString = "Danh sách sai số".localized()
                    return vc
                }
            } else {
                checkShopPopupChooseDocType(jobIndex: index)
            }
            return
        }

        if role == .mc && index == 1 {
            flowDestination = LegacyFlowDestination {
                let storyboard = UIStoryboard(name: R.storyboard.main.name, bundle: nil)
                guard let vc = storyboard.instantiateViewController(withIdentifier: R.storyboard.main.inventoryDetailViewController) as? InventoryDetailViewController else { return UIViewController() }
                return vc
            }
            return
        }

        if role == .pcb && index == 2 {
            flowDestination = LegacyFlowDestination {
                let storyboard = UIStoryboard(name: R.storyboard.main.name, bundle: nil)
                guard let vc = storyboard.instantiateViewController(withIdentifier: R.storyboard.main.inventoryDetailViewController) as? InventoryDetailViewController else { return UIViewController() }
                return vc
            }
            return
        }

        flowDestination = LegacyFlowDestination {
            var title = ""
            if self.role == .mc {
                title = "Xuất kho".localized()
            } else if self.role == .pcb {
                title = index == 0 ? "Xuất kho".localized() : "Nhập kho".localized()
            }
            var layout = ""
            if !self.dataStorage.isEmpty, self.selectedStorageIndex < self.dataStorage.count {
                layout = self.dataStorage[self.selectedStorageIndex].layout ?? ""
            }
            let view = ScanCodeMCSwiftUIView(role: self.role, titleNavi: title, layoutString: layout)
            return UIHostingController(rootView: view)
        }
    }

    func logout() {
        guard InternetManager.isConnected() else {
            alert = AlertMessage(title: "Thông báo".localized(), message: "Vui lòng kiểm tra lại kết nối internet của thiết bị.".localized())
            return
        }

        isLoading = true
        var params = Dictionary<String, Any>()
        params["userId"] = UserDefault.shared.getDataLoginModel().userId ?? ""

        networkManager.logoutDeleteRequest(param: params) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 || response.code == 26 {
                        self.clearSessionAndGoLogin()
                    } else if response.code == 500 {
                        self.alert = AlertMessage(title: "Thông báo".localized(), message: "Không nhận được phản hồi từ hệ thống, hãy kiểm tra lại server".localized())
                    } else {
                        self.alert = AlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                            message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
                        )
                    }
                case .failure(let error):
                    self.alert = AlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    func getStorageRequest() {
        guard InternetManager.isConnected() else {
            alert = AlertMessage(title: "Thông báo".localized(), message: "Vui lòng kiểm tra lại kết nối internet của thiết bị.".localized())
            return
        }

        isLoading = true
        networkManager.getStorage { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 {
                        self.dataStorage = response.data ?? []
                        self.selectedStorageIndex = 0
                    } else {
                        self.alert = AlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                            message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
                        )
                    }
                case .failure(let error):
                    self.alert = AlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    func getDocType() {
        guard InternetManager.isConnected() else {
            alert = AlertMessage(title: "Thông báo".localized(), message: "Vui lòng kiểm tra lại kết nối internet của thiết bị.".localized())
            return
        }

        if UserDefault.shared.getDataLoginModel().accountType == AccountType.monitoringAccount.rawValue {
            return
        }

        guard let accountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId else { return }
        guard let inventoryId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId else { return }

        isLoading = true
        networkManager.getDocType(inventoryId: inventoryId, accountId: accountId) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    self.dataDocType = response
                case .failure(let error):
                    self.alert = AlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    static func buildFeatures(for role: TypeRole) -> [MainFeatureItem] {
        if role == .mc {
            return [
                MainFeatureItem(title: "Xuất kho".localized(), content: "Thực hiện quét mã linh kiện và nhập số lượng xuất kho".localized(), imageName: R.image.ic_home_warehouse.name),
                MainFeatureItem(title: "Kiểm kê".localized(), content: "Thực hiện kiểm kê số lượng trong kho".localized(), imageName: R.image.ic_inventory.name)
            ]
        }

        if role == .pcb {
            return [
                MainFeatureItem(title: "Xuất kho".localized(), content: "Thực hiện quét mã linh kiện và nhập số lượng xuất kho".localized(), imageName: R.image.ic_home_warehouse.name),
                MainFeatureItem(title: "Nhập kho".localized(), content: "Thực hiện quét mã linh kiện và nhập số lượng nhập kho".localized(), imageName: R.image.ic_home_warehouse.name),
                MainFeatureItem(title: "Kiểm kê".localized(), content: "Thực hiện kiểm kê số lượng trong kho".localized(), imageName: R.image.ic_inventory.name)
            ]
        }

        if role == .inventory {
            return [
                MainFeatureItem(title: "Kiểm kê".localized(), content: "Thực hiện kiểm kê số lượng linh kiện trong kho".localized(), imageName: R.image.ic_inventory.name),
                MainFeatureItem(title: "Xác nhận".localized(), content: "Thực hiện xác nhận kiểm kê số lượng linh kiện trong kho".localized(), imageName: R.image.ic_accept.name),
                MainFeatureItem(title: "Điều tra sai số".localized(), content: "Thực hiện điều tra sai số linh kiện trong kho.".localized(), imageName: R.image.ic_monitor.name)
            ]
        }

        return [
            MainFeatureItem(title: "Giám sát".localized(), content: "Thực hiện giám sát kiểm kê số lượng linh kiện trong kho".localized(), imageName: R.image.ic_monitor.name)
        ]
    }

    private func checkShopPopupChooseDocType(jobIndex: Int) {
        guard let dataDocType = dataDocType else { return }
        let titleJob = jobIndex == 0 ? "Kiểm kê".localized() : "Xác nhận".localized()

        if dataDocType.isOutOfDate() {
            let message = jobIndex == 0
                ? "Không thể kiểm kê vì đã quá ngày kiểm kê của đợt kiểm kê hiện tại. Vui lòng thử lại sau".localized()
                : "Không thể xác nhận kiểm kê vì đã quá ngày kiểm kê của đợt kiểm kê hiện tại. Vui lòng thử lại sau".localized()
            alert = AlertMessage(title: "Thông báo".localized(), message: message)
            return
        }

        if dataDocType.isNotAssignInventory() {
            let message = jobIndex == 0
                ? "Không thể kiểm kê vì tài khoản của bạn chưa được phân phát phiếu trong đợt kiểm kê hiện tại. Vui lòng thử lại sau".localized()
                : "Không thể xác nhận kiểm kê vì tài khoản của bạn chưa được phân phát phiếu trong đợt kiểm kê hiện tại. Vui lòng thử lại sau".localized()
            alert = AlertMessage(title: "Thông báo".localized(), message: message)
            return
        }

        switch dataDocType.isShowChooseDocType() {
        case .aebc:
            docTypeChoices = [
                makeDocTypeChoice(title: "Loại phiếu A,E".localized(), jobIndex: jobIndex),
                makeChooseModelChoice(jobIndex: jobIndex, titleJob: titleJob, docType: "B", title: "Loại phiếu B".localized()),
                makeChooseModelChoice(jobIndex: jobIndex, titleJob: titleJob, docType: "C", title: "Loại phiếu C".localized())
            ]
        case .aeb:
            docTypeChoices = [
                makeDocTypeChoice(title: "Loại phiếu A,E".localized(), jobIndex: jobIndex),
                makeChooseModelChoice(jobIndex: jobIndex, titleJob: titleJob, docType: "B", title: "Loại phiếu B".localized())
            ]
        case .aec:
            docTypeChoices = [
                makeDocTypeChoice(title: "Loại phiếu A,E".localized(), jobIndex: jobIndex),
                makeChooseModelChoice(jobIndex: jobIndex, titleJob: titleJob, docType: "C", title: "Loại phiếu C".localized())
            ]
        case .bc:
            docTypeChoices = [
                makeChooseModelChoice(jobIndex: jobIndex, titleJob: titleJob, docType: "B", title: "Loại phiếu B".localized()),
                makeChooseModelChoice(jobIndex: jobIndex, titleJob: titleJob, docType: "C", title: "Loại phiếu C".localized())
            ]
        case .ae:
            navigateToScancode(isConfirm: jobIndex == 1)
        case .b:
            navigateChooseModelDoc(jobIndex: jobIndex, titleJob: titleJob, docType: "B")
        case .c:
            navigateChooseModelDoc(jobIndex: jobIndex, titleJob: titleJob, docType: "C")
        }
    }

    private func makeDocTypeChoice(title: String, jobIndex: Int) -> DocTypeChoiceItem {
        DocTypeChoiceItem(title: title) { [weak self] in
            self?.navigateToScancode(isConfirm: jobIndex == 1)
        }
    }

    private func makeChooseModelChoice(jobIndex: Int, titleJob: String, docType: String, title: String) -> DocTypeChoiceItem {
        DocTypeChoiceItem(title: title) { [weak self] in
            self?.navigateChooseModelDoc(jobIndex: jobIndex, titleJob: titleJob, docType: docType)
        }
    }

    private func navigateToScancode(isConfirm: Bool = false) {
        flowDestination = LegacyFlowDestination {
            let view = ScanCodeMCSwiftUIView(
                role: .inventory,
                titleNavi: isConfirm ? "Xác nhận".localized() : "Kiểm kê".localized(),
                layoutString: "",
                mode: isConfirm ? .confirm : .inventory
            )
            return UIHostingController(rootView: view)
        }
    }

    private func navigateChooseModelDoc(jobIndex: Int, titleJob: String, docType: String) {
        flowDestination = LegacyFlowDestination {
            let view = ChooseModelDocSwiftUIView(
                titleString: UserDefault.shared.getUserID(),
                jobIndex: jobIndex,
                docType: docType,
                titleJob: titleJob
            )
            return UIHostingController(rootView: view)
        }
    }

    private func clearSessionAndGoLogin() {
        UserDefaults.standard.removeObject(forKey: "dataLoginModel")
        UserDefaults.standard.removeObject(forKey: "nameWifi")
        router?.navigateToLogin()
    }
}
