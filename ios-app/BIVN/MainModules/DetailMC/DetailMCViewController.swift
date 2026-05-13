//
//  DetailViewController.swift
//  BIVN
//
//  Created by tinhvan on 14/09/2023.
//  //095480563  //092185632  //MaLKDuc01

import UIKit
import Moya
import Localize_Swift

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> Int {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return Int(ceil(boundingBox.height))
    }
    
    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}

extension NSAttributedString {
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.width)
    }
}

class DetailMCViewController: BaseViewController {
    @IBOutlet weak var titleCodeItemsTv: UILabel!
    @IBOutlet weak var contentCodeItemsTv: UITextView!
    @IBOutlet weak var titleNameItemsTv: UILabel!
    @IBOutlet weak var contentNameItemsTv: UITextView!
    @IBOutlet weak var titleNoteItemsTv: UILabel!
    @IBOutlet weak var titleSLXLabel: UILabel!
    @IBOutlet weak var contentNoteItemsTv: UILabel!
    @IBOutlet weak var contentNoteItemsTv2: UILabel!
    @IBOutlet weak var contentNoteItemsTv3: UILabel!
    @IBOutlet weak var titleLocateItemsTv: UILabel!
    @IBOutlet weak var contentLocateItemsTv: UITextView!
    @IBOutlet weak var numberItemsLabel: UILabel!
    @IBOutlet weak var imgCloseNumberItems: UIImageView!
    @IBOutlet weak var imgCloseNumberItems2: UIImageView!
    @IBOutlet weak var imgCloseNumberItems3: UIImageView!
    @IBOutlet weak var numberItemsTextfield: UITextField!
    @IBOutlet weak var numberItemsTextfield2: UITextField!
    @IBOutlet weak var numberItemsTextfield3: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var reasonTextView : UITextView!
    @IBOutlet weak var reasonView: UIStackView!
    @IBOutlet weak var errorNumberLabel: UILabel!
    @IBOutlet weak var errorReasonLabel: UILabel!
    @IBOutlet weak var viewCheckAllValue: UIView!
    @IBOutlet weak var btnCheck: UIButton!
    
    @IBOutlet weak var cstHeightViewSL: NSLayoutConstraint!
    @IBOutlet weak var viewNCC1: UIView!
    @IBOutlet weak var viewNCC2: UIView!
    @IBOutlet weak var viewNCC3: UIView!
    @IBOutlet weak var viewNSL1: UIView!
    @IBOutlet weak var viewNSL2: UIView!
    @IBOutlet weak var viewNSL3: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var tvReason: UILabel!
    
    var placeholderLabel = UILabel()
    var type: TypeRole?
    var typePCB: String?
    var componentDetailModels: [ComponentDetailModel] = []
    var isCheckAll = false
    var isCheckDots = false
    var isCheckComma = false

    private var textTypeError = ""
    
    var regionUS = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigation()
        setView()
        
