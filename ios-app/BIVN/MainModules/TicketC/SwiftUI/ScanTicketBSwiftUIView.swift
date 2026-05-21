import SwiftUI
import Localize_Swift

struct ScanBAlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct ScanBLegacyDestination: Identifiable {
    let id = UUID()
    let build: () -> UIViewController
}

struct ScanBTicketChoice: Identifiable {
    let id = UUID()
    let index: Int
    let title: String
}

final class ScanTicketBSwiftUIViewModel: ObservableObject {
    @Published var inputCode: String = ""
    @Published var listDocB: ListDocB
    @Published var isLoading = false
    @Published var alert: ScanBAlertMessage?
    @Published var destination: ScanBLegacyDestination?
    @Published var ticketChoices: [ScanBTicketChoice] = []
    @Published var pendingResetConfirm: DetailResponseDataTicket?

    private let titleNavi: String
    let jobIndex: Int
    private let model: String?
    private let modelCode: String?
    private let machineType: String?
    private let lineCode: String
    private let networkManager = NetworkManager()

    init(titleNavi: String, jobIndex: Int, model: String?, modelCode: String?, machineType: String?, lineCode: String, listDocB: ListDocB) {
        self.titleNavi = titleNavi
        self.jobIndex = jobIndex
        self.model = model
        self.modelCode = modelCode
        self.machineType = machineType
        self.lineCode = lineCode
        self.listDocB = listDocB
    }

    var finishText: String {
        "\(listDocB.finishCount ?? 0) / \(listDocB.totalCount ?? 0)"
    }

    func onAppear() {
        refreshListDocB()
    }

