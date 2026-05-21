import SwiftUI
import Localize_Swift

private enum TicketListMode {
    case docAE
    case docB
    case docC
}

struct TicketListAlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct TicketListLegacyDestination: Identifiable {
    let id = UUID()
    let build: () -> UIViewController
}

final class ListAccessoryNotInventorySwiftUIViewModel: ObservableObject {
    @Published var docAEItems: [DocAEInfoModels]
    @Published var docBItems: [DocBInfoModels]
    @Published var docCItems: [DocCInfoModels]
    @Published var alert: TicketListAlertMessage?
    @Published var destination: TicketListLegacyDestination?
    @Published var isLoading = false
    @Published var chooseTicketPositions: [String] = []

    let titleString: String
    let jobIndex: Int

    private let mode: TicketListMode
    private let model: String?
    private let modelCode: String?
    private let machineType: String?
    private let lineCode: String
    private let currentUserID = UserDefault.shared.getUserID()
    private let networkManager = NetworkManager()
    private var aeDetailTickets: [DetailResponseDataTicket] = []

    init(
        titleString: String,
        jobIndex: Int
    ) {
        self.titleString = titleString
        self.jobIndex = jobIndex
        self.model = nil
        self.modelCode = nil
        self.machineType = nil
        self.lineCode = ""
        self.docAEItems = []
        self.docBItems = []
        self.docCItems = []
        self.mode = .docAE
    }

    init(
        titleString: String,
        jobIndex: Int,
        model: String?,
        modelCode: String?,
        machineType: String?,
        lineCode: String,
        docBItems: [DocBInfoModels]
    ) {
        self.titleString = titleString
        self.jobIndex = jobIndex
        self.model = model
        self.modelCode = modelCode
        self.machineType = machineType
        self.lineCode = lineCode
        self.docAEItems = []
        self.docBItems = docBItems
        self.docCItems = []
        self.mode = .docB
    }

    init(
        titleString: String,
        jobIndex: Int,
        model: String?,
        machineType: String?,
        lineCode: String,
        docCItems: [DocCInfoModels]
    ) {
        self.titleString = titleString
        self.jobIndex = jobIndex
        self.model = model
        self.modelCode = nil
        self.machineType = machineType
        self.lineCode = lineCode
        self.docAEItems = []
        self.docBItems = []
        self.docCItems = docCItems
        self.mode = .docC
    }

    var emptyText: String {
        "Không có dữ liệu".localized()
    }

    var headerText: String {
        if mode == .docAE {
            return jobIndex == 0 ? "Danh sách LK chưa kiểm kê".localized() : "Danh sách LK chờ xác nhận".localized()
        }
        if mode == .docC {
            return jobIndex == 0 ? "Danh sách phiếu chưa kiểm kê".localized() : "Danh sách phiếu chờ xác nhận".localized()
        }
        return jobIndex == 0 ? "Danh sách LK chưa kiểm kê".localized() : "Danh sách LK chờ xác nhận".localized()
    }

    func onAppear() {
        guard mode == .docAE else { return }
        loadDocAEList()
    }

    func onTapDocAE(_ item: DocAEInfoModels) {
        guard let inventoryId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId,
              let accountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId else { return }

        var param = Dictionary<String, Any>()
        param["positionCode"] = item.positionCode ?? ""
        param["docCode"] = item.docCode ?? ""
        param["isErrorInvestigation"] = "false"

        isLoading = true
        networkManager.getDetailTicket(inventoryId: inventoryId, accountId: accountId, componentCode: item.componentCode ?? "", isConfirm: jobIndex == 1, param: param) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 {
                        let tickets = response.data ?? []
                        self.aeDetailTickets = tickets
                        if tickets.count == 1, let one = tickets.first {
                            self.navigateInventoryDetail(ticket: one)
                        } else {
                            self.chooseTicketPositions = tickets.map { $0.inventoryDoc?.positionCode ?? "" }
                        }
                    } else {
                        self.alert = TicketListAlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                            message: response.message ?? UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
                        )
                    }
                case .failure(let error):
                    self.alert = TicketListAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    func selectDocAETicketPosition(index: Int) {
        guard aeDetailTickets.indices.contains(index) else {
            chooseTicketPositions = []
            return
        }
        let ticket = aeDetailTickets[index]
        chooseTicketPositions = []
        navigateInventoryDetail(ticket: ticket)
    }

    func clearTicketPositions() {
        chooseTicketPositions = []
    }

