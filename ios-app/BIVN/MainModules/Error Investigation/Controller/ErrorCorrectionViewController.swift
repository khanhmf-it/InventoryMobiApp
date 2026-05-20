//
//  ErrorCorrectionViewController.swift
//  BIVN
//
//  Created by Bi on 13/1/25.
//

import UIKit
import DropDown
import Localize_Swift
import Moya

struct ImageData {
    var serverImage1: String?
    var serverImage2: String?
    var capturedImage1: UIImage?
    var capturedImage2: UIImage?
    var isDeletedImage1: Bool = false
    var isDeletedImage2: Bool = false
}


enum ClassifyEnum: Int, CaseIterable {
    case incorrectInventory = 0
    case packaging = 1
    case defectiveComponents = 2
    case wrongAdjustment = 3
    case bOMWrong = 4
    case misuse = 5
    case other = 6
    
    var displayName: String {
        switch self {
        case .incorrectInventory:
            return "Kiểm kê sai".localized()
        case .packaging:
            return "Quy cách đóng gói".localized()
        case .defectiveComponents:
            return "Linh kiện lỗi".localized()
        case .wrongAdjustment:
            return "Điều chỉnh nhầm".localized()
        case .bOMWrong:
            return "BOM sai".localized()
        case .misuse:
            return "Dùng nhầm".localized()
        case .other:
            return "Khác".localized()
        }
    }
    
    var numberedDisplayName: String {
        return "\(self.rawValue + 1). \(self.displayName)"
    }
    
    static func fromRawValue(_ rawValue: Int) -> ClassifyEnum? {
        return ClassifyEnum(rawValue: rawValue)
    }
}

enum EnumErrorCorrection {
    case errorCorrectionTableViewCell
    case classifyTableViewCell
    case investigationDetailsTableViewCell
    static let all = [errorCorrectionTableViewCell,classifyTableViewCell,investigationDetailsTableViewCell]
}

class ErrorCorrectionViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, InvestigationDetailsCellDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ErrorCorrectionCellDelegate {
    
    
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(R.nib.errorCorrectionTableViewCell)
            tableView.register(R.nib.classifyTableViewCell)
            tableView.register(R.nib.investigationDetailsTableViewCell)
        }
    }
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var accpectButton: UIButton!
    private var imageData = ImageData()
    let myDropDown = DropDown()
    let networkManager: NetworkManager = NetworkManager()
    var componentCode: String?
    var accessoryModel: AccessoryModels?
    var titleString: String?
    var viewDetailModel: ViewDetailModel?
    var isCheckAccpect: Bool = false
    var isUpdating = false
    var employeeID: String?
    var errorCategoryModel: [DataCategory]?
    private var errorCategory: Int = 0
    private var isCheckAcppect: Bool = false
    private var isEdited: Bool = false
    private let successView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }()
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle")
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "Đã thực hiện điều tra sai số".localized()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageUpdate: UILabel = {
        let label = UILabel()
        label.text = "Đã thực hiện cập nhật dữ liệu điều tra sai số".localized()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.setTitle("Quay lại".localized(), for: .normal)
        self.hideKeyboardWhenTappedAround()
        setupToash()
        tableView.separatorStyle = .none
        self.navigationItem.hidesBackButton = true
        getErrorCategory()
        employeeID = UserDefaults.standard.string(forKey: "MANHANVIEN")
//        getViewDetail(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", componentCode: componentCode ?? "")
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setDisplay()
    }
    
    private func setupToash() {
        view.addSubview(successView)
        successView.addSubview(iconImageView)
        successView.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            successView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            successView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            successView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            successView.heightAnchor.constraint(equalToConstant: 50),
            iconImageView.leadingAnchor.constraint(equalTo: successView.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: successView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            messageLabel.centerYAnchor.constraint(equalTo: successView.centerYAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: successView.trailingAnchor, constant: -12)
        ])
    }
    
    func setDisplay() {
        if let titleString = titleString {
            title = titleString
        }
    }
    
    private func showDropdownStatus(for cell: ClassifyTableViewCell, anchorButton: UIButton, nameTextField: UITextField) {
        guard let categories = errorCategoryModel else { return }
        let dropdownModel = categories.map { $0.errorCategoryName ?? "" }
        myDropDown.dataSource = dropdownModel
        myDropDown.anchorView = anchorButton
        myDropDown.bottomOffset = CGPoint(x: 0, y: nameTextField.frame.size.height + 5)
        myDropDown.topOffset = CGPoint(x: 0, y: -(myDropDown.anchorView?.plainView.bounds.height ?? 0))
        myDropDown.dismissMode = .onTap
        myDropDown.direction = .bottom
        myDropDown.customCellConfiguration = { (index: Int, item: String, cell: DropDownCell) in
            if item == nameTextField.text {
                cell.optionLabel.textColor = .red
            } else {
                cell.optionLabel.textColor = .blue
            }
        }
        myDropDown.selectionAction = { (index: Int, item: String) in
            nameTextField.text = item
            let selectedCategory = categories[index]
            cell.hideError()
            self.errorCategory = Int(selectedCategory.errorCategoryKey ?? "") ?? 0
            self.didEditInformation()
        }
        
        myDropDown.show()
    }
    
    func didEditInformation() {
        isEdited = true
    }
    
    func didEditInformationDelegate() {
        isEdited = true
    }
    
    
    // MARK: CALL API
    private func getViewDetail(inventoryId: String, componentCode: String) {
        networkManager.getViewDetailError(inventoryId: inventoryId, componentCode: componentCode, completion: { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.isCheckAcppect = true
                    self.isUpdating = true
                    self.accpectButton.setTitle("Cập nhật".localized(), for: .normal)
                    self.accpectButton.backgroundColor = UIColor(named: R.color.greenColor.name)
                    self.stopLoading()
                    self.viewDetailModel = response
                    self.imageData.serverImage1 = response.data?.confirmationImage1
                    self.imageData.serverImage2 = response.data?.confirmationImage2
                    self.tableView.reloadData()
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { result in
                    }
                } else if response.code == 104 {
                    self.stopLoading()
                    self.isCheckAcppect = false
                    self.isUpdating = false
                    self.accpectButton.setTitle("Xác nhận".localized(), for: .normal)
                    self.accpectButton.backgroundColor = UIColor(named: R.color.buttonBlue.name)
                    self.tableView.reloadData()
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self.showAlertConfigTimeOut()
                    }
                }
                print(error.localizedDescription)
            }
        })
    }
    
    private func getErrorCategory() {
        networkManager.errorCategory(completion: { [weak self] data in
            guard let self = self else { return }
            self.isLoading = false
            self.tableView.isScrollEnabled = true
            switch data {
            case .success(let response):
                if response.code == 200 {
                    let newData = response
                    errorCategoryModel = newData.data
                    self.tableView.reloadData()
                } else {
                    self.showAlertNoti(
                        title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                        message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),
                        cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0),
                        acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0)
                    )
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self.showAlertConfigTimeOut()
                    }
                }
                print(error.localizedDescription)
            }
        })
    }
    
    private func callAPIUpdateStatus(inventoryId: String, componentCode: String) {
        networkManager.updateStatus(inventoryId: inventoryId, componentCode: componentCode, completion: { [weak self] data in
            guard let self = self else { return }
            self.isLoading = false
            switch data {
            case .success(let response):
                if response.code == 200 {
                    DispatchQueue.main.async {
                        for viewController in self.navigationController?.viewControllers ?? [] where viewController is ListErrorController {
                            self.navigationController?.popToViewController(viewController, animated: true)
                            return
                        }
                    }
                } else {
                    self.showAlertNoti(
                        title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                        message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),
                        cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0),
                        acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0)
                    )
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self.showAlertConfigTimeOut()
                    }
                }
                print(error.localizedDescription)
            }
        })
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return EnumErrorCorrection.all.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch EnumErrorCorrection.all[section] {
        case .errorCorrectionTableViewCell, .classifyTableViewCell, .investigationDetailsTableViewCell:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch EnumErrorCorrection.all[indexPath.section] {
        case .investigationDetailsTableViewCell:
            return 400
        default:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch EnumErrorCorrection.all[indexPath.section] {
        case .errorCorrectionTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.errorCorrectionTableViewCell, for: indexPath) else {return UITableViewCell()}
            if let accessoryModel = accessoryModel{
                cell.fillData(resultErrorModel: accessoryModel)
            }
            if let viewDetailModel = viewDetailModel {
                cell.fillDataChange(errorInvestigationModel: viewDetailModel.data)
            }
            cell.delegateValue = self
            cell.selectionStyle = .none
            return cell
        case .classifyTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.classifyTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.onTapDropdown = { anchorView, nameTextField in
                self.showDropdownStatus(for: cell, anchorButton: anchorView, nameTextField: nameTextField)
                
            }
            if let viewDetailModel = viewDetailModel, let status = viewDetailModel.data?.errorCategory, let initialEnum = ClassifyEnum.fromRawValue(status) {
                cell.classifyTextField.text = initialEnum.numberedDisplayName
            }
            cell.selectionStyle = .none
            return cell
        case .investigationDetailsTableViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.investigationDetailsTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            configureCell(cell)
            cell.containerView1.addTapGestureRecognizer(action: {
                guard let image1 = cell.firstImageView.image,
                          image1 != UIImage(named: R.image.image1834.name) else {
                        return
                    }
                let vc = ShowImageDetailVC()
                vc.imageCapture = image1
                vc.modalPresentationStyle = .fullScreen
                self.navigationController?.present(vc, animated: true)
            })
            cell.containerView2.addTapGestureRecognizer(action: {
                guard let image2 = cell.secondImageView.image,
                          image2 != UIImage(named: R.image.image1834.name) else {
                        return
                    }
                let vc = ShowImageDetailVC()
                vc.imageCapture = image2
                vc.modalPresentationStyle = .fullScreen
                self.navigationController?.present(vc, animated: true)
            })
            return cell
        }
    }
    
    func configureCell(_ cell: InvestigationDetailsTableViewCell) {
        cell.selectionStyle = .none
        if let viewDetailModel = viewDetailModel {
            cell.textView.text = viewDetailModel.data?.errorDetails
            cell.checkPlaceholderVisibility()
        }
        
        cell.delegate = self
        let baseUrl: URL? = {
            let ssid = UserDefaults.standard.string(forKey: "nameWifi")
            if Environment.rootURL.description.contains("tinhvan") {
                return Environment.rootURL
            } else if ssid == "bivnioswifim01" {
                return URL(string: "http://172.26.248.26/gateway_inv_test")
            } else {
                return Environment.rootURL
            }
        }()
        
        
        if let capturedImage1 = imageData.capturedImage1 {
            cell.firstImageView.image = capturedImage1
        } else if let serverImageUrl1 = cell.getFullImageUrl(baseUrl: baseUrl, path: imageData.serverImage1 ?? ""){
            cell.firstImageView.kf.setImage(with: serverImageUrl1, placeholder: UIImage(named: R.image.image1834.name))
        } else {
            cell.firstImageView.image = UIImage(named: R.image.image1834.name)
        }
        
        if let capturedImage2 = imageData.capturedImage2 {
            cell.secondImageView.image = capturedImage2
        } else if let serverImage2 = cell.getFullImageUrl(baseUrl: baseUrl, path: imageData.serverImage2 ?? "") {
            cell.secondImageView.kf.setImage(with: serverImage2, placeholder: UIImage(named: R.image.image1834.name))
        } else {
            cell.secondImageView.image = UIImage(named: R.image.image1834.name)
        }
        
        let isServerImage1Empty = imageData.serverImage1 == nil || imageData.serverImage1?.isEmpty == true
        let isServerImage2Empty = imageData.serverImage2 == nil || imageData.serverImage2?.isEmpty == true

        let isCapturedImage1Empty = imageData.capturedImage1 == nil || imageData.capturedImage1 == UIImage(named: R.image.image1834.name)
        let isCapturedImage2Empty = imageData.capturedImage2 == nil || imageData.capturedImage2 == UIImage(named: R.image.image1834.name)

        cell.deleteButtonImage1.isHidden = isServerImage1Empty && isCapturedImage1Empty
        cell.deleteButtonImage2.isHidden = isServerImage2Empty && isCapturedImage2Empty


        
        cell.captureImageHandler = { [weak self] imageIndex in
            self?.didTapCapturePhoto(imageIndex: imageIndex)
        }
        
        cell.deleteImageHandler = { [weak self] imageIndex in
            self?.didTapDeleteImage(imageIndex: imageIndex)
        }
    }
    func didTapDeleteImage(imageIndex: Int) {
        if imageIndex == 0 {
            imageData.capturedImage1 = UIImage(named: R.image.image1834.name)
            imageData.serverImage1 = nil
            imageData.isDeletedImage1 = true
        } else if imageIndex == 1 {
            imageData.capturedImage2 = UIImage(named: R.image.image1834.name)
            imageData.serverImage2 = nil
            imageData.isDeletedImage2 = true
        }

        tableView.reloadData()
    }

    func didTapCapturePhoto(imageIndex: Int) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        imagePicker.view.tag = imageIndex
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            picker.dismiss(animated: true, completion: nil)
            return
        }

        let imageIndex = picker.view.tag
        if imageIndex == 0 {
            imageData.capturedImage1 = image
            imageData.isDeletedImage1 = false
        } else if imageIndex == 1 {
            imageData.capturedImage2 = image
            imageData.isDeletedImage2 = false
        }

        tableView.reloadData()
        picker.dismiss(animated: true, completion: nil)
    }

    
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        guard validate() else {
            return
        }
        let indexPath = IndexPath(row: 0, section: 2)
        guard let cell = tableView.cellForRow(at: indexPath) as? InvestigationDetailsTableViewCell else {
            return
        }
        var confirmationImage1: Data = Data()
        var confirmationImage2: Data = Data()
        
        if let capturedImage1 = imageData.capturedImage1 {
            confirmationImage1 = capturedImage1.resizeWithPercent(percentage: 0.3)?.pngData() ?? Data()
        }
        
        if let capturedImage2 = imageData.capturedImage2 {
            confirmationImage2 = capturedImage2.resizeWithPercent(percentage: 0.3)?.pngData() ?? Data()
        }
        
        guard let errorDetails = cell.textView.text, !errorDetails.isEmpty else {
            return
        }
        
        let indexPath2 = IndexPath(row: 0, section: 0)
        guard let cell2 = tableView.cellForRow(at: indexPath2) as? ErrorCorrectionTableViewCell else {
            return
        }
        
        
        guard let textFieldValue = cell2.valueAdjustLabel.text else {
            return
        }
        let formattedString = textFieldValue.replacingOccurrences(of: ",", with: ".")
        
        let doubleValueTotal = Double(formattedString) ?? 0
        
        for cell in tableView.visibleCells {
            handleClassifyCell(cell)
            handleInvestigationDetailsCell(cell)
            handleErrorCorrectionCell(cell)
        }
        
        submitError(
            inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "",
            componentCode: componentCode ?? "",
            type: self.isCheckAcppect ? 1 : 0,
            quantity: doubleValueTotal,
            errorCategory: self.errorCategory,
            errorDetails: errorDetails,
            image1: imageData.isDeletedImage1 ? nil : confirmationImage1,
            image2: imageData.isDeletedImage2 ? nil : confirmationImage2,
            isDeleteImage1: imageData.isDeletedImage1,
            isDeleteImage2: imageData.isDeletedImage2,
            userCode: employeeID ?? ""
        )
    }
    
    private func validate() -> Bool {
        var hasError = false
        for cell in tableView.visibleCells {
            if let classifyCell = cell as? ClassifyTableViewCell {
                if classifyCell.classifyTextField.text == "Chọn phân loại".localized() {
                    classifyCell.showError(message: "Vui lòng chọn phân loại".localized())
                    hasError = true
                } else {
                    classifyCell.hideError()
                }
            }
            
            
            
            if let investigationCell = cell as? InvestigationDetailsTableViewCell {
                
                if investigationCell.textView.text.isEmpty {
                    investigationCell.showTextViewError(message: "Vui lòng nhập chi tiết điều tra".localized())
                    hasError = true
                } else {
                    investigationCell.hideTextViewError()
                }
            }
            
            if let errorCorrectionCell = cell as? ErrorCorrectionTableViewCell {
                if errorCorrectionCell.valueAdjustLabel.text?.isEmpty ?? false {
                    errorCorrectionCell.showError(message: "Số lượng điều chỉnh không được để trống".localized())
                    hasError = true
                } else {
                    errorCorrectionCell.hideError()
                }
            }
        }
        
        return !hasError
    }
    
    
    @IBAction func ontapBack(_ sender: UIButton) {
        if !self.isUpdating {
            self.showAlertNoti(
                title: "Thông báo".localized(),
                message: "Bạn có chắc chắn muốn thoát? Dữ liệu đã nhập sẽ không được lưu lại".localized(),
                cancelButton: "Hủy bỏ".localized(),
                acceptButton: "Đồng ý".localized(),
                acceptOnTap: { [weak self] in
                    guard let self = self else { return }
                    if accessoryModel?.data?.status != 2 {
                        callAPIUpdateStatus(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", componentCode: self.componentCode ?? "")
                    } else {
                        DispatchQueue.main.async {
                            for viewController in self.navigationController?.viewControllers ?? [] where viewController is ListErrorController {
                                self.navigationController?.popToViewController(viewController, animated: true)
                                return
                            }
                        }
                    }
                },
                cancelOnTap: nil
            )
        } else {
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    private func handleClassifyCell(_ cell: UITableViewCell) {
        if let classifyTableViewCell = cell as? ClassifyTableViewCell {
            if classifyTableViewCell.classifyTextField.text == "Chọn phân loại".localized() {
                classifyTableViewCell.showError(message: "Vui lòng chọn phân loại".localized())
            } else {
                classifyTableViewCell.hideError()
            }
        }
    }
    
    private func handleInvestigationDetailsCell(_ cell: UITableViewCell) {
        if let investigationDetailsTableViewCell = cell as? InvestigationDetailsTableViewCell {
            if investigationDetailsTableViewCell.textView.text.isEmpty {
                investigationDetailsTableViewCell.showTextViewError(message: "Vui lòng nhập chi tiết điều tra".localized())
            } else {
                investigationDetailsTableViewCell.hideTextViewError()
            }
        }
    }
    
    private func handleErrorCorrectionCell(_ cell: UITableViewCell) {
        if let errorCorrectionTableViewCell = cell as? ErrorCorrectionTableViewCell {
            if errorCorrectionTableViewCell.valueAdjustLabel.text?.isEmpty ?? false {
                errorCorrectionTableViewCell.showError(message: "Số lượng điều chỉnh không được để trống".localized())
            } else {
                errorCorrectionTableViewCell.hideError()
            }
        }
    }
    
    func showSuccessMessage(_ message: String) {
        messageLabel.text = message
        successView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.successView.alpha = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            UIView.animate(withDuration: 0.3) {
                self.successView.alpha = 0
            }
            if let navigationController = self.navigationController {
                for controller in navigationController.viewControllers {
                    if controller is ListErrorController {
                        navigationController.popToViewController(controller, animated: true)
                        break
                    }
                }
            }
        }
    }
    
    private func showTextViewErrorInErrorCorrectionCell(_ errorMessage: String) {
        let indexPath = IndexPath(row: 0, section: 0)
        
        guard let cell = tableView.cellForRow(at: indexPath) as? ErrorCorrectionTableViewCell else {
            return
        }
        
        cell.showErrorTextField(message: errorMessage)
    }
    
    private func hideTextViewErrorInErrorCorrectionCell() {
        let indexPath = IndexPath(row: 0, section: 0)
        
        guard let cell = tableView.cellForRow(at: indexPath) as? ErrorCorrectionTableViewCell else {
            return
        }
        
        cell.hideErrorTextField()
    }
    
    func submitError(inventoryId: String, componentCode: String, type : Int, quantity : Double, errorCategory: Int, errorDetails: String, image1: Data?, image2: Data?, isDeleteImage1: Bool, isDeleteImage2: Bool, userCode: String) {
        self.startLoading()
        
        networkManager.submitErrorCorrection(inventoryId: inventoryId, componentCode: componentCode, type: type, quantity: quantity, errorCategory: errorCategory, errorDetails: errorDetails, confirmationImage1: image1 ?? Data(), confirmationImage2: image2 ?? Data(), isDeleteImage1: isDeleteImage1, isDeleteImage2: isDeleteImage2, userCode: userCode, completion: { [self] data in
            switch data {
            case .success(let response):
                self.stopLoading()
                if response.code == 200 {
                    self.hideTextViewErrorInErrorCorrectionCell()
                    if self.isUpdating {
                        self.showSuccessMessage(messageUpdate.text ?? "")
                    } else {
                        self.showSuccessMessage(self.messageLabel.text ?? "")
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("UpdateStatusSuccess"), object: nil, userInfo: ["componentCode": componentCode])
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { result in
                    }
                } else if response.code == 107 {
                    self.showTextViewErrorInErrorCorrectionCell("Không được điều chỉnh lớn hơn số lượng chênh lệch".localized())
                } else if response.code == 103 {
                    self.showTextViewErrorInErrorCorrectionCell("Không được điều chỉnh số lượng cùng dấu với số lượng sai số.".localized())
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self.showAlertConfigTimeOut()
                        DispatchQueue.main.async {
                            for viewController in self.navigationController?.viewControllers ?? [] where viewController is ScanUserIDController {
                                self.navigationController?.popToViewController(viewController, animated: true)
                                return
                            }
                        }
                    }
                }
                print(error.localizedDescription)
            }
        })
    }
    
    
}
