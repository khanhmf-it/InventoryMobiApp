//
//  BaseViewController.swift
//  BIVN
//
//  Created by Luyện Đào on 12/09/2023.
//

import Foundation
import UIKit
import Moya
import Localize_Swift

class BaseViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var spinner = UIActivityIndicatorView()
    lazy var isLoading: Bool = false
    let numberFormatter = NumberFormatter()
    
    func updateNumberFormatter() {
        numberFormatter.locale = Locale(identifier: "en_US")
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        numberFormatter.maximumFractionDigits = 61
        numberFormatter.groupingSeparator = Locale.current.groupingSeparator
    }
    
    private var enableHideKeyBoardWhenTouchInScreen: Bool = true
    var isEnableHideKeyBoardWhenTouchInScreen: Bool {
        get {
            return self.enableHideKeyBoardWhenTouchInScreen ? true : false
        }
        
        set {
            self.enableHideKeyBoardWhenTouchInScreen = newValue
            if self.enableHideKeyBoardWhenTouchInScreen {
                let touchOnScreen = UITapGestureRecognizer(target: self, action: #selector(self.touchOnScreen))
                touchOnScreen.delegate = self
                touchOnScreen.cancelsTouchesInView = false
                view.addGestureRecognizer(touchOnScreen)
            }
        }
    }
    
    @objc func touchOnScreen() {
        view.endEditing(true)
    }
    
    func setFontTitleNavBar() {
        if let navigationBar = self.navigationController?.navigationBar {
            var navBarTitleTextAttributes = [NSAttributedString.Key: Any]()
            navBarTitleTextAttributes[.font] = fontUtils.size16.bold
            navBarTitleTextAttributes[.foregroundColor] = UIColor.black
            
            navigationBar.titleTextAttributes = navBarTitleTextAttributes
        }
    }
    
    func setSpinner() {
        view.alpha = 0.95
        spinner.style = .large
        spinner.color = #colorLiteral(red: 0, green: 0, blue: 0.5019607843, alpha: 1)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        view.addSubview(spinner)
        
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    func showLoading() {
        setSpinner()
        spinner.startAnimating()
        view.isUserInteractionEnabled = false
    }
    
    func hideLoading() {
        view.alpha = 1
        spinner.stopAnimating()
        view.isUserInteractionEnabled = true
    }
    
    func setShadowView(view: UIView) {
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 10
    }
    
    func setShadowButton(button: UIButton, cornerRadius: CGFloat) {
        button.layer.cornerRadius = cornerRadius
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.5
        button.layer.shadowOffset = .zero
        button.layer.shadowRadius = 10
    }
    
    func setPlaceholder(textView: UITextView, label: UILabel, text: String) {
        label.text = text
        label.font = UIFont.italicSystemFont(ofSize: (textView.font?.pointSize)!)
        label.sizeToFit()
        textView.addSubview(label)
        label.frame.origin = CGPoint(x: 5, y: (textView.font?.pointSize)! / 2)
        label.textColor = UIColor.lightGray
        label.isHidden = !textView.text.isEmpty
    }
    
    func backVC(controller: UIViewController){
        DispatchQueue.main.async {
            let vc = controller
            let keyWindow = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first
            
            keyWindow?.rootViewController = vc
            keyWindow?.endEditing(true)
        }
    }
    
    func showAlertErrorList(message: String?) {
        self.showAlertNoti(title: "Thông báo".localized(), message: message ?? "", acceptButton: "Đồng ý".localized())
    }
    
    func showPopUpAlert(title: String, array: [String], status: [Int] = [], cancel: @escaping () -> Void, accept: ((Int) -> ())?) -> Void {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "PopUpViewController") as! PopUpViewController
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overFullScreen
        vc.titleText = title
        vc.arrayData = array
        vc.arrayStatus = status
        vc.cancelClosure = cancel
        vc.accpectClosure = { value in
            accept?(value ?? 0)
        }
        present(vc, animated: true)
    }
    
    func showPopUpAlertTicket(title: String, array: [String], status: [Int] = [], cancel: @escaping () -> Void, accept: ((Int) -> ())?) -> Void {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "PopUpViewController") as! PopUpViewController
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overFullScreen
        vc.titleText = title
        vc.arrayData = array
        vc.arrayStatus = status
        vc.cancelClosure = cancel
        vc.accpectClosure = { value in
            accept?(value ?? 0)
        }
        present(vc, animated: true)
    }
    
    
    func showAlertNoti(title: String, message: String, cancelButton: String = "", acceptButton: String = "", acceptOnTap: (() -> ())? = nil, cancelOnTap: (() -> ())? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        if cancelButton.count > 0 {
            alert.addAction(UIAlertAction(title: cancelButton, style: UIAlertAction.Style.cancel, handler: { action in
                cancelOnTap?()
            }))
        }
        if acceptButton.count > 0 {
            alert.addAction(UIAlertAction(title: acceptButton, style: UIAlertAction.Style.default, handler: { action in
                acceptOnTap?()
            }))
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func alertAtribute(title: String, message1: String, message2: String, message3: String, cancelButton: String = "", acceptButton: String = "", acceptOnTap: (() -> ())? = nil) {
        
        let attributedText = NSMutableAttributedString()
        let str1 = message1
        let str2 = message2
        let str3 = message3
        let attr1 = [NSAttributedString.Key.foregroundColor: UIColor(named: R.color.textDefault.name), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .regular)]
        let attr2 = [NSAttributedString.Key.foregroundColor: UIColor(named: R.color.textDefault.name), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium)]
        let attr3 = [NSAttributedString.Key.foregroundColor: UIColor(named: R.color.textDefault.name), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .regular)]
        attributedText.append(NSAttributedString(string: "\n" + str1, attributes: attr1 as [NSAttributedString.Key : Any]))
        attributedText.append(NSAttributedString(string: str2, attributes: attr2 as [NSAttributedString.Key : Any]))
        attributedText.append(NSAttributedString(string: str3, attributes: attr3 as [NSAttributedString.Key : Any]))
        
        let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertController.Style.alert)
        alert.setValue(attributedText, forKey: "attributedMessage")
        
        if cancelButton.count > 0 {
            alert.addAction(UIAlertAction(title: cancelButton, style: UIAlertAction.Style.destructive, handler: nil))
        }
        if acceptButton.count > 0 {
            alert.addAction(UIAlertAction(title: acceptButton, style: UIAlertAction.Style.default, handler: { action in
                acceptOnTap?()
            }))
        }
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func showToast(timeSeconds: Double, messgage: String) {
        let alert = UIAlertController(title: nil, message: messgage, preferredStyle: .actionSheet)
        self.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeSeconds) {
            alert.dismiss(animated: true)
        }
    }
    
    func showAlertExpiredToken(isLogin: Bool = false, code: Int?, completion: @escaping (Bool) -> (), completionHandler: (() -> Void)? = nil) {
        switch code {
        case 15:
            let titleOK = "Xác nhận".localized()
            self.showAlertNoti(title: "Thông báo".localized(), message: "Tài khoản đang sử dụng đã được đăng nhập vào một thiết bị khác, vui lòng đăng xuất khỏi thiết bị này.".localized(), acceptButton: titleOK, acceptOnTap: {
                if isLogin {
                    completionHandler?()
                } else {
                    UserDefaults.standard.removeObject(forKey: "dataLoginModel")
                    let vc : LoginViewController = self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.loginViewController.identifier) as! LoginViewController
                    let navigationController = UINavigationController(rootViewController: vc)
                    navigationController.modalTransitionStyle = .crossDissolve
                    navigationController.modalPresentationStyle = .fullScreen
                    self.present(navigationController, animated: true, completion: nil)
                }
            })
            break
        case 401, 19, 17:
            refreshToken(){ [weak self] result in
                guard let self = self else { return }
                completion(result)
            }
            break
        case 403:
            self.showAlertNoti(title: "Lỗi đăng nhập".localized(), message: "Tài khoản không có quyền truy cập ứng dụng.Hãy liên hệ với Admin.".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap: {
                UserDefaults.standard.removeObject(forKey: "dataLoginModel")
                
                if !isLogin {
                    let vc : LoginViewController = self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.loginViewController.identifier) as! LoginViewController
                    let navigationController = UINavigationController(rootViewController: vc)
                    navigationController.modalTransitionStyle = .crossDissolve
                    navigationController.modalPresentationStyle = .fullScreen
                    self.present(navigationController, animated: true, completion: nil)
                }
            })
            break
        case 404:
            self.showAlertNoti(title: "Không có quyền".localized(), message: "Bạn chưa được phân quyền theo nhà máy và phòng ban. Vui lòng liên hệ admin để được hỗ trợ.".localized(), acceptButton: "Quay lại".localized(), acceptOnTap: {
                UserDefaults.standard.removeObject(forKey: "dataLoginModel")
                
                let vc : LoginViewController = self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.loginViewController.identifier) as! LoginViewController
                let navigationController = UINavigationController(rootViewController: vc)
                navigationController.modalTransitionStyle = .crossDissolve
                navigationController.modalPresentationStyle = .fullScreen
                self.present(navigationController, animated: true, completion: nil)
            })
            break
        case 60:
            self.showAlertNoti(title: "Thông báo".localized(), message: "Quyền sử dụng của bạn đã được thay đổi bởi admin. Vui lòng đăng nhập lại để cập nhập quyền mới nhất.".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap: {
                UserDefaults.standard.removeObject(forKey: "dataLoginModel")
                
                if !isLogin {
                    let vc : LoginViewController = self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.loginViewController.identifier) as! LoginViewController
                    let navigationController = UINavigationController(rootViewController: vc)
                    navigationController.modalTransitionStyle = .crossDissolve
                    navigationController.modalPresentationStyle = .fullScreen
                    self.present(navigationController, animated: true, completion: nil)
                }
            })
            break
        case 56:
            self.showAlertNoti(title: "Không có quyền".localized(), message: "Bạn chưa được phân quyền theo nhà máy và phòng ban. Vui lòng liên hệ admin để được hỗ trợ.".localized(), acceptButton: "Quay lại".localized(), acceptOnTap: {
                UserDefaults.standard.removeObject(forKey: "dataLoginModel")
                
                if !isLogin {
                    let vc : LoginViewController = self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.loginViewController.identifier) as! LoginViewController
                    let navigationController = UINavigationController(rootViewController: vc)
                    navigationController.modalTransitionStyle = .crossDissolve
                    navigationController.modalPresentationStyle = .fullScreen
                    self.present(navigationController, animated: true, completion: nil)
                }
            })
            break
        default:
            break
        }
    }
    
    func showAlerInternet() {
        self.showAlertNoti(title: "Thông báo".localized(), message: "Vui lòng kiểm tra lại kết nối internet của thiết bị.".localized(), acceptButton: "Đồng ý".localized())
    }
    
    // unfomater for request sever
    func unFormatNumber(stringValue: String, regionUS: Bool) -> Double {
        var number: Double = 0.0
        if regionUS {
            let completeString = stringValue.replacingOccurrences(of: ",", with: "", options: NSString.CompareOptions.literal, range: nil)
            number = Double(completeString) ?? 0.0
        } else {
            var completeString = stringValue.replacingOccurrences(of: ".", with: "", options: NSString.CompareOptions.literal, range: nil)
            completeString = completeString.replacingOccurrences(of: ",", with: ".", options: NSString.CompareOptions.literal, range: nil)
            
            number = Double(completeString) ?? 0.0
        }
        
        return number
    }
    
    func unFormatNumber2(stringValue: String, regionUS: Bool, currentRegion: String) -> Double {
        var number: Double = 0.0
        if regionUS {
            var completeString = stringValue.replacingOccurrences(of: ".", with: "", options: NSString.CompareOptions.literal, range: nil)
            completeString = completeString.replacingOccurrences(of: ",", with: ".", options: NSString.CompareOptions.literal, range: nil)
            
            number = Double(completeString) ?? 0.0
        } else {
            let completeString = stringValue.replacingOccurrences(of: ",", with: "", options: NSString.CompareOptions.literal, range: nil)
            number = Double(completeString) ?? 0.0
        }
        
        return number
    }
    
    func unFormatNumber3(stringValue: String) -> Double {
        var number: Double = 0.0
        var completeString =  stringValue.replacingOccurrences(of: ".", with: "", options: NSString.CompareOptions.literal, range: nil)
        completeString = completeString.replacingOccurrences(of: ",", with: ".", options: NSString.CompareOptions.literal, range: nil)
        number = Double(completeString) ?? 0.0
        return number
    }
    
    func showAlertConfigTimeOut() {
        let alert = UIAlertController(title: "Thông báo".localized(), message: "Không nhận được phản hồi từ hệ thống, hãy kiểm tra lại server".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Thoát".localized(), style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    func showAlertError(title: String, message: String,titleButton: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: titleButton, style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    private func refreshToken(completion: @escaping (Bool) -> ()) {
        guard InternetManager.isConnected() else {
            self.showAlerInternet()
            return
        }
        
        self.startLoading()
        var param = Dictionary<String, Any>()
        var dataLoginModel: DataLoginModel = UserDefault.shared.getDataLoginModel()
        param["deviceId"] = UIDevice.current.identifierForVendor?.uuidString
        param["oldToken"] = dataLoginModel.token
        param["refreshToken"] = dataLoginModel.refreshToken
        
        let networkManager: NetworkManager = NetworkManager()
        networkManager.refreshToken(param: param) { [weak self] result in
            self?.stopLoading()
            switch result {
            case .success(let response):
                guard let self = self else { return }
                if response.code == 200 {
                    dataLoginModel.userId = response.data?.userId
                    dataLoginModel.token = response.data?.token
                    dataLoginModel.refreshToken = response.data?.refreshToken
                    if let encodedObject = try? JSONEncoder().encode(dataLoginModel) {
                        UserDefaults.standard.set(encodedObject, forKey: "dataLoginModel")
                    }
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    if let lastDateString = UserDefaults.standard.string(forKey: "lastDate") {
                        let myString = formatter.string(from: Date())
                        let lastDate = formatter.date(from:lastDateString)!
                        let currentDate = formatter.date(from:myString)
                        let components = ((currentDate?.timeIntervalSinceReferenceDate ?? 0) - lastDate.timeIntervalSinceReferenceDate) / 60
                        UserDefaults.standard.set(myString, forKey: "lastDate")
                        if components < 11 {
                            completion(true)
                            return
                        } else {
                            if AccountType.generalAccount.rawValue == "TaiKhoanChung" {
                                DispatchQueue.main.async {
                                    guard let controllersInStack = self.navigationController?.viewControllers else { return }
                                    if let scanVC = controllersInStack.first(where: { $0 is ScanUserIDController }) as? ScanUserIDController  {
                                        self.navigationController?.popToViewController(scanVC, animated: true)
                                        return
                                    } else {
                                        guard let vc = Storyboards.inventoryUser.instantiate() as? ScanUserIDController else {return}
                                        let navigationController = UINavigationController(rootViewController: vc)
                                        navigationController.modalTransitionStyle = .crossDissolve
                                        navigationController.modalPresentationStyle = .fullScreen
                                        self.present(navigationController, animated: true, completion: nil)
                                    }
                                }
                            } else if AccountType.monitoringAccount.rawValue == "TaiKhoanGiamSat" {
                                DispatchQueue.main.async {
                                    for viewController in self.navigationController?.viewControllers ?? [] where viewController is MainViewController {
                                        self.navigationController?.popToViewController(viewController, animated: true)
                                        return
                                    }
                                }
                            } else {
                                DispatchQueue.main.async {
                                    for viewController in self.navigationController?.viewControllers ?? [] where viewController is MainViewController {
                                        self.navigationController?.popToViewController(viewController, animated: true)
                                        return
                                    }
                                }
                            }
                        }
                    } else {
                        let myString = formatter.string(from: Date())
                        UserDefaults.standard.set(myString, forKey: "lastDate")
                        completion(true)
                        return
                    }
                } else {
                    self.showAlertNoti(title: "Phiên đã hết hạn".localized(), message: "Vui lòng đăng nhập lại.".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap: {
                        UserDefaults.standard.removeObject(forKey: "dataLoginModel")
                        let vc : LoginViewController = self.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.loginViewController.identifier) as! LoginViewController
                        let navigationController = UINavigationController(rootViewController: vc)
                        navigationController.modalTransitionStyle = .crossDissolve
                        navigationController.modalPresentationStyle = .fullScreen
                        self.present(navigationController, animated: true, completion: nil)
                    })
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self?.showAlertNoti(title: "Phiên đã hết hạn".localized(), message: "Vui lòng đăng nhập lại.".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap:  {
                            UserDefaults.standard.removeObject(forKey: "dataLoginModel")
                            let vc : LoginViewController = self?.storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.loginViewController.identifier) as! LoginViewController
                            let navigationController = UINavigationController(rootViewController: vc)
                            navigationController.modalTransitionStyle = .crossDissolve
                            navigationController.modalPresentationStyle = .fullScreen
                            self?.present(navigationController, animated: true, completion: nil)
                        })
                    }
                }
            }
        }
    }
}