    func refreshListDocB() {
        var param = Dictionary<String, Any>()
        param["inventoryId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? ""
        param["accountId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? ""
        param["machineModel"] = model ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineCode
        param["actionType"] = jobIndex
        param["stageName"] = ""
        param["modelCode"] = modelCode ?? ""
        param["pageNum"] = 1
        param["pageSize"] = 20

        isLoading = true
        networkManager.getListdocB(param: param) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 {
                        self.listDocB = response.data ?? ListDocB()
                    } else {
                        self.alert = ScanBAlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                            message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
                        )
                    }
                case .failure(let error):
                    self.alert = ScanBAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    func openListNotInventory() {
        let filtered: [DocBInfoModels]
        if jobIndex == 0 {
            filtered = listDocB.docBInfoModels?.filter({ $0.status == 2 }) ?? []
        } else {
            filtered = listDocB.docBInfoModels?.filter({ $0.status == 3 }) ?? []
        }

        destination = ScanBLegacyDestination {
            let view = ListAccessoryNotInventorySwiftUIView(
                titleString: self.titleNavi,
                jobIndex: self.jobIndex,
                model: self.model,
                modelCode: self.modelCode,
                machineType: self.machineType,
                lineCode: self.lineCode,
                docBItems: filtered
            )
            return UIHostingController(rootView: view)
        }
    }

    func handleNativeScannedCode(_ code: String) {
        inputCode = code
        sendCode()
    }

    func sendCode() {
        let value = inputCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            alert = ScanBAlertMessage(title: "Lỗi".localized(), message: "Vui lòng nhập mã linh kiện.".localized())
            return
        }

        let hasSpecialCharacters = value.range(of: ".*[^A-Za-z0-9 ].*", options: .regularExpression) != nil
        if hasSpecialCharacters {
            alert = ScanBAlertMessage(title: "Lỗi".localized(), message: "Mã linh kiện không đúng định dạng. Vui lòng thử lại".localized())
            return
        }

        var param = Dictionary<String, Any>()
        param["inventoryId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? ""
        param["accountId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? ""
        param["componentCode"] = value
        param["machineModel"] = model ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineCode
        param["modelCode"] = modelCode ?? ""
        param["actionType"] = jobIndex
        param["isErrorInvestigation"] = false

        isLoading = true
        networkManager.scanDocB(isErrorInvestigation: false, param: param) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 {
                        let tickets = response.data ?? []
                        if tickets.count == 1, let one = tickets.first {
                            self.handleTicketSelection(one)
                        } else {
                            self.ticketChoices = tickets.enumerated().map { idx, ticket in
                                let position = ticket.inventoryDoc?.positionCode ?? ""
                                return ScanBTicketChoice(index: idx, title: position)
                            }
                        }
                    } else {
                        self.alert = ScanBAlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                            message: response.message ?? UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
                        )
                    }
                case .failure(let error):
                    self.alert = ScanBAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    func selectTicketChoice(_ choice: ScanBTicketChoice) {
        var param = Dictionary<String, Any>()
        param["inventoryId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? ""
        param["accountId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? ""
        param["componentCode"] = inputCode
        param["machineModel"] = model ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineCode
        param["modelCode"] = modelCode ?? ""
        param["actionType"] = jobIndex
        param["isErrorInvestigation"] = false

        isLoading = true
        networkManager.scanDocB(isErrorInvestigation: false, param: param) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                if case .success(let response) = result, response.code == 200 {
                    let tickets = response.data ?? []
                    if tickets.indices.contains(choice.index) {
                        self.handleTicketSelection(tickets[choice.index])
                    }
                }
            }
        }
    }

    func confirmResetAndNavigate() {
        guard let ticket = pendingResetConfirm else { return }
        pendingResetConfirm = nil
        navigateInventoryDetail(ticket: ticket, resetInventory: jobIndex == 0)
    }

    func cancelResetConfirm() {
        pendingResetConfirm = nil
    }

    func clearTicketChoices() {
        ticketChoices = []
    }

    func clearDestination() {
        destination = nil
    }

    private func handleTicketSelection(_ ticket: DetailResponseDataTicket) {
        let status = ticket.inventoryDoc?.status ?? 0

        if jobIndex == 0 {
            if status >= 3 {
                pendingResetConfirm = ticket
            } else {
                navigateInventoryDetail(ticket: ticket, resetInventory: false)
            }
            return
        }

        if UserDefault.shared.getUserID() == ticket.inventoryDoc?.inventoryBy {
            alert = ScanBAlertMessage(title: "Thông báo".localized(), message: "Bạn không được xác nhận phiếu này".localized())
            return
        }

        if status >= 5 {
            pendingResetConfirm = ticket
        } else {
            navigateInventoryDetail(ticket: ticket, resetInventory: false)
        }
    }

    private func navigateInventoryDetail(ticket: DetailResponseDataTicket, resetInventory: Bool) {
        destination = ScanBLegacyDestination {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let vc = storyboard.instantiateViewController(withIdentifier: "InventoryDetailViewController") as? InventoryDetailViewController else { return UIViewController() }
            if let histories = ticket.histories {
                for item in histories where (item.evicenceImg ?? "").isEmpty == false {
                    vc.evicenceImg = item.evicenceImg
                    break
                }
            }
            vc.dataTicket = ticket
            vc.isConfirmScan = self.jobIndex == 1
            vc.jobIndex = self.jobIndex
            vc.resetInventory = resetInventory
            return vc
        }
    }
}

struct ScanTicketBSwiftUIView: View {
    @ObservedObject private var viewModel: ScanTicketBSwiftUIViewModel
    @State private var showResetDialog = false
    @State private var showNativeScanner = false

    private var inputCodeBinding: Binding<String> {
        Binding(
            get: { viewModel.inputCode },
            set: { viewModel.inputCode = $0 }
        )
    }

    private var headerTitle: String {
        if viewModel.jobIndex == 0 {
            return "Danh sách LK chưa kiểm kê".localized()
        }
        return "Danh sách LK chờ xác nhận".localized()
    }

    init(titleNavi: String, jobIndex: Int, model: String?, modelCode: String?, machineType: String?, lineCode: String, listDocB: ListDocB) {
        viewModel = ScanTicketBSwiftUIViewModel(titleNavi: titleNavi, jobIndex: jobIndex, model: model, modelCode: modelCode, machineType: machineType, lineCode: lineCode, listDocB: listDocB)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 14) {
                HStack {
                    Text(headerTitle)
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Text(viewModel.finishText)
                        .font(.system(size: 13, weight: .semibold))
                }

                TextField("Nhập mã linh kiện...".localized(), text: inputCodeBinding)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(.horizontal, 12)
                    .frame(height: 46)
                    .background(Color(UIColor(named: R.color.grey1.name) ?? .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button("Gửi".localized()) {
                    viewModel.sendCode()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .foregroundColor(.white)
                .background(Color(UIColor(named: R.color.buttonBlue.name) ?? .systemBlue))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 10) {
                    Button("Danh sách".localized()) {
                        viewModel.openListNotInventory()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 1))

                    Button("Quét camera".localized()) {
                        showNativeScanner = true
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 1))
                }

                Spacer()
            }
            .padding(16)

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
        .onAppear {
            viewModel.onAppear()
        }
        .onReceive(viewModel.$pendingResetConfirm) { pending in
            showResetDialog = pending != nil
        }
        .alert(item: $viewModel.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("Đồng ý".localized())))
        }
        .confirmationDialog("Chọn vị trí".localized(), isPresented: Binding(
            get: { !viewModel.ticketChoices.isEmpty },
            set: { shown in
                if !shown {
                    viewModel.clearTicketChoices()
                }
            }
        ), titleVisibility: .visible) {
            ForEach(viewModel.ticketChoices) { choice in
                Button(choice.title) {
                    viewModel.clearTicketChoices()
                    viewModel.selectTicketChoice(choice)
                }
            }
            Button("Hủy".localized(), role: .cancel) {
                viewModel.clearTicketChoices()
            }
        }
        .confirmationDialog("Thông báo".localized(), isPresented: $showResetDialog, titleVisibility: .visible) {
            Button("Đồng ý".localized()) {
                viewModel.confirmResetAndNavigate()
            }
            Button("Hủy bỏ".localized(), role: .cancel) {
                viewModel.cancelResetConfirm()
            }
        } message: {
            Text(viewModel.jobIndex == 0 ? "Đã được kiểm kê. Bạn có muốn kiểm kê lại không".localized() : "Đã được xác nhận. Bạn có muốn xác nhận lại không".localized())
        }
        .fullScreenCover(item: $viewModel.destination, onDismiss: {
            viewModel.clearDestination()
        }) { destination in
            ScanBLegacyHost {
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

private struct ScanBLegacyHost: UIViewControllerRepresentable {
    let build: () -> UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        build()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
