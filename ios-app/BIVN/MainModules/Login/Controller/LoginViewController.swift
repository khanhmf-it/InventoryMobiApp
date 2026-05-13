//
//  LoginViewController.swift
//  BIVN
//
//  Created by Tinhvan on 13/09/2023.
//

import UIKit
import Moya
import SystemConfiguration.CaptiveNetwork
import CoreLocation
import Localize_Swift
import DropDown

enum TypeRole {
    case mc
    case pcb
    case inventory
    case monitor
    
    var value: String {
        get{
            switch self {
            case .mc:
                return "MC"
            case .pcb:
                return "PCB"
            case .inventory:
                return "INVENTORY"
            case .monitor:
                return "MONITOR"
            }
        }
    }
}

enum AccountType : String {
    case generalAccount = "TaiKhoanChung"
    case privateAccount = "TaiKhoanRieng"
    case monitoringAccount = "TaiKhoanGiamSat"
}

class LoginViewController: BaseViewController , UITextFieldDelegate{
    
    @IBOutlet weak var selectedStackView: UIStackView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var imgLogo: UIImageView!
    @IBOutlet weak var errorUserNameLabel: UILabel!
    @IBOutlet weak var errorPasswordLabel: UILabel!
    @IBOutlet weak var wifiLabel: UILabel!
    @IBOutlet weak var nameWifi1Button: UIButton!
    @IBOutlet weak var nameWifi2Button: UIButton!
    @IBOutlet weak var buttonDropdown: UIButton!
    @IBOutlet weak var nameLanguageLabel: UITextField!
    
