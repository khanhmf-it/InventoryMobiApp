import SwiftUI
import Localize_Swift

struct ScanCAlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct ScanCLegacyDestination: Identifiable {
    let id = UUID()
    let build: () -> UIViewController
}

final class ScanTicketCSwiftUIViewModel: ObservableObject {
    @Published var clusterCode: String = ""
    @Published var stageName: String = ""
    @Published var listDocC: ArrayData
    @Published var isLoading = false
    @Published var alert: ScanCAlertMessage?
    @Published var destination: ScanCLegacyDestination?

    private let titleNavi: String
    let jobIndex: Int
    private let model: String?
    private let machineType: String?
    private let lineCode: String
    private let networkManager = NetworkManager()
    private let currentUserID = UserDefault.shared.getUserID()

    init(titleNavi: String, jobIndex: Int, model: String?, machineType: String?, lineCode: String, listDocC: ArrayData) {
        self.titleNavi = titleNavi
        self.jobIndex = jobIndex
        self.model = model
        self.machineType = machineType
        self.lineCode = lineCode
        self.listDocC = listDocC
    }

    var finishText: String {
        "\(listDocC.finishCount ?? 0) / \(listDocC.totalCount ?? 0)"
    }

    func onAppear() {
        refreshListDocC()
    }

    func refreshListDocC() {
        scanListDocC(stage: "", modelCode: "")
    }

    func openListNotInventory() {
        let filtered: [DocCInfoModels]
        if jobIndex == 0 {
            filtered = listDocC.docCInfoModels?.filter({ $0.status == 2 }) ?? []
        } else {
            filtered = listDocC.docCInfoModels?.filter({ $0.status == 3 }) ?? []
        }

        destination = ScanCLegacyDestination {
            let view = ListAccessoryNotInventorySwiftUIView(
                titleString: self.titleNavi,
                jobIndex: self.jobIndex,
                model: self.model,
                machineType: self.machineType,
                lineCode: self.lineCode,
                docCItems: filtered
            )
            return UIHostingController(rootView: view)
        }
    }

    func handleNativeScannedCode(_ code: String) {
        clusterCode = code
        sendCode()
    }

    func sendCode() {
        let code = clusterCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else {
            alert = ScanCAlertMessage(title: "Lỗi".localized(), message: "Vui lòng nhập mã cụm".localized())
            return
        }

        let hasSpecialCharacters = code.range(of: ".*[^A-Za-z0-9 ].*", options: .regularExpression) != nil
        if hasSpecialCharacters {
            alert = ScanCAlertMessage(title: "Lỗi".localized(), message: "Tên cụm không đúng định dạng. Vui lòng thử lại.".localized())
            return
        }

        scanListDocC(stage: stageName, modelCode: code)
    }

    func clearDestination() {
        destination = nil
    }

    private func scanListDocC(stage: String, modelCode: String) {
        var param = Dictionary<String, Any>()
        param["inventoryId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? ""
        param["accountId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? ""
        param["machineModel"] = model ?? ""
        param["machineType"] = machineType ?? ""
        param["lineName"] = lineCode
        param["actionType"] = jobIndex
        param["stageName"] = stage
        param["modelCode"] = modelCode

        isLoading = true
        networkManager.scanListDocC(param: param) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 {
                        self.listDocC = response.data ?? ArrayData()
                        self.routeFromScanResult(list: self.listDocC.docCInfoModels ?? [])
                    } else {
                        self.alert = ScanCAlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                            message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
                        )
                    }
                case .failure(let error):
                    self.alert = ScanCAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    private func routeFromScanResult(list: [DocCInfoModels]) {
        if list.count > 1 {
            destination = ScanCLegacyDestination {
                let view = ListAccessoryNotInventorySwiftUIView(
                    titleString: self.titleNavi,
                    jobIndex: self.jobIndex,
                    model: self.model,
                    machineType: self.machineType,
                    lineCode: self.lineCode,
                    docCItems: list
                )
                return UIHostingController(rootView: view)
            }
            return
        }

        guard let one = list.first else { return }

        if jobIndex == 0 {
            if one.confirmedBy == currentUserID {
                destination = ScanCLegacyDestination {
                    guard let vc = Storyboards.waitConfirmationC.instantiate() as? WaitConfirmationViewController else { return UIViewController() }
                    vc.documentId = one.id ?? ""
                    return vc
                }
            } else {
                destination = ScanCLegacyDestination {
                    guard let vc = Storyboards.ballotCount.instantiate() as? BallotCountViewController else { return UIViewController() }
                    vc.documentId = one.id
                    vc.viewController = 0
                    return vc
                }
            }
            return
        }

        if (one.status ?? 0) <= 2 {
            alert = ScanCAlertMessage(title: "Lỗi".localized(), message: "Công đoạn này chưa được thực hiện kiểm kê. Vui lòng thử lại".localized())
            return
        }

        if one.inventoryBy == currentUserID {
            destination = ScanCLegacyDestination {
                guard let vc = Storyboards.waitConfirmationC.instantiate() as? WaitConfirmationViewController else { return UIViewController() }
                vc.isBackThreeSeconds = false
                vc.documentId = one.id ?? ""
                return vc
            }
        } else {
            destination = ScanCLegacyDestination {
                guard let vc = Storyboards.AccepticketC.instantiate() as? AccepticketCController else { return UIViewController() }
                vc.documentId = one.id
                return vc
            }
        }
    }
}

struct ScanTicketCSwiftUIView: View {
    @ObservedObject private var viewModel: ScanTicketCSwiftUIViewModel
    @State private var showNativeScanner = false

    init(titleNavi: String, jobIndex: Int, model: String?, machineType: String?, lineCode: String, listDocC: ArrayData) {
        viewModel = ScanTicketCSwiftUIViewModel(titleNavi: titleNavi, jobIndex: jobIndex, model: model, machineType: machineType, lineCode: lineCode, listDocC: listDocC)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 14) {
                HStack {
                    Text(viewModel.jobIndex == 0 ? "Danh sách phiếu chưa kiểm kê".localized() : "Danh sách phiếu chờ xác nhận".localized())
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Text(viewModel.finishText)
                        .font(.system(size: 13, weight: .semibold))
                }

                TextField("Nhập tên công đoạn".localized(), text: $viewModel.stageName)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(Color(UIColor(named: R.color.grey1.name) ?? .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                TextField("Nhập mã cụm".localized(), text: $viewModel.clusterCode)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
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
        .navigationTitle("Quét mã cụm".localized())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
        .alert(item: $viewModel.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("Đồng ý".localized())))
        }
        .fullScreenCover(item: $viewModel.destination, onDismiss: {
            viewModel.clearDestination()
        }) { destination in
            ScanCLegacyHost {
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

private struct ScanCLegacyHost: UIViewControllerRepresentable {
    let build: () -> UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        build()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