    func onTapDocB(_ item: DocBInfoModels) {
        var param = Dictionary<String, Any>()
        param["inventoryId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? ""
        param["accountId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? ""
        param["componentCode"] = item.componentCode ?? ""
        param["machineModel"] = model ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineCode
        param["modelCode"] = modelCode ?? ""
        param["actionType"] = jobIndex

        isLoading = true
        networkManager.scanDocB(isErrorInvestigation: false, param: param) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 {
                        guard let ticket = response.data?.first else {
                            self.alert = TicketListAlertMessage(title: "Lỗi".localized(), message: "Không tìm thấy phiếu phù hợp".localized())
                            return
                        }
                        self.navigateInventoryDetail(ticket: ticket)
                    } else {
                        self.alert = TicketListAlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                            message: response.message ?? UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
                        )
                    }
                case .failure(let error):
                    self.alert = TicketListAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    func onTapDocC(_ item: DocCInfoModels) {
        if jobIndex == 0 {
            if item.confirmedBy == currentUserID {
                destination = TicketListLegacyDestination {
                    guard let vc = Storyboards.waitConfirmationC.instantiate() as? WaitConfirmationViewController else { return UIViewController() }
                    vc.isBackThreeSeconds = false
                    vc.documentId = item.id ?? ""
                    return vc
                }
            } else {
                destination = TicketListLegacyDestination {
                    guard let vc = Storyboards.ballotCount.instantiate() as? BallotCountViewController else { return UIViewController() }
                    vc.documentId = item.id
                    vc.viewController = 1
                    return vc
                }
            }
            return
        }

        if (item.status ?? 0) <= 2 {
            alert = TicketListAlertMessage(title: "Lỗi".localized(), message: "Công đoạn này chưa được thực hiện kiểm kê. Vui lòng thử lại".localized())
            return
        }

        if item.inventoryBy == currentUserID {
            destination = TicketListLegacyDestination {
                guard let vc = Storyboards.waitConfirmationC.instantiate() as? WaitConfirmationViewController else { return UIViewController() }
                vc.isBackThreeSeconds = false
                vc.documentId = item.id ?? ""
                return vc
            }
        } else {
            destination = TicketListLegacyDestination {
                guard let vc = Storyboards.AccepticketC.instantiate() as? AccepticketCController else { return UIViewController() }
                vc.documentId = item.id
                return vc
            }
        }
    }

    func clearDestination() {
        destination = nil
    }

    private func loadDocAEList() {
        var param = Dictionary<String, Any>()
        param["inventoryId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? ""
        param["accountId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? ""
        param["actionType"] = jobIndex
        param["pageNum"] = 1
        param["pageSize"] = 20

        isLoading = true
        networkManager.getListdocAE(param: param) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 {
                        let items = response.data?.docAEInfoModels ?? []
                        if self.jobIndex == 0 {
                            self.docAEItems = items.filter { $0.status == 2 }
                        } else {
                            self.docAEItems = items.filter { $0.status == 3 }
                        }
                    } else {
                        self.alert = TicketListAlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                            message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
                        )
                    }
                case .failure(let error):
                    self.alert = TicketListAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    private func navigateInventoryDetail(ticket: DetailResponseDataTicket) {
        destination = TicketListLegacyDestination {
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
            vc.resetInventory = false
            return vc
        }
    }
}

struct ListAccessoryNotInventorySwiftUIView: View {
    @SwiftUI.Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var viewModel: ListAccessoryNotInventorySwiftUIViewModel

    init(titleString: String, jobIndex: Int, model: String?, modelCode: String?, machineType: String?, lineCode: String, docBItems: [DocBInfoModels]) {
        viewModel = ListAccessoryNotInventorySwiftUIViewModel(titleString: titleString, jobIndex: jobIndex, model: model, modelCode: modelCode, machineType: machineType, lineCode: lineCode, docBItems: docBItems)
    }

    init(titleString: String, jobIndex: Int) {
        viewModel = ListAccessoryNotInventorySwiftUIViewModel(titleString: titleString, jobIndex: jobIndex)
    }

    init(titleString: String, jobIndex: Int, model: String?, machineType: String?, lineCode: String, docCItems: [DocCInfoModels]) {
        viewModel = ListAccessoryNotInventorySwiftUIViewModel(titleString: titleString, jobIndex: jobIndex, model: model, machineType: machineType, lineCode: lineCode, docCItems: docCItems)
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.headerText)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                if viewModel.docAEItems.isEmpty && viewModel.docBItems.isEmpty && viewModel.docCItems.isEmpty {
                    Text(viewModel.emptyText)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        if !viewModel.docAEItems.isEmpty {
                            ForEach(Array(viewModel.docAEItems.enumerated()), id: \.offset) { pair in
                                let item = pair.element
                                Button {
                                    viewModel.onTapDocAE(item)
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.componentCode ?? "")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text(item.positionCode ?? "")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        } else if viewModel.docCItems.isEmpty {
                            ForEach(Array(viewModel.docBItems.enumerated()), id: \.offset) { pair in
                                let item = pair.element
                                Button {
                                    viewModel.onTapDocB(item)
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.componentCode ?? "")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text(item.positionCode ?? "")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        } else {
                            ForEach(Array(viewModel.docCItems.enumerated()), id: \.offset) { pair in
                                let item = pair.element
                                Button {
                                    viewModel.onTapDocC(item)
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Cụm ảo".localized())
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Text(item.modelCode ?? "")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.primary)
                                        }
                                        HStack {
                                            Text("STT công đoạn".localized())
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Text(item.stageNumber ?? "")
                                                .font(.system(size: 13))
                                                .foregroundColor(.primary)
                                        }
                                        HStack {
                                            Text("Tên công đoạn".localized())
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.gray)
                                            Spacer()
                                            Text(item.stageName ?? "")
                                                .font(.system(size: 13))
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }

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
        .navigationTitle(viewModel.titleString)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .alert(item: $viewModel.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("Đồng ý".localized())))
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
                    viewModel.selectDocAETicketPosition(index: index)
                }
            }
            Button("Hủy".localized(), role: .cancel) {
                viewModel.clearTicketPositions()
            }
        }
        .fullScreenCover(item: $viewModel.destination, onDismiss: {
            viewModel.clearDestination()
        }) { destination in
            TicketListLegacyHost {
                let vc = destination.build()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                return nav
            }
            .ignoresSafeArea()
        }
    }
}

private struct TicketListLegacyHost: UIViewControllerRepresentable {
    let build: () -> UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        build()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