    var param = Dictionary<String, Any>()
    var locationManager: CLLocationManager?
    var nameWifi: String?
    var myDropDown = DropDown()
    var listString = ["vi", "en"]
    var defaultLanguage = "vi"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorUserNameLabel.isHidden = true
        errorPasswordLabel.isHidden = true
        buttonDropdown.setTitle("", for: .normal)
        setupView()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        setupWifi()
        nameWifi1Button.isSelected = true
        UserDefaults.standard.set("bivnioswifim01", forKey: "nameWifi")
        self.hideKeyboardWhenTappedAround()
        setupDefaultValue()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUI()
    }
    
    private func setupDefaultValue() {
        getLanguageSetting()
        self.nameLanguageLabel.text = defaultLanguage
    }
    
    private func getLanguageSetting() {
        let languageSetting = UserDefaults.standard.string(forKey: "AppLanguage")
        if languageSetting == nil {
            defaultLanguage = "vi"
        } else {
            defaultLanguage = languageSetting ?? "vi"
        }
    }
    
    private func updateUI() {
        userNameLabel.text = "Tài khoản đăng nhập".localized()
        userNameTextField.placeholder = "Nhập tài khoản đăng nhập".localized()
        passwordLabel.text = "Mật khẩu".localized()
        passwordTextField.placeholder = "Nhập mật khẩu".localized()
        loginButton.setTitle("Đăng nhập".localized(), for: .normal)
    }
    
    @IBAction func onTapDropdown(_ sender: UIButton) {
        self.showDropdown()
    }
    
    private func updateErrorMessages() {
            if errorUserNameLabel.isHidden == false {
                errorUserNameLabel.text = "Vui lòng nhập tài khoản đăng nhập.".localized()
            }
            if errorPasswordLabel.isHidden == false {
                if passwordTextField.text?.isEmpty == true {
                    errorPasswordLabel.text = "Vui lòng nhập mật khẩu.".localized()
                } else {
                    errorPasswordLabel.text = "Mật khẩu phải có độ dài từ 8 - 15 ký tự, bao gồm cả ký tự chữ và số, không chứa ký tự khoảng trắng.".localized()
                }
            }
        }
    
    private func showDropdown() {
        myDropDown.dataSource = listString
        myDropDown.anchorView = buttonDropdown
        myDropDown.bottomOffset = CGPoint(x: 0, y: (nameLanguageLabel.frame.size.height))
        myDropDown.topOffset = CGPoint(x: 0, y: -(myDropDown.anchorView?.plainView.bounds.height)!)
        myDropDown.dismissMode = .onTap
        myDropDown.direction = .bottom
        self.nameLanguageLabel.text = defaultLanguage
        myDropDown.selectionAction = { (index: Int, item: String) in
            self.nameLanguageLabel.text = "\(self.listString[index])"
            self.nameLanguageLabel.textColor = .black
            let selectedLanguage = (index == 0) ? "vi" : "en"
            Localize.setCurrentLanguage(selectedLanguage)
            UserDefaults.standard.set(selectedLanguage, forKey: "AppLanguage")
            self.defaultLanguage = self.listString[index]
            self.updateErrorMessages()
        }
        myDropDown.show()
    }
    
    func setupWifi() {
        nameWifi1Button.setTitle("", for: .normal)
        nameWifi2Button.setTitle("", for: .normal)
        nameWifi1Button.setImage(UIImage.init(named: R.image.ic_emptyCheckBox.name), for: .normal)
        nameWifi1Button.setImage(UIImage.init(named: R.image.ic_checked.name), for: .selected)
        nameWifi2Button.setImage(UIImage.init(named: R.image.ic_emptyCheckBox.name), for: .normal)
        nameWifi2Button.setImage(UIImage.init(named: R.image.ic_checked.name), for: .selected)
    }
    
    func setupView() {
        self.view.backgroundColor = .white
        imgLogo.image = UIImage(named: R.image.logo_union.name)
        userNameLabel.textColor = UIColor(named: R.color.textDefault.name)
        passwordLabel.textColor = UIColor(named: R.color.textDefault.name)
        userNameTextField.textColor = UIColor(named: R.color.textDefault.name)
        userNameTextField.placeholderColor(color: UIColor(named: R.color.textDefault.name)!)
        passwordTextField.placeholderColor(color: UIColor(named: R.color.textDefault.name)!)
        passwordTextField.textColor = UIColor(named: R.color.textDefault.name)
        errorUserNameLabel.textColor = UIColor(named: R.color.textRed.name)
        errorPasswordLabel.textColor = UIColor(named: R.color.textRed.name)
        loginButton.layer.cornerRadius = 8
        loginButton.addTarget(self, action: #selector(loginAction), for: .touchUpInside)
        
        userNameTextField.delegate = self
        passwordTextField.delegate = self
        userNameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        passwordTextField.isSecureTextEntry = true
        passwordTextField.setupRightImage(iconAction: { isShow in
            self.passwordTextField.isSecureTextEntry = isShow
        })
    }
    
    func getWiFiName() -> String? {
        var ssid: String?
        
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                    break
                }
            }
        }
        
        return ssid
    }
    
    func isAlphabetic(s: String) -> Bool {
        return !s.isEmpty && s.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil
    }
    
    func isHaveLetterNumber(input: String) -> Bool {
        var isHaveAlphabet = false
        var isHaveNumber = false
        for chr in input {
            if (chr >= "a" && chr <= "z") || (chr >= "A" && chr <= "Z") {
                isHaveAlphabet = true
            }
            
            if chr.isNumber {
                isHaveNumber = true
            }
        }
        
        if isHaveAlphabet && isHaveNumber {
            return true
        }
        return false
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if textField == passwordTextField {
            if passwordTextField.text?.count ?? 0 > 0 {
                errorPasswordLabel.isHidden = true
                passwordTextField.text = passwordTextField.text?.removeWhitespace()
            }
            
            if textField.text?.count ?? 0 < 8 || textField.text?.count ?? 0 > 16 || !isHaveLetterNumber(input: passwordTextField.text ?? "") {
                errorPasswordLabel.isHidden = false
                errorPasswordLabel.text = "Mật khẩu phải có độ dài từ 8 - 15 ký tự,bao gồm cả ký tự chữ và số , không chứa ký tự khoảng trắng.".localized()
                return
            } else {
                errorPasswordLabel.isHidden = true
            }
        } else if textField == userNameTextField {
            if userNameTextField.text?.count ?? 0 > 0 && userNameTextField.text?.count ?? 0 < 16 {
                errorUserNameLabel.isHidden = true
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case userNameTextField:
            if userNameTextField.text?.count ?? 0 > 0 {
                
            } else {
                errorUserNameLabel.isHidden = false
                errorUserNameLabel.text = "Vui lòng nhập tài khoản đăng nhập.".localized()
            }
            break
        case passwordTextField:
            if passwordTextField.text?.count ?? 0 > 0 {
                
            } else {
                errorPasswordLabel.isHidden = false
                errorPasswordLabel.text = "Vui lòng nhập mật khẩu.".localized()
            }
            break
        default:
            break
        }
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        let newLength = text.count + string.count - range.length
        return newLength < 16
    }
    
    private func isValidateLogin() -> Bool {
        var isValidate = true
        if userNameTextField.text?.removeWhitespace().count ?? 0 > 0 {
            errorUserNameLabel.isHidden = true
        } else {
            errorUserNameLabel.isHidden = false
            errorUserNameLabel.text = "Vui lòng nhập tài khoản đăng nhập.".localized()
            isValidate = false
        }
        
        if passwordTextField.text?.count ?? 0 > 7 && passwordTextField.text?.count ?? 0 < 16{
            errorPasswordLabel.isHidden = true
        } else if passwordTextField.text?.count ?? 0 == 0 {
            errorPasswordLabel.isHidden = false
            errorPasswordLabel.text = "Vui lòng nhập mật khẩu.".localized()
            isValidate = false
        } else {
            errorPasswordLabel.isHidden = false
            errorPasswordLabel.text = "Mật khẩu phải có độ dài từ 8 - 15 ký tự,bao gồm cả ký tự chữ và số , không chứa ký tự khoảng trắng.".localized()
            isValidate = false
        }
        
        return isValidate
    }
    
    private func loginRequest(isOverride: Bool = false) {
        UserDefaults.standard.set(userNameTextField.text, forKey: "userNameLogin")
        guard InternetManager.isConnected() else {
            self.showAlerInternet()
            return
        }
        
        guard isValidateLogin() else { return }
        
        self.startLoading()
        param["username"] = userNameTextField.text
        param["password"] = passwordTextField.text
        param["deviceId"] = UIDevice.current.identifierForVendor?.uuidString
        
        let networkManager: NetworkManager = NetworkManager()
        networkManager.loginPostRequest(isOverride : isOverride, param: param) { [weak self] result in
            self?.stopLoading()
            switch result {
            case .success(let response):
                guard let self = self else { return }
                if response.code == 200 {
                    self.errorPasswordLabel.isHidden = true
                    UserDefault.shared.setUserID(userID: "")
                    if let encodedObject = try? JSONEncoder().encode(response.data) {
                        UserDefaults.standard.set(encodedObject, forKey: "dataLoginModel")
                        print(UserDefault.shared.getDataLoginModel().mobileAccess)
                    }
                    if AccountType.generalAccount.rawValue == response.data?.accountType {
                        guard let vc = Storyboards.inventoryUser.instantiate() as? ScanUserIDController else {return}
                        self.navigationController?.pushViewController(vc, animated: true)
                    } else if AccountType.monitoringAccount.rawValue == response.data?.accountType {
                        let vc : MainViewController = self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.mainViewController.identifier) as! MainViewController
                        if UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryRoleType == UIViewController.inventory {
                            vc.isCheckType = .inventory
                        } else if UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryRoleType == UIViewController.monitor {
                            vc.isCheckType = .monitor
                        } else if UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryRoleType == UIViewController.promote {
                            vc.isCheckType = .inventory
                        }
                        self.navigationController?.pushViewController(vc, animated: true)
                    } else {
                        let vc : MainViewController = self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.mainViewController.identifier) as! MainViewController
                        if UserDefault.shared.getDataLoginModel().mobileAccess == TypeRole.mc.value {
                            vc.isCheckType = .mc
                        } else {
                            vc.isCheckType = .pcb
                        }
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        loginRequest()
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
    
    @objc private func loginAction() {
        loginRequest()
    }
    
    @IBAction func onTapSelectedWifi(_ sender: UIButton) {
        if sender == nameWifi1Button {
            nameWifi1Button.isSelected = true
            nameWifi2Button.isSelected = false
            nameWifi = "bivnioswifim01"
            UserDefaults.standard.set(nameWifi, forKey: "nameWifi")
        } else {
            nameWifi1Button.isSelected = false
            nameWifi2Button.isSelected = true
            nameWifi = "B-WINS"
            UserDefaults.standard.set(nameWifi, forKey: "nameWifi")
        }
    }
}

extension LoginViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedAlways {
            let ssid = self.getWiFiName()
            if let ssid = ssid {
                selectedStackView.isHidden = true
                UserDefaults.standard.set(ssid, forKey: "nameWifi")
            } else {
                selectedStackView.isHidden = false
            }
            print("SSID: \(String(describing: ssid))")
        }
    }
}


