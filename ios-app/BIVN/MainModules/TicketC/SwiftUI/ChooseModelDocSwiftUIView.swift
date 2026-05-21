import SwiftUI
import Moya
import Localize_Swift

struct ChooseAlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct ChooseLegacyDestination: Identifiable {
    let id = UUID()
    let build: () -> UIViewController
}

final class ChooseModelDocSwiftUIViewModel: ObservableObject {
    @Published var modelText: String = ""
    @Published var machineText: String = ""
    @Published var modelCodeText: String = ""
    @Published var lineText: String = ""

    @Published var modelOptions: [String] = []
    @Published var machineOptions: [DataResut] = []
    @Published var modelCodeOptions: [String] = []
    @Published var lineOptions: [DataResut] = []

    @Published var selectedModel: String?
    @Published var selectedMachineType: String?
    @Published var selectedModelCode: String?
    @Published var selectedLineCode: String = ""

    @Published var isLoading = false
    @Published var alert: ChooseAlertMessage?
    @Published var destination: ChooseLegacyDestination?

    let titleString: String
    let jobIndex: Int
    let docType: String

    private let titleJob: String
    private let networkManager = NetworkManager()

    init(titleString: String, jobIndex: Int, docType: String, titleJob: String) {
        self.titleString = titleString
        self.jobIndex = jobIndex
        self.docType = docType
        self.titleJob = titleJob
    }

    func onAppear() {
        loadInitialModels()
    }

    func onSelectModel(_ item: String) {
        selectedModel = item
        modelText = item

        machineText = ""
        modelCodeText = ""
        lineText = ""
        selectedMachineType = nil
        selectedModelCode = nil
        selectedLineCode = ""
        machineOptions = []
        modelCodeOptions = []
        lineOptions = []

        if docType == "B" {
            getListDropdownMachineB(model: item)
        } else {
            getListDropdownMachine(modelCode: item)
        }
    }

    func onSelectMachine(_ item: DataResut) {
        selectedMachineType = item.key
        machineText = item.displayName ?? ""

        modelCodeText = ""
        lineText = ""
        selectedModelCode = nil
        selectedLineCode = ""
        modelCodeOptions = []
        lineOptions = []

        if docType == "B" {
            getListDropdownModelCodeB(machineModel: selectedModel ?? "", machineType: item.key ?? "")
        } else {
            getListDropdownLines(modelCode: selectedModel ?? "", machineType: item.key ?? "")
        }
    }

    func onSelectModelCode(_ item: String) {
        selectedModelCode = item
        modelCodeText = item

        lineText = ""
        selectedLineCode = ""
        lineOptions = []

        getListDropdownLinesB(machineModel: selectedModel ?? "", machineType: selectedMachineType ?? "", modelCode: item)
    }

    func onSelectLine(_ item: DataResut) {
        lineText = item.displayName ?? ""
        selectedLineCode = item.key ?? ""
    }

    func reset() {
        modelText = ""
        machineText = ""
        modelCodeText = ""
        lineText = ""

        selectedModel = nil
        selectedMachineType = nil
        selectedModelCode = nil
        selectedLineCode = ""

        machineOptions = []
        modelCodeOptions = []
        lineOptions = []
    }

    func confirm() {
        if docType == "C" {
            fetchListDocC()
        } else {
            fetchListDocB()
        }
    }

    func clearDestination() {
        destination = nil
    }

    private func loadInitialModels() {
        if docType == "B" {
            getListDropdownModelB()
        } else {
            getListDropdownModel()
        }
    }