        regionUS = numberFormatter.locale.identifier == "en_US"
        updateNumberFormatter()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.tintColor = UIColor.gray
    }
    
    private func setUpNavigation() {
        let yourBackImage = UIImage(named: R.image.ic_back.name)
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationItem.setHidesBackButton(true, animated: true)
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: #selector(onTapBack))
        self.navigationItem.leftBarButtonItem = buttonLeft
        
        type = UserDefault.shared.getDataLoginModel().mobileAccess == TypeRole.mc.value ? .mc : .pcb
        if type == .mc {
            self.title = "Nhập số lượng xuất kho".localized()
            self.textTypeError = "xuất kho".localized()
        } else {
            self.title = typePCB == "Xuất kho".localized() ? "Nhập số lượng xuất kho".localized() : "Nhập số lượng nhập kho".localized()
            self.reasonView.isHidden = typePCB == "Xuất kho".localized()
            self.textTypeError = typePCB == "Xuất kho".localized() ? "xuất kho".localized() : "nhập kho".localized()
        }
    }
    
    @objc private func onTapBack() {
        if numberItemsTextfield.text?.isEmpty ?? true && numberItemsTextfield2.text?.isEmpty ?? true && numberItemsTextfield3.text?.isEmpty ?? true && reasonTextView.text.isEmpty {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.showAlertNoti(title: "Xác nhận thoát".localized(), message: "Thông tin vừa nhập sẽ không được lưu lại. Bạn có chắc chắn muốn thoát ?".localized(), cancelButton: "Không".localized(), acceptButton: "Có".localized(), acceptOnTap: {
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
    
    @objc private func onTapCancel() {
        onTapBack()
    }
    
    @objc private func onTapAccept() {
        guard self.validateDataInput() else { return }
        
        if type == .mc {
            requestOutputStorage()
        } else {
            if typePCB == "Xuất kho".localized() {
                requestOutputStorage()
            } else {
                requestInputStorage()
            }
        }
    }
    
    private func setView() {
        self.hideKeyboardWhenTappedAround()
        self.setupTextView()
        self.setFontTitleNavBar()
        bottomView.addshadow(top: true, left: false, bottom: false, right: false)
//        addTopShadow(forView: bottomView)
        titleCodeItemsTv.textColor = UIColor(named: R.color.textDefault.name)
        contentCodeItemsTv.textColor = UIColor(named: R.color.buttonBlue.name)
        titleNameItemsTv.textColor = UIColor(named: R.color.textDefault.name)
        contentNameItemsTv.textColor = UIColor(named: R.color.textDefault.name)
        titleNoteItemsTv.textColor = UIColor(named: R.color.textDefault.name)
        titleSLXLabel.textColor = UIColor(named: R.color.textDefault.name)
        contentNoteItemsTv.textColor = UIColor(named: R.color.textDefault.name)
        titleLocateItemsTv.textColor = UIColor(named: R.color.textDefault.name)
        contentLocateItemsTv.textColor = UIColor(named: R.color.buttonBlue.name)
        numberItemsLabel.textColor = UIColor(named: R.color.textDefault.name)
        numberItemsTextfield.textColor = UIColor(named: R.color.buttonBlue.name)
        reasonTextView.textColor = UIColor(named: R.color.textDefault.name)
        errorNumberLabel.textColor = UIColor(named: R.color.textRed.name)
        errorReasonLabel.textColor = UIColor(named: R.color.textRed.name)
        errorNumberLabel.isHidden = true
        errorReasonLabel.isHidden = true
        
        numberItemsTextfield.delegate = self
        numberItemsTextfield2.delegate = self
        numberItemsTextfield3.delegate = self
        numberItemsTextfield.keyboardType = .decimalPad
        numberItemsTextfield2.keyboardType = .decimalPad
        numberItemsTextfield3.keyboardType = .decimalPad
        
        numberItemsTextfield.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        numberItemsTextfield2.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        numberItemsTextfield3.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        numberItemsTextfield.placeholderColor(color: UIColor(named: R.color.textDefault.name)!)
        numberItemsTextfield2.placeholderColor(color: UIColor(named: R.color.textDefault.name)!)
        numberItemsTextfield3.placeholderColor(color: UIColor(named: R.color.textDefault.name)!)
        
        btnCheck.setImage(UIImage(named: R.image.ic_uncheckbox.name), for: .normal)
        btnCheck.setTitle("", for: .normal)
        cancelButton.addTarget(self, action: #selector(onTapCancel), for: .touchUpInside)
        acceptButton.addTarget(self, action: #selector(onTapAccept), for: .touchUpInside)
        
        viewNCC1.isHidden = true
        viewNCC2.isHidden = true
        viewNCC3.isHidden = true
        viewNSL1.isHidden = true
        viewNSL2.isHidden = true
        viewNSL3.isHidden = true
        
        
        titleCodeItemsTv.text = "Mã linh kiện:".localized()
        titleNameItemsTv.text = "Tên linh kiện:".localized()
        titleLocateItemsTv.text = "Vị trí:".localized()
        tvReason.text = "Lý do:".localized()
        cancelButton.setTitle("Hủy bỏ".localized(), for: .normal)
        acceptButton.setTitle("Đồng ý".localized(), for: .normal)
        
        setDataView()
    }
    
    // MARK: setData
    private func setDataView() {
        titleNoteItemsTv.text = "Tên NCC:".localized()
        imgCloseNumberItems.addTapGestureRecognizer { [weak self] in
            guard let `self` = self else { return }
            self.numberItemsTextfield.text = ""
            self.numberItemsTextfield.font = .systemFont(ofSize: 14, weight: .regular)
            self.btnCheck.setImage(UIImage(named: R.image.ic_uncheckbox.name), for: .normal)
            self.isCheckAll = false
        }
        imgCloseNumberItems2.addTapGestureRecognizer { [weak self] in
            guard let `self` = self else { return }
            self.numberItemsTextfield2.text = ""
            self.numberItemsTextfield2.font = .systemFont(ofSize: 14, weight: .regular)
            self.btnCheck.setImage(UIImage(named: R.image.ic_uncheckbox.name), for: .normal)
            self.isCheckAll = false
        }
        imgCloseNumberItems3.addTapGestureRecognizer { [weak self] in
            guard let `self` = self else { return }
            self.numberItemsTextfield3.text = ""
            self.numberItemsTextfield3.font = .systemFont(ofSize: 14, weight: .regular)
            self.btnCheck.setImage(UIImage(named: R.image.ic_uncheckbox.name), for: .normal)
            self.isCheckAll = false
        }
        viewCheckAllValue.addTapGestureRecognizer { [weak self] in
            guard let `self` = self else { return }
            self.checkAllAction()
        }
        
        // set data
        contentCodeItemsTv.text = componentDetailModels.first?.componentCode
        contentNameItemsTv.text = componentDetailModels.first?.componentName
        contentLocateItemsTv.text = componentDetailModels.first?.positionCode
        
        if type == .mc {
            numberItemsLabel.text = "Nhập số lượng xuất kho".localized()
            numberItemsTextfield.text = ""
            numberItemsTextfield2.text = ""
            numberItemsTextfield3.text = ""
            titleSLXLabel.text = "Số lượng xuất".localized()
        } else {
            if typePCB == "Xuất kho".localized() {
                numberItemsLabel.text = "Nhập số lượng xuất kho".localized()
                numberItemsTextfield.text = ""
                numberItemsTextfield2.text = ""
                numberItemsTextfield3.text = ""
                titleSLXLabel.text = "Số lượng xuất".localized()
            } else {
                numberItemsLabel.text = "Nhập số lượng nhập kho".localized()
                viewCheckAllValue.isHidden = true
                titleSLXLabel.text = "Số lượng nhập".localized()
            }
        }
        
        numberItemsTextfield.font = .systemFont(ofSize: (numberItemsTextfield.text?.count ?? 0) > 0 ? 24 : 14, weight: (numberItemsTextfield.text?.count ?? 0) > 0 ? .bold : .regular)
        numberItemsTextfield2.font = .systemFont(ofSize: (numberItemsTextfield2.text?.count ?? 0) > 0 ? 24 : 14, weight: (numberItemsTextfield2.text?.count ?? 0) > 0 ? .bold : .regular)
        numberItemsTextfield3.font = .systemFont(ofSize: (numberItemsTextfield3.text?.count ?? 0) > 0 ? 24 : 14, weight: (numberItemsTextfield3.text?.count ?? 0) > 0 ? .bold : .regular)
        
        
        if componentDetailModels.count == 1 {
            contentNoteItemsTv.text = componentDetailModels[0].supplierShortName
            viewNCC1.isHidden = false
            viewNCC2.isHidden = true
            viewNCC3.isHidden = true
            viewNSL1.isHidden = false
            viewNSL2.isHidden = true
            viewNSL3.isHidden = true
        } else if componentDetailModels.count == 2 {
            contentNoteItemsTv.text = componentDetailModels[0].supplierShortName
            contentNoteItemsTv2.text = componentDetailModels[1].supplierShortName
            viewNCC1.isHidden = false
            viewNCC2.isHidden = false
            viewNCC3.isHidden = true
            viewNSL1.isHidden = false
            viewNSL2.isHidden = false
            viewNSL3.isHidden = true
        } else if componentDetailModels.count == 3 {
            contentNoteItemsTv.text = componentDetailModels[0].supplierShortName
            contentNoteItemsTv2.text = componentDetailModels[1].supplierShortName
            contentNoteItemsTv3.text = componentDetailModels[2].supplierShortName
            viewNCC1.isHidden = false
            viewNCC2.isHidden = false
            viewNCC3.isHidden = false
            viewNSL1.isHidden = false
            viewNSL2.isHidden = false
            viewNSL3.isHidden = false
        }
        
        let height1 = contentNoteItemsTv.text?.height(withConstrainedWidth: viewNCC1.frame.width, font: UIFont.systemFont(ofSize: 14, weight: .regular))
        let height2 = contentNoteItemsTv2.text?.height(withConstrainedWidth: viewNCC1.frame.width, font: UIFont.systemFont(ofSize: 14, weight: .regular))
        let height3 = contentNoteItemsTv3.text?.height(withConstrainedWidth: viewNCC1.frame.width, font: UIFont.systemFont(ofSize: 14, weight: .regular))
        
        let arrrayHeight = [height1, height2, height3]
        var maxNumber = arrrayHeight.reduce(arrrayHeight[0]) { $0 ?? 0 > $1 ?? 0 ? $0 : $1 }
        maxNumber = maxNumber ?? 0 < 60 ? 60 : (maxNumber ?? 60) + 20
        
        cstHeightViewSL.constant = CGFloat(componentDetailModels.count * (maxNumber ?? 60)) + 60
    }
    
    private func setupTextView() {
        reasonTextView!.layer.cornerRadius = 5
        reasonTextView!.layer.borderWidth = 1
        reasonTextView!.layer.borderColor = UIColor(named: R.color.lineColor.name)?.cgColor
        //reasonTextView.placeholder = "Nhập nội dung..."
        
        reasonTextView.delegate = self
        placeholderLabel.text = "Nhập nội dung...".localized()
        placeholderLabel.font = .systemFont(ofSize: (reasonTextView.font?.pointSize)!, weight: .regular)
        //.italicSystemFont(ofSize: (reasonTextView.font?.pointSize)!)
        placeholderLabel.sizeToFit()
        reasonTextView.addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPoint(x: 5, y: (reasonTextView.font?.pointSize)! / 2)
        //placeholderLabel.textColor = .tertiaryLabel
        placeholderLabel.textColor = UIColor(named: R.color.textDefault.name)?.withAlphaComponent(0.4)
        placeholderLabel.isHidden = !reasonTextView.text.isEmpty
    }
    
    private func checkAllAction() {
        isCheckAll = !isCheckAll
        if isCheckAll {
            errorNumberLabel.isHidden = true
            btnCheck.setImage(UIImage(named: R.image.ic_checkbox.name), for: .normal)
            
            numberItemsTextfield.text = ""
            numberItemsTextfield2.text = ""
            numberItemsTextfield3.text = ""
            
            numberItemsTextfield.text = numberFormatter.string(from: NSNumber(value: componentDetailModels.count > 0 ? componentDetailModels[0].inventoryNumber ?? 0.0 : 0.0))
            numberItemsTextfield2.text = numberFormatter.string(from: NSNumber(value: componentDetailModels.count > 1 ? componentDetailModels[1].inventoryNumber ?? 0.0 : 0.0))
            numberItemsTextfield3.text = numberFormatter.string(from: NSNumber(value: componentDetailModels.count > 1 ? componentDetailModels[2].inventoryNumber ?? 0.0 : 0.0))
        } else {
            btnCheck.setImage(UIImage(named: R.image.ic_uncheckbox.name), for: .normal)
            
            numberItemsTextfield.text = ""
            numberItemsTextfield2.text = ""
            numberItemsTextfield3.text = ""
        }
        
        numberItemsTextfield.font = .systemFont(ofSize: (numberItemsTextfield.text?.count ?? 0) > 0 ? 24 : 14, weight: (numberItemsTextfield.text?.count ?? 0) > 0 ? .bold : .regular)
        numberItemsTextfield2.font = .systemFont(ofSize: (numberItemsTextfield2.text?.count ?? 0) > 0 ? 24 : 14, weight: (numberItemsTextfield2.text?.count ?? 0) > 0 ? .bold : .regular)
        numberItemsTextfield3.font = .systemFont(ofSize: (numberItemsTextfield3.text?.count ?? 0) > 0 ? 24 : 14, weight: (numberItemsTextfield3.text?.count ?? 0) > 0 ? .bold : .regular)
    }
    
    // unfomater for request sever
    func unFormatNumber(stringValue: String) -> Double {
        var number: Double = 0.0
        if regionUS {
            let completeString = stringValue.replacingOccurrences(of: ",", with: "", options: NSString.CompareOptions.literal, range: nil)
            
            number = Double(completeString) ?? 0.0
        } else {
            var completeString = stringValue.replacingOccurrences(of: ".", with: "", options: NSString.CompareOptions.literal, range: nil)
            completeString = completeString.replacingOccurrences(of: ",", with: "", options: NSString.CompareOptions.literal, range: nil)
            
            number = Double(completeString) ?? 0.0
        }
        
        return number
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Check if the region has changed
        if traitCollection.userInterfaceIdiom == .phone && previousTraitCollection?.userInterfaceIdiom == .phone && traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            // Update NumberFormatter based on the new locale
            updateNumberFormatter()
            
            // Reformat the text in the text field
            numberItemsTextfield.text = numberFormatter.string(from: numberFormatter.number(from: numberItemsTextfield.text ??  "") ?? 0)
            numberItemsTextfield2.text = numberFormatter.string(from: numberFormatter.number(from: numberItemsTextfield2.text ??  "") ?? 0)
            numberItemsTextfield3.text = numberFormatter.string(from: numberFormatter.number(from: numberItemsTextfield3.text ??  "") ?? 0)
        }
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if textField == numberItemsTextfield || textField == numberItemsTextfield2 || textField == numberItemsTextfield3 {
            if textField.text?.count ?? 0 > 0 {
                textField.font = .systemFont(ofSize: 24, weight: .bold)
                errorNumberLabel.isHidden = true
                
                // checkbox
                if componentDetailModels.count > 0 && numberItemsTextfield.text != componentDetailModels[0].inventoryNumber?.description {
                    isCheckAll = false
                } else if componentDetailModels.count > 1 && numberItemsTextfield2.text != componentDetailModels[1].inventoryNumber?.description {
                    isCheckAll = false
                } else if componentDetailModels.count > 2 && numberItemsTextfield3.text != componentDetailModels[2].inventoryNumber?.description {
                    isCheckAll = false
                }
            } else {
                textField.font = .systemFont(ofSize: 16, weight: .regular)
                isCheckAll = false
            }
            btnCheck.setImage(UIImage(named: isCheckAll ? R.image.ic_checkbox.name : R.image.ic_uncheckbox.name), for: .normal)
        }
    }
    
    func validateDataInput() -> Bool {
        var isValidate = true
        if numberItemsTextfield.text?.count ?? 0 == 0 && numberItemsTextfield2.text?.count ?? 0 == 0 && numberItemsTextfield3.text?.count ?? 0 == 0 {
            errorNumberLabel.isHidden = false
            let full = "Vui lòng nhập số lượng".localized()
            errorNumberLabel.text = "\(full) \(textTypeError)."
            
            isValidate = false
        } 
        
        if componentDetailModels.count > 0 {
            if numberItemsTextfield.text == "0" {
                errorNumberLabel.isHidden = false
                errorNumberLabel.text = "Vui lòng nhập số lượng lớn hơn 0.".localized()
                isValidate = false
            }
        } else if componentDetailModels.count > 1 {
            if numberItemsTextfield.text == "0" && numberItemsTextfield2.text == "0" {
                errorNumberLabel.isHidden = false
                errorNumberLabel.text = "Vui lòng nhập số lượng lớn hơn 0.".localized()
                isValidate = false
            }
        } else if componentDetailModels.count > 2 {
            if numberItemsTextfield.text == "0" && numberItemsTextfield2.text == "0" && numberItemsTextfield3.text == "0" {
                errorNumberLabel.isHidden = false
                errorNumberLabel.text = "Vui lòng nhập số lượng lớn hơn 0.".localized()
                isValidate = false
            }
        }
        
        
        if reasonTextView.text.isEmpty && reasonView.isHidden == false {
            errorReasonLabel.isHidden = false
            
            isValidate = false
        }
        
        return isValidate
    }
    
    //MARK: request API
    private func requestInputStorage() {
        guard InternetManager.isConnected() else {
            self.showAlerInternet()
            return
        }
        
        var listComponent: [Dictionary<String, Any>] = []
        let userID = UserDefault.shared.getDataLoginModel().userId ?? ""
        let typeOfBusiness = type == .mc ? 1 : 2
        
        var isValidateCount1 = true
        var isValidateCount2 = true
        var isValidateCount3 = true
        var supplierNameString = ""
        
        if numberItemsTextfield.text?.count ?? 0 > 0 &&  self.componentDetailModels.count > 0 {
            let positionCode = self.componentDetailModels[0].positionCode ?? ""
            let quantity = unFormatNumber(stringValue: numberItemsTextfield.text ?? "0")
            let supplierCode = self.componentDetailModels[0].supplierCode ?? ""
            
            let modelComponent = ComponentInOutModel(positionCode:  positionCode, supplierCode: supplierCode, userId: userID, quantity: quantity, reason: reasonTextView.text, typeOfBusiness: typeOfBusiness)
            listComponent.append(modelComponent.dict)
            
            let inputValue = unFormatNumber(stringValue: numberItemsTextfield.text ?? "0")
            let lastValue = Double(componentDetailModels[0].maxInventoryNumber ?? 0)
            if inputValue > lastValue {
                isValidateCount1 = false
                
                supplierNameString = "\(self.componentDetailModels[0].supplierShortName ?? "")"
            }
        }
        if numberItemsTextfield2.text?.count ?? 0 > 0 &&  self.componentDetailModels.count > 1 {
            let positionCode = self.componentDetailModels[1].positionCode ?? ""
            let quantity = unFormatNumber(stringValue: numberItemsTextfield2.text ?? "0")
            let supplierCode = self.componentDetailModels[1].supplierCode ?? ""
            
            let modelComponent = ComponentInOutModel(positionCode:  positionCode, supplierCode: supplierCode, userId: userID, quantity: quantity, reason: reasonTextView.text, typeOfBusiness: typeOfBusiness)
            listComponent.append(modelComponent.dict)
            
            let inputValue = unFormatNumber(stringValue: numberItemsTextfield2.text ?? "0")
            let lastValue = Double(componentDetailModels[1].maxInventoryNumber ?? 0)
            if inputValue > lastValue {
                isValidateCount2 = false
                
                supplierNameString = supplierNameString + ((self.componentDetailModels[0].supplierShortName ?? "").count > 0 ? " & " : "") + "\(self.componentDetailModels[1].supplierShortName ?? "")"
            }
        }
        if numberItemsTextfield3.text?.count ?? 0 > 0 &&  self.componentDetailModels.count > 2 {
            let positionCode = self.componentDetailModels[2].positionCode ?? ""
            let quantity = unFormatNumber(stringValue: numberItemsTextfield3.text ?? "0")
            let supplierCode = self.componentDetailModels[2].supplierCode ?? ""
            
            let modelComponent = ComponentInOutModel(positionCode:  positionCode, supplierCode: supplierCode, userId: userID, quantity: quantity, reason: reasonTextView.text, typeOfBusiness: typeOfBusiness)
            listComponent.append(modelComponent.dict)
            
            let inputValue = unFormatNumber(stringValue: numberItemsTextfield3.text ?? "0")
            let lastValue = Double(componentDetailModels[2].maxInventoryNumber ?? 0)
            if inputValue > lastValue {
                isValidateCount3 = false
                
                supplierNameString = supplierNameString + ((self.componentDetailModels[1].supplierShortName ?? "").count > 0 ? " & " : "") + "\(self.componentDetailModels[2].supplierShortName ?? "")"
            }
        }
        
        var param = Dictionary<String, Any>()
        param = ["params" : listComponent]
        
        if !isValidateCount1 || !isValidateCount2 || !isValidateCount3 {
            self.alertAtribute(title: "Quá sức chứa".localized(), message1: "Số lượng nhập linh kiện thuộc nhà cung cấp ".localized(), message2: supplierNameString, message3: "  đang vượt quá sức chứa. Vui lòng kiểm tra lại.", acceptButton: "Đóng".localized())
        } else {
            let networkManager: NetworkManager = NetworkManager()
            networkManager.postInputStorage(param: param) { [weak self] result in
                switch result {
                case .success(let response):
                    guard let `self` = self else { return }
                    if response.code == 200 {
                        self.showToast(timeSeconds: 3.0, messgage: "Nhập kho linh kiện thành công!".localized())
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.navigationController?.popViewController(animated: true)
                        }
                    } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                        self.showAlertExpiredToken(code: response.code) { [weak self] result in
                            guard let self = self else { return }
                            self.requestInputStorage()
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
    }
    
    private func addTopShadow(forView view: UIView, shadowHeight height: CGFloat = 5) {
                let shadowPath = UIBezierPath()
                shadowPath.move(to: CGPoint(x: 0, y: 0))
                shadowPath.addLine(to: CGPoint(x: view.bounds.width, y:0))
                shadowPath.addLine(to: CGPoint(x: view.bounds.width, y: view.bounds.height ))
                shadowPath.addLine(to: CGPoint(x: view.bounds.width, y: view.bounds.height))
                shadowPath.close()

        view.layer.shadowColor = UIColor.red.cgColor
                view.layer.shadowOpacity = 1
                view.layer.masksToBounds = false
                view.layer.shadowPath = shadowPath.cgPath
            }
    
    private func requestOutputStorage() {
        guard InternetManager.isConnected() else {
            self.showAlerInternet()
            return
        }
        
        var listComponent: [Dictionary<String, Any>] = []
        let userID = UserDefault.shared.getDataLoginModel().userId ?? ""
        let typeOfBusiness = type == .mc ? 1 : 2
        
        var isValidateCount1 = true
        var isValidateCount2 = true
        var isValidateCount3 = true
        var supplierNameString = ""
        
        if numberItemsTextfield.text?.count ?? 0 > 0 &&  self.componentDetailModels.count > 0 {
            let positionCode = self.componentDetailModels[0].positionCode ?? ""
            let quantity = unFormatNumber(stringValue: numberItemsTextfield.text ?? "0")
            let supplierCode = self.componentDetailModels[0].supplierCode ?? ""
            
            let modelComponent = ComponentInOutModel(positionCode:  positionCode, supplierCode: supplierCode, userId: userID, quantity: quantity, reason: reasonTextView.text, typeOfBusiness: typeOfBusiness)
            listComponent.append(modelComponent.dict)
            
            let inputValue =  unFormatNumber(stringValue: numberItemsTextfield.text ?? "0")
            let lastValue = Double(componentDetailModels[0].inventoryNumber ?? 0)
            if inputValue > lastValue {
                isValidateCount1 = false
                
                supplierNameString = "\(self.componentDetailModels[0].supplierShortName ?? "")"
            }
        }
        if numberItemsTextfield2.text?.count ?? 0 > 0 &&  self.componentDetailModels.count > 1 {
            let positionCode = self.componentDetailModels[1].positionCode ?? ""
            let quantity = unFormatNumber(stringValue: numberItemsTextfield2.text ?? "0")
            let supplierCode = self.componentDetailModels[1].supplierCode ?? ""
            
            let modelComponent = ComponentInOutModel(positionCode:  positionCode, supplierCode: supplierCode, userId: userID, quantity: quantity, reason: reasonTextView.text, typeOfBusiness: typeOfBusiness)
            listComponent.append(modelComponent.dict)
            
            let inputValue = unFormatNumber(stringValue: numberItemsTextfield2.text ?? "0")
            let lastValue = Double(componentDetailModels[1].inventoryNumber ?? 0)
            if inputValue > lastValue {
                isValidateCount2 = false
                
                supplierNameString = supplierNameString + ((self.componentDetailModels[0].supplierShortName ?? "").count > 0 ? " & " : "") + "\(self.componentDetailModels[1].supplierShortName ?? "")"
            }
        }
        if numberItemsTextfield3.text?.count ?? 0 > 0 &&  self.componentDetailModels.count > 2 {
            let positionCode = self.componentDetailModels[2].positionCode ?? ""
            let quantity = unFormatNumber(stringValue: numberItemsTextfield3.text ?? "0")
            let supplierCode = self.componentDetailModels[2].supplierCode ?? ""
            
            let modelComponent = ComponentInOutModel(positionCode:  positionCode, supplierCode: supplierCode, userId: userID, quantity: quantity, reason: reasonTextView.text, typeOfBusiness: typeOfBusiness)
            listComponent.append(modelComponent.dict)
            
            let inputValue = unFormatNumber(stringValue: numberItemsTextfield3.text ?? "0")
            let lastValue = Double(componentDetailModels[2].inventoryNumber ?? 0)
            if inputValue > lastValue {
                isValidateCount3 = false
                
                supplierNameString = supplierNameString + ((self.componentDetailModels[1].supplierShortName ?? "").count > 0 ? " & " : "") + "\(self.componentDetailModels[2].supplierShortName ?? "")"
            }
        }
        
        var params = Dictionary<String, Any>()
        params = ["params" : listComponent]
        
        if !isValidateCount1 || !isValidateCount2 || !isValidateCount3 {
            self.alertAtribute(title: "Không đủ số lượng".localized(), message1: "Số lượng xuất linh kiện thuộc nhà cung cấp ".localized(), message2: supplierNameString, message3: " đang vượt quá số lượng tồn. Vui lòng kiểm tra lại.".localized(), acceptButton: "Đóng".localized())
        } else {
            let networkManager: NetworkManager = NetworkManager()
            networkManager.postOutputStorage(param: params) { [weak self] result in
                switch result {
                case .success(let response):
                    guard let `self` = self else { return }
                    if response.code == 200 {
                        self.showToast(timeSeconds: 3.0, messgage: "Xuất kho linh kiện thành công!".localized())
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.navigationController?.popViewController(animated: true)
                        }
                    } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                        self.showAlertExpiredToken(code: response.code) { [weak self] result in
                            guard let self = self else { return }
                            self.requestOutputStorage()
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
        
    }
    
}

extension DetailMCViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView == reasonTextView {
            if textView.text.count > 0 {
                errorReasonLabel.isHidden = true
            } else {
                errorReasonLabel.isHidden = false
            }
        }
        
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !reasonTextView.text.isEmpty
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = true
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        if textView == reasonTextView {
            if newText.count > 200 {
                reasonTextView.text = String(newText.prefix(200))
            }
        }
        return numberOfChars < 201
    }
}

extension DetailMCViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == numberItemsTextfield || textField == numberItemsTextfield2 || textField == numberItemsTextfield3 {
            if numberItemsTextfield.text?.count ?? 0 == 0 &&  numberItemsTextfield2.text?.count ?? 0 == 0 && numberItemsTextfield3.text?.count ?? 0 == 0 {
                errorNumberLabel.isHidden = false
                let num = "Vui lòng nhập số lượng".localized()
                errorNumberLabel.text = "\(num) \(textTypeError)."
            }
            else if textField.text == "0" {
                errorNumberLabel.isHidden = false
                errorNumberLabel.text = "Vui lòng nhập số lượng lớn hơn 0.".localized()
            }
            else {
                errorNumberLabel.isHidden = true
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == numberItemsTextfield || textField == numberItemsTextfield2 || textField == numberItemsTextfield3 {
            let completeString = (textField.text?.replacingOccurrences(of: numberFormatter.groupingSeparator, with: "") ?? "") + string
            var backSpace = false
            if let char = string.cString(using: String.Encoding.utf8) {
                let isBackSpace = strcmp(char, "\\b")
                if isBackSpace == -92 {
                    backSpace = true
                }
            }
            if string == "" && backSpace {
                return true
            }
            if string == "-" && textField.text == "" {
                return true
            }
            let result = completeString.prefix(8)
            let value = Double(result)
            
            if value != nil {
                let formattedNumber = numberFormatter.string(from: NSNumber(value: value!)) ?? ""
                textField.text = formattedNumber
                return string == numberFormatter.decimalSeparator
            }
            
            return result.count < 9
        }
        return true
    }
}
