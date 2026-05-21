import SwiftUI
import Moya
import Localize_Swift

enum ScanMCMode {
    case storage
    case inventory
    case confirm
    case monitor
}

struct ScanMCAlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct ScanMCLegacyDestination: Identifiable {
    let id = UUID()
    let build: () -> UIViewController
}

final class ScanCodeMCSwiftUIViewModel: ObservableObject {
    @Published var componentCode: String = ""
    @Published var isLoading = false
    @Published var alert: ScanMCAlertMessage?
    @Published var choosePositions: [String] = []
    @Published var destination: ScanMCLegacyDestination?
    @Published var chooseTicketPositions: [String] = []
    @Published var pendingResetTicket: DetailResponseDataTicket?

    private let role: TypeRole
    private let titleNavi: String
    private let layoutString: String
    private let mode: ScanMCMode
    private let networkManager = NetworkManager()
    private var responseData: [DataPositionModel] = []
    private var detailTickets: [DetailResponseDataTicket] = []
    private var monitorTickets: [AuditInfoModels] = []

    init(role: TypeRole, titleNavi: String, layoutString: String, mode: ScanMCMode) {
        self.role = role
        self.titleNavi = titleNavi
        self.layoutString = layoutString
        self.mode = mode
    }

    var showInventoryListButton: Bool {
        mode == .inventory || mode == .confirm
    }

    var inventoryListButtonTitle: String {
        mode == .inventory ? "Danh sách LK chưa kiểm kê".localized() : "Danh sách LK chờ xác nhận".localized()
    }

    func send() {
        let trimmed = componentCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            alert = ScanMCAlertMessage(title: "Lỗi".localized(), message: "Vui lòng nhập mã linh kiện.".localized())
            return
        }

        let hasSpecialCharacters = trimmed.range(of: ".*[^A-Za-z0-9 ].*", options: .regularExpression) != nil
        if hasSpecialCharacters {
            alert = ScanMCAlertMessage(title: "Lỗi".localized(), message: "Mã linh kiện không đúng định dạng. Vui lòng thử lại".localized())
            return
        }