    private func getListDropdownModelB() {
        guard let accountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId,
              let inventoryId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId else { return }

        isLoading = true
        networkManager.getListDropdownModelB(inventoryId: inventoryId, accountId: accountId) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 {
                        self.modelOptions = response.arrayOfStrings
                    } else {
                        self.alert = ChooseAlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code),
                            message: UserDefault.shared.showErrorText(errorCode: response.code)
                        )
                    }
                case .failure(let error):
                    self.alert = ChooseAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    private func getListDropdownMachineB(model: String) {
        guard let accountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId,
              let inventoryId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId else { return }

        isLoading = true
        networkManager.getListDropdownMachinesB(inventoryId: inventoryId, accountId: accountId, modelCode: model) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    self.machineOptions = response.data ?? []
                case .failure(let error):
                    self.alert = ChooseAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    private func getListDropdownModelCodeB(machineModel: String, machineType: String) {
        guard let accountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId,
              let inventoryId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId else { return }

        isLoading = true
        networkManager.getListDropdownModelCodeB(inventoryId: inventoryId, accountId: accountId, machineModel: machineModel, machineType: machineType) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    self.modelCodeOptions = response.arrayOfStrings
                case .failure(let error):
                    self.alert = ChooseAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    private func getListDropdownLinesB(machineModel: String, machineType: String, modelCode: String) {
        guard let accountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId,
              let inventoryId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId else { return }

        isLoading = true
        networkManager.getListDropdownLinesB(inventoryId: inventoryId, accountId: accountId, machineModel: machineModel, machineType: machineType, modelCode: modelCode) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    self.lineOptions = response.data ?? []
                case .failure(let error):
                    self.alert = ChooseAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    private func getListDropdownModel() {
        guard let accountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId,
              let inventoryId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId else { return }

        isLoading = true
        networkManager.getListDropdownModel(inventoryId: inventoryId, accountId: accountId) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 {
                        self.modelOptions = response.arrayOfStrings
                    } else {
                        self.alert = ChooseAlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code),
                            message: UserDefault.shared.showErrorText(errorCode: response.code)
                        )
                    }
                case .failure(let error):
                    self.alert = ChooseAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    private func getListDropdownMachine(modelCode: String) {
        guard let accountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId,
              let inventoryId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId else { return }

        isLoading = true
        networkManager.getListDropdownMachines(inventoryId: inventoryId, accountId: accountId, modelCode: modelCode) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    self.machineOptions = response.data ?? []
                case .failure(let error):
                    self.alert = ChooseAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    private func getListDropdownLines(modelCode: String, machineType: String) {
        guard let accountId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId,
              let inventoryId = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId else { return }

        isLoading = true
        networkManager.getListDropdownLines(inventoryId: inventoryId, accountId: accountId, modelCode: modelCode, machineType: machineType) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    self.lineOptions = response.data ?? []
                case .failure(let error):
                    self.alert = ChooseAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    private func fetchListDocB() {
        var params = Dictionary<String, Any>()
        params["inventoryId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? ""
        params["accountId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? ""
        params["machineModel"] = selectedModel ?? ""
        params["machineType"] = selectedMachineType ?? ""
        params["lineName"] = selectedLineCode
        params["actionType"] = jobIndex
        params["stageName"] = ""
        params["modelCode"] = selectedModelCode ?? ""
        params["pageNum"] = 1
        params["pageSize"] = 20

        isLoading = true
        networkManager.getListdocB(param: params) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 {
                        self.destination = ChooseLegacyDestination {
                            let view = ScanTicketBSwiftUIView(
                                titleNavi: self.titleString,
                                jobIndex: self.jobIndex,
                                model: self.selectedModel,
                                modelCode: self.selectedModelCode,
                                machineType: self.selectedMachineType,
                                lineCode: self.selectedLineCode,
                                listDocB: response.data ?? ListDocB()
                            )
                            return UIHostingController(rootView: view)
                        }
                    } else {
                        self.alert = ChooseAlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                            message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
                        )
                    }
                case .failure(let error):
                    self.alert = ChooseAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }

    private func fetchListDocC() {
        var params = Dictionary<String, Any>()
        params["inventoryId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? ""
        params["accountId"] = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? ""
        params["machineModel"] = selectedModel ?? ""
        params["machineType"] = selectedMachineType ?? ""
        params["lineName"] = selectedLineCode
        params["actionType"] = jobIndex
        params["stageName"] = ""
        params["modelCode"] = ""
        params["pageNum"] = 1
        params["pageSize"] = 20

        isLoading = true
        networkManager.scanListDocC(param: params) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 {
                        self.destination = ChooseLegacyDestination {
                            let view = ScanTicketCSwiftUIView(
                                titleNavi: self.titleString,
                                jobIndex: self.jobIndex,
                                model: self.selectedModel,
                                machineType: self.selectedMachineType,
                                lineCode: self.selectedLineCode,
                                listDocC: response.data ?? ArrayData()
                            )
                            return UIHostingController(rootView: view)
                        }
                    } else {
                        self.alert = ChooseAlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                            message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
                        )
                    }
                case .failure(let error):
                    self.alert = ChooseAlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                }
            }
        }
    }
}

struct ChooseModelDocSwiftUIView: View {
    @ObservedObject private var viewModel: ChooseModelDocSwiftUIViewModel

    init(titleString: String, jobIndex: Int, docType: String, titleJob: String) {
        viewModel = ChooseModelDocSwiftUIViewModel(titleString: titleString, jobIndex: jobIndex, docType: docType, titleJob: titleJob)
    }

    var body: some View {
        ZStack {
            Form {
                Section {
                    PickerField(
                        title: "Model",
                        value: viewModel.modelText.isEmpty ? "Lựa chọn model".localized() : viewModel.modelText,
                        options: viewModel.modelOptions,
                        onSelect: { item in viewModel.onSelectModel(item) }
                    )

                    PickerField(
                        title: "Dòng máy".localized(),
                        value: viewModel.machineText.isEmpty ? "Lựa chọn dòng máy".localized() : viewModel.machineText,
                        options: viewModel.machineOptions.compactMap { $0.displayName },
                        onSelect: { text in
                            guard let item = viewModel.machineOptions.first(where: { $0.displayName == text }) else { return }
                            viewModel.onSelectMachine(item)
                        }
                    )

                    if viewModel.docType == "B" {
                        PickerField(
                            title: "Model code",
                            value: viewModel.modelCodeText.isEmpty ? "Lựa chọn model code".localized() : viewModel.modelCodeText,
                            options: viewModel.modelCodeOptions,
                            onSelect: { item in viewModel.onSelectModelCode(item) }
                        )
                    }

                    PickerField(
                        title: "Chuyền".localized(),
                        value: viewModel.lineText.isEmpty ? "Lựa chọn chuyền".localized() : viewModel.lineText,
                        options: viewModel.lineOptions.compactMap { $0.displayName },
                        onSelect: { text in
                            guard let item = viewModel.lineOptions.first(where: { $0.displayName == text }) else { return }
                            viewModel.onSelectLine(item)
                        }
                    )
                }

                Section {
                    Button("Reset".localized()) {
                        viewModel.reset()
                    }

                    Button("Confirm".localized()) {
                        viewModel.confirm()
                    }
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
        .alert(item: $viewModel.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("Đồng ý".localized())))
        }
        .fullScreenCover(item: $viewModel.destination, onDismiss: {
            viewModel.clearDestination()
        }) { destination in
            ChooseLegacyHost {
                let vc = destination.build()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                return nav
            }
            .ignoresSafeArea()
        }
    }
}

private struct PickerField: View {
    let title: String
    let value: String
    let options: [String]
    let onSelect: (String) -> Void

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { item in
                Button(item) {
                    onSelect(item)
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(value)
                        .font(.system(size: 15))
                        .foregroundColor(.black)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 6)
        }
    }
}

private struct ChooseLegacyHost: UIViewControllerRepresentable {
    let build: () -> UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        build()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
