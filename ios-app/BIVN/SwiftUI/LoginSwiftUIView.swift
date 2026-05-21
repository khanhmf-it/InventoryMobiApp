import UIKit
import SwiftUI
import Moya
import Localize_Swift

final class LoginSwiftUIViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var password: String = ""
    @Published var isSecurePassword: Bool = true
    @Published var selectedLanguage: String = "vi"
    @Published var selectedWifi: String = "bivnioswifim01"
    @Published var userNameError: String = ""
    @Published var passwordError: String = ""
    @Published var isLoading: Bool = false
    @Published var alert: AlertMessage?

    private let networkManager = NetworkManager()
    private weak var router: AppLaunchRouter?

    init(router: AppLaunchRouter) {
        self.router = router
        loadDefaultData()
    }

    func loadDefaultData() {
        let languageSetting = UserDefaults.standard.string(forKey: "AppLanguage")
        selectedLanguage = languageSetting ?? "vi"
        Localize.setCurrentLanguage(selectedLanguage)

        let wifi = UserDefaults.standard.string(forKey: "nameWifi")
        selectedWifi = wifi ?? "bivnioswifim01"
        UserDefaults.standard.set(selectedWifi, forKey: "nameWifi")
    }

    func changeLanguage(_ language: String) {
        selectedLanguage = language
        Localize.setCurrentLanguage(language)
        UserDefaults.standard.set(language, forKey: "AppLanguage")
        updateErrorMessagesForCurrentLanguage()
    }

    func setWifi(_ wifi: String) {
        selectedWifi = wifi
        UserDefaults.standard.set(wifi, forKey: "nameWifi")
    }

    func handlePasswordChange(_ value: String) {
        password = value.removeWhitespace()

        guard !password.isEmpty else {
            passwordError = ""
            return
        }

        if password.count < 8 || password.count > 15 || !containsLetterAndNumber(password) {
            passwordError = "Mật khẩu phải có độ dài từ 8 - 15 ký tự,bao gồm cả ký tự chữ và số , không chứa ký tự khoảng trắng.".localized()
        } else {
            passwordError = ""
        }
    }

    func login() {
        UserDefaults.standard.set(userName, forKey: "userNameLogin")

        guard InternetManager.isConnected() else {
            alert = AlertMessage(title: "Thông báo".localized(), message: "Vui lòng kiểm tra lại kết nối internet của thiết bị.".localized())
            return
        }

        guard validateLoginInput() else { return }

        isLoading = true
        var params = Dictionary<String, Any>()
        params["username"] = userName
        params["password"] = password
        params["deviceId"] = UIDevice.current.identifierForVendor?.uuidString

        networkManager.loginPostRequest(param: params) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    self.handleLoginResponse(response)
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

    private func handleLoginResponse(_ response: LoginModel) {
        if response.code == 200 {
            userNameError = ""
            passwordError = ""
            UserDefault.shared.setUserID(userID: "")

            if let encodedObject = try? JSONEncoder().encode(response.data) {
                UserDefaults.standard.set(encodedObject, forKey: "dataLoginModel")
            }

            if AccountType.generalAccount.rawValue == response.data?.accountType {
                router?.navigateToInventoryUser()
                return
            }

            if AccountType.monitoringAccount.rawValue == response.data?.accountType {
                let roleType = UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryRoleType
                if roleType == UIViewController.inventory || roleType == UIViewController.promote {
                    router?.navigateToMain(role: .inventory)
                } else if roleType == UIViewController.monitor {
                    router?.navigateToMain(role: .monitor)
                } else {
                    router?.navigateToMain(role: .inventory)
                }
                return
            }

            let role: TypeRole = UserDefault.shared.getDataLoginModel().mobileAccess == TypeRole.mc.value ? .mc : .pcb
            router?.navigateToMain(role: role)
            return
        }

        let title = UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0)
        let message = response.message ?? UserDefault.shared.showErrorText(errorCode: response.code ?? 0)
        alert = AlertMessage(title: title, message: message)
    }

    private func validateLoginInput() -> Bool {
        var isValid = true

        if userName.removeWhitespace().isEmpty {
            userNameError = "Vui lòng nhập tài khoản đăng nhập.".localized()
            isValid = false
        } else {
            userNameError = ""
        }

        if password.isEmpty {
            passwordError = "Vui lòng nhập mật khẩu.".localized()
            isValid = false
        } else if password.count < 8 || password.count > 15 || !containsLetterAndNumber(password) {
            passwordError = "Mật khẩu phải có độ dài từ 8 - 15 ký tự,bao gồm cả ký tự chữ và số , không chứa ký tự khoảng trắng.".localized()
            isValid = false
        } else {
            passwordError = ""
        }

        return isValid
    }

    private func updateErrorMessagesForCurrentLanguage() {
        if !userNameError.isEmpty {
            userNameError = "Vui lòng nhập tài khoản đăng nhập.".localized()
        }
        if !passwordError.isEmpty {
            if password.isEmpty {
                passwordError = "Vui lòng nhập mật khẩu.".localized()
            } else {
                passwordError = "Mật khẩu phải có độ dài từ 8 - 15 ký tự,bao gồm cả ký tự chữ và số , không chứa ký tự khoảng trắng.".localized()
            }
        }
    }

    private func containsLetterAndNumber(_ input: String) -> Bool {
        var hasLetter = false
        var hasNumber = false

        for char in input {
            if char.isLetter { hasLetter = true }
            if char.isNumber { hasNumber = true }
        }

        return hasLetter && hasNumber
    }
}