        switch mode {
        case .storage:
            requestGetPosition(layout: layoutString, componentCode: trimmed)
        case .inventory:
            getDetailTicket(componentCode: trimmed, isConfirm: false)
        case .confirm:
            getDetailTicket(componentCode: trimmed, isConfirm: true)
        case .monitor:
            getDetailMonitor(componentCode: trimmed)
        }
    }

    func handleNativeScannedCode(_ code: String) {
        componentCode = code
        send()
    }

    func choosePosition(index: Int) {
        guard responseData.indices.contains(index) else { return }
        navigateToDetail(with: responseData[index])
    }

    func clearPositionDialog() {
        choosePositions = []
    }

    func clearDestination() {
        destination = nil
    }

    func clearTicketPositions() {
        chooseTicketPositions = []
    }

    func selectTicketPosition(index: Int) {
        guard detailTickets.indices.contains(index) else { return }
        handleTicketSelection(detailTickets[index])
    }

    func selectMonitorPosition(index: Int) {
        guard monitorTickets.indices.contains(index) else { return }
        openMonitorDetail(documentId: monitorTickets[index].id ?? "")
    }

    func confirmResetTicket() {
        guard let ticket = pendingResetTicket else { return }
        pendingResetTicket = nil
        navigateInventoryDetail(ticket: ticket, resetInventory: mode == .inventory)
    }

    func cancelResetTicket() {
        pendingResetTicket = nil
    }

    func openInventoryList() {
        guard mode == .inventory || mode == .confirm else { return }
        destination = ScanMCLegacyDestination {
            let view = ListAccessoryNotInventorySwiftUIView(
                titleString: self.titleNavi,
                jobIndex: self.mode == .confirm ? 1 : 0
            )
            return UIHostingController(rootView: view)
        }
    }

    private func getDetailTicket(componentCode: String, isConfirm: Bool) {
        guard let inventoryId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId,
              let accountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId else { return }

        guard InternetManager.isConnected() else {
            alert = ScanMCAlertMessage(title: "Thông báo".localized(), message: "Vui lòng kiểm tra lại kết nối internet của thiết bị.".localized())
            return
        }

        var param = Dictionary<String, Any>()
        param["positionCode"] = ""
        param["docCode"] = ""
        param["isErrorInvestigation"] = "false"

        isLoading = true
        networkManager.getDetailTicket(inventoryId: inventoryId, accountId: accountId, componentCode: componentCode, isConfirm: isConfirm, param: param) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 {
                        self.detailTickets = response.data ?? []
                        if self.detailTickets.count == 1, let one = self.detailTickets.first {
                            self.handleTicketSelection(one)
                        } else {
                            self.chooseTicketPositions = self.detailTickets.map { $0.inventoryDoc?.positionCode ?? "" }
                        }
                    } else {
                        self.alert = ScanMCAlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                            message: response.message ?? UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
                        )
                    }
                case .failure(let error):
                    self.alert = ScanMCAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    private func handleTicketSelection(_ ticket: DetailResponseDataTicket) {
        let status = ticket.inventoryDoc?.status ?? 0
        let histories = ticket.histories ?? []
        let hasHistory = histories.contains { $0.status == 3 || $0.status == 5 }

        if hasHistory {
            if mode == .inventory {
                if status >= 3 {
                    pendingResetTicket = ticket
                    return
                }
            } else if mode == .confirm {
                if UserDefault.shared.getUserID() == ticket.inventoryDoc?.inventoryBy {
                    alert = ScanMCAlertMessage(title: "Thông báo".localized(), message: "Bạn không được xác nhận phiếu này".localized())
                    return
                }
                if status >= 5 {
                    pendingResetTicket = ticket
                    return
                }
            }
        }

        navigateInventoryDetail(ticket: ticket, resetInventory: false)
    }

    private func navigateInventoryDetail(ticket: DetailResponseDataTicket, resetInventory: Bool) {
        destination = ScanMCLegacyDestination {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let vc = storyboard.instantiateViewController(withIdentifier: "InventoryDetailViewController") as? InventoryDetailViewController else { return UIViewController() }
            if let histories = ticket.histories {
                for item in histories where (item.evicenceImg ?? "").isEmpty == false {
                    vc.evicenceImg = item.evicenceImg
                    break
                }
            }
            vc.dataTicket = ticket
            vc.isConfirmScan = self.mode == .confirm
            vc.jobIndex = self.mode == .confirm ? 1 : 0
            vc.resetInventory = resetInventory
            return vc
        }
    }

    private func getDetailMonitor(componentCode: String) {
        guard let inventoryId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId,
              let accountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId else { return }

        guard InternetManager.isConnected() else {
            alert = ScanMCAlertMessage(title: "Thông báo".localized(), message: "Vui lòng kiểm tra lại kết nối internet của thiết bị.".localized())
            return
        }

        isLoading = true
        networkManager.getDetailMonitor(inventoryId: inventoryId, accountId: accountId, componentCode: componentCode) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 {
                        self.monitorTickets = response.data ?? []
                        if self.monitorTickets.count == 1 {
                            self.openMonitorDetail(documentId: self.monitorTickets.first?.id ?? "")
                        } else {
                            self.choosePositions = self.monitorTickets.map { $0.positionCode ?? "" }
                        }
                    } else {
                        self.alert = ScanMCAlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                            message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
                        )
                    }
                case .failure(let error):
                    self.alert = ScanMCAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    private func openMonitorDetail(documentId: String) {
        guard !documentId.isEmpty else { return }
        guard let inventoryId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId,
              let accountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId else { return }

        isLoading = true
        networkManager.getDetailSheetsMonitor(inventoryId: inventoryId, accountId: accountId, documentId: documentId, actionType: 2) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 {
                        self.destination = ScanMCLegacyDestination {
                            guard let vc = Storyboards.acctionInventory.instantiate() as? ActionInventoryViewController else { return UIViewController() }
                            vc.documentId = documentId
                            vc.dataDetailSheets = response.data
                            vc.dataHistory = response.data?.docHistories ?? []
                            vc.arrayData = response.data?.docComponentABEs ?? []
                            vc.titleNav = response.data?.docCode ?? ""
                            return vc
                        }
                    } else {
                        self.alert = ScanMCAlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                            message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
                        )
                    }
                case .failure(let error):
                    self.alert = ScanMCAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    private func requestGetPosition(layout: String, componentCode: String) {
        guard InternetManager.isConnected() else {
            alert = ScanMCAlertMessage(title: "Thông báo".localized(), message: "Vui lòng kiểm tra lại kết nối internet của thiết bị.".localized())
            return
        }

        isLoading = true
        networkManager.getPosition(layout: layout, componentCode: componentCode) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 {
                        self.responseData = response.data ?? []
                        let positions = self.responseData.map { $0.positionCode ?? "" }

                        if self.responseData.count == 1 {
                            self.navigateToDetail(with: self.responseData[0])
                        } else {
                            self.choosePositions = positions
                        }
                    } else {
                        self.alert = ScanMCAlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                            message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
                        )
                    }
                case .failure(let error):
                    if case MoyaError.underlying(let underlyingError, _) = error,
                       (underlyingError as NSError).code == 13 {
                        self.alert = ScanMCAlertMessage(title: "Thông báo".localized(), message: "Không nhận được phản hồi từ hệ thống, hãy kiểm tra lại server".localized())
                    } else {
                        self.alert = ScanMCAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                    }
                }
            }
        }
    }

    private func navigateToDetail(with data: DataPositionModel) {
        destination = ScanMCLegacyDestination {
            let storyboard = UIStoryboard(name: R.storyboard.main.name, bundle: nil)
            guard let vc = storyboard.instantiateViewController(withIdentifier: R.storyboard.main.detailViewController) as? DetailMCViewController else { return UIViewController() }
            if self.role == .mc {
                vc.type = self.role
            } else {
                vc.typePCB = self.titleNavi
            }
            vc.componentDetailModels = data.componentDetails ?? []
            return vc
        }
    }
}

