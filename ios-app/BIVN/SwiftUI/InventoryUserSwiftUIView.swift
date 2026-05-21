import SwiftUI
import Moya
import Localize_Swift

final class InventoryUserSwiftUIViewModel: ObservableObject {
    @Published var userID: String = ""
    @Published var userIDError: String = ""
    @Published var isLoading = false
    @Published var alert: AlertMessage?

    private weak var router: AppLaunchRouter?
    private let networkManager = NetworkManager()

    init(router: AppLaunchRouter) {
        self.router = router
    }

    func handleUserIDChange(_ newValue: String) {
        userID = String(newValue.uppercased().prefix(8))
        userIDError = ""
    }

    func submitUserID() {
        let value = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            userIDError = "Vui lòng nhập mã nhân viên.".localized()
            return
        }

        if !value.checkUserId() {
            alert = AlertMessage(title: "Lỗi".localized(), message: "Mã nhân viên không đúng định dạng. Vui lòng kiểm tra và thao tác lại.".localized())
            return
        }

        UserDefaults.standard.set(value, forKey: "MANHANVIEN")
        UserDefault.shared.setUserID(userID: value)
        navigateToMainByRole()
    }

    func handleScannedUserID(_ value: String) {
        userID = String(value.uppercased().prefix(8))
        submitUserID()
    }

    func logout() {
        guard InternetManager.isConnected() else {
            alert = AlertMessage(title: "Thông báo".localized(), message: "Vui lòng kiểm tra lại kết nối internet của thiết bị.".localized())
            return
        }

        isLoading = true
        var param = Dictionary<String, Any>()
        param["userId"] = UserDefault.shared.getDataLoginModel().userId ?? ""

        networkManager.logoutDeleteRequest(param: param) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    if response.code == 200 || response.code == 26 {
                        UserDefaults.standard.removeObject(forKey: "dataLoginModel")
                        UserDefaults.standard.removeObject(forKey: "nameWifi")
                        UserDefault.shared.setUserID(userID: "")
                        self.router?.navigateToLogin()
                    } else {
                        self.alert = AlertMessage(
                            title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                            message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
                        )
                    }
                case .failure(let error):
                    if case MoyaError.underlying(let underlyingError, _) = error,
                       (underlyingError as NSError).code == 13 {
                        self.alert = AlertMessage(title: "Thông báo".localized(), message: "Không nhận được phản hồi từ hệ thống, hãy kiểm tra lại server".localized())
                    } else {
                        self.alert = AlertMessage(title: "Lỗi".localized(), message: error.localizedDescription)
                    }
                }
            }
        }
    }

    private func navigateToMainByRole() {
        let roleType = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryRoleType
        if roleType == 2 || roleType == 0 {
            router?.navigateToMain(role: .inventory)
        } else {
            router?.navigateToMain(role: .monitor)
        }
    }
}

struct InventoryUserSwiftUIView: View {
    @ObservedObject private var viewModel: InventoryUserSwiftUIViewModel
    @State private var showScanner = false

    init(router: AppLaunchRouter) {
        viewModel = InventoryUserSwiftUIViewModel(router: router)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(UserDefault.shared.getDataLoginModel().username ?? "")
                            .font(.system(size: 14, weight: .semibold))
                        Text(UserDefault.shared.getUserID())
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button("Đăng xuất".localized()) {
                        viewModel.logout()
                    }
                    .font(.system(size: 13, weight: .semibold))
                }

                VStack(spacing: 8) {
                    Image(R.image.ic_scan.name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)
                    Text("Đưa camera hướng về mã nhân viên".localized())
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.top, 18)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Nhập mã nhân viên".localized())
                        .font(.system(size: 14, weight: .medium))
                    TextField(
                        "Nhập mã nhân viên...".localized(),
                        text: Binding(
                            get: { viewModel.userID },
                            set: { viewModel.handleUserIDChange($0) }
                        )
                    )
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled(true)
                        .padding(.horizontal, 12)
                        .frame(height: 46)
                        .background(Color(UIColor(named: R.color.grey1.name) ?? .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    if !viewModel.userIDError.isEmpty {
                        Text(viewModel.userIDError)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }

                Button("Lưu".localized()) {
                    viewModel.submitUserID()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .foregroundColor(.white)
                .background(Color(UIColor(named: R.color.buttonBlue.name) ?? .systemBlue))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button("Quét camera".localized()) {
                    showScanner = true
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundColor(Color(UIColor(named: R.color.buttonBlue.name) ?? .systemBlue))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(UIColor(named: R.color.buttonBlue.name) ?? .systemBlue), lineWidth: 1)
                )

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
        .navigationTitle("Quét mã nhân viên".localized())
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("Đồng ý".localized())))
        }
        .fullScreenCover(isPresented: $showScanner) {
            CodeScannerSwiftUIView { code in
                viewModel.handleScannedUserID(code)
            }
            .ignoresSafeArea()
        }
    }
}