struct LoginSwiftUIView: View {
    @ObservedObject private var viewModel: LoginSwiftUIViewModel

    init(router: AppLaunchRouter) {
        viewModel = LoginSwiftUIViewModel(router: router)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Spacer()
                        Image(R.image.logo_union.name)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180)
                        Spacer()
                    }
                    .padding(.bottom, 10)

                    Text("Tài khoản đăng nhập".localized())
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(UIColor(named: R.color.textDefault.name) ?? .black))

                    TextField("Nhập tài khoản đăng nhập".localized(), text: $viewModel.userName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(.horizontal, 12)
                        .frame(height: 48)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.35), lineWidth: 1))

                    if !viewModel.userNameError.isEmpty {
                        Text(viewModel.userNameError)
                            .font(.system(size: 12))
                            .foregroundColor(Color(UIColor(named: R.color.textRed.name) ?? .red))
                    }

                    Text("Mật khẩu".localized())
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(UIColor(named: R.color.textDefault.name) ?? .black))

                    ZStack(alignment: .trailing) {
                        Group {
                            if viewModel.isSecurePassword {
                                SecureField(
                                    "Nhập mật khẩu".localized(),
                                    text: Binding(
                                        get: { viewModel.password },
                                        set: { viewModel.handlePasswordChange($0) }
                                    )
                                )
                            } else {
                                TextField(
                                    "Nhập mật khẩu".localized(),
                                    text: Binding(
                                        get: { viewModel.password },
                                        set: { viewModel.handlePasswordChange($0) }
                                    )
                                )
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                            }
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 48)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.35), lineWidth: 1))

                        Button(action: {
                            viewModel.isSecurePassword.toggle()
                        }) {
                            Image(viewModel.isSecurePassword ? R.image.ic_eye.name : R.image.ic_eye_hide.name)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .padding(.trailing, 12)
                        }
                    }

                    if !viewModel.passwordError.isEmpty {
                        Text(viewModel.passwordError)
                            .font(.system(size: 12))
                            .foregroundColor(Color(UIColor(named: R.color.textRed.name) ?? .red))
                    }

                    HStack(spacing: 12) {
                        Text("Wifi")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(UIColor(named: R.color.textDefault.name) ?? .black))

                        Button(action: { viewModel.setWifi("bivnioswifim01") }) {
                            HStack(spacing: 6) {
                                Image(viewModel.selectedWifi == "bivnioswifim01" ? R.image.ic_checked.name : R.image.ic_emptyCheckBox.name)
                                Text("bivnioswifim01")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(UIColor(named: R.color.textDefault.name) ?? .black))
                            }
                        }

                        Button(action: { viewModel.setWifi("B-WINS") }) {
                            HStack(spacing: 6) {
                                Image(viewModel.selectedWifi == "B-WINS" ? R.image.ic_checked.name : R.image.ic_emptyCheckBox.name)
                                Text("B-WINS")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(UIColor(named: R.color.textDefault.name) ?? .black))
                            }
                        }
                    }
                    .padding(.top, 6)

                    HStack {
                        Text("Language")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(UIColor(named: R.color.textDefault.name) ?? .black))

                        Spacer()

                        Picker(
                            "Language",
                            selection: Binding(
                                get: { viewModel.selectedLanguage },
                                set: { viewModel.changeLanguage($0) }
                            )
                        ) {
                            Text("vi").tag("vi")
                            Text("en").tag("en")
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.top, 6)

                    Button(action: {
                        viewModel.login()
                    }) {
                        Text("Đăng nhập".localized())
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(UIColor(named: R.color.buttonBlue.name) ?? .systemBlue))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.top, 8)
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 30)
            }
            .background(Color.white.ignoresSafeArea())

            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding(20)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .alert(item: $viewModel.alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("Đồng ý".localized()))
            )
        }
    }
}