struct ScanCodeMCSwiftUIView: View {
    @ObservedObject private var viewModel: ScanCodeMCSwiftUIViewModel
    @State private var showResetConfirm = false
    @State private var showNativeScanner = false

    init(role: TypeRole, titleNavi: String, layoutString: String, mode: ScanMCMode = .storage) {
        viewModel = ScanCodeMCSwiftUIViewModel(role: role, titleNavi: titleNavi, layoutString: layoutString, mode: mode)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Image(R.image.ic_scan.name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)
                    Text("Đưa camera hướng về mã linh kiện".localized())
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Nhập mã linh kiện".localized())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(UIColor(named: R.color.textDefault.name) ?? .black))
                    TextField("Nhập mã linh kiện...".localized(), text: $viewModel.componentCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(.horizontal, 12)
                        .frame(height: 46)
                        .background(Color(UIColor(named: R.color.grey1.name) ?? .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button(action: {
                    viewModel.send()
                }) {
                    Text("Gửi".localized())
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color(UIColor(named: R.color.buttonBlue.name) ?? .systemBlue))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if viewModel.showInventoryListButton {
                    Button(action: {
                        viewModel.openInventoryList()
                    }) {
                        Text(viewModel.inventoryListButtonTitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(UIColor(named: R.color.buttonBlue.name) ?? .systemBlue))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(UIColor(named: R.color.buttonBlue.name) ?? .systemBlue), lineWidth: 1)
                            )
                    }
                }

                Button(action: {
                    showNativeScanner = true
                }) {
                    Text("Quét camera".localized())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(UIColor(named: R.color.buttonBlue.name) ?? .systemBlue))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(UIColor(named: R.color.buttonBlue.name) ?? .systemBlue), lineWidth: 1)
                        )
                }

                Spacer()
            }
            .padding(.horizontal, 16)

            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .navigationTitle("Quét mã linh kiện".localized())
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(viewModel.$pendingResetTicket) { pending in
            showResetConfirm = pending != nil
        }
        .alert(item: $viewModel.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("Đồng ý".localized())))
        }
        .confirmationDialog("Chọn vị trí".localized(), isPresented: Binding(
            get: { !viewModel.choosePositions.isEmpty },
            set: { shown in
                if !shown {
                    viewModel.clearPositionDialog()
                }
            }
        ), titleVisibility: .visible) {
            ForEach(Array(viewModel.choosePositions.enumerated()), id: \.offset) { index, name in
                Button(name) {
                    viewModel.clearPositionDialog()
                    viewModel.choosePosition(index: index)
                }
            }
            Button("Hủy".localized(), role: .cancel) {
                viewModel.clearPositionDialog()
            }
        }
        .confirmationDialog("Chọn vị trí".localized(), isPresented: Binding(
            get: { !viewModel.chooseTicketPositions.isEmpty },
            set: { shown in
                if !shown {
                    viewModel.clearTicketPositions()
                }
            }
        ), titleVisibility: .visible) {
            ForEach(Array(viewModel.chooseTicketPositions.enumerated()), id: \.offset) { index, name in
                Button(name) {
                    viewModel.clearTicketPositions()
                    viewModel.selectTicketPosition(index: index)
                }
            }
            Button("Hủy".localized(), role: .cancel) {
                viewModel.clearTicketPositions()
            }
        }
        .confirmationDialog("Thông báo".localized(), isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Đồng ý".localized()) {
                viewModel.confirmResetTicket()
            }
            Button("Hủy bỏ".localized(), role: .cancel) {
                viewModel.cancelResetTicket()
            }
        } message: {
            Text("Đã được xử lý. Bạn có muốn thực hiện lại không".localized())
        }
        .fullScreenCover(item: $viewModel.destination, onDismiss: {
            viewModel.clearDestination()
        }) { destination in
            ScanMCLegacyHost {
                let vc = destination.build()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                return nav
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showNativeScanner) {
            CodeScannerSwiftUIView { code in
                viewModel.handleNativeScannedCode(code)
            }
            .ignoresSafeArea()
        }
    }
}

private struct ScanMCLegacyHost: UIViewControllerRepresentable {
    let build: () -> UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        build()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
