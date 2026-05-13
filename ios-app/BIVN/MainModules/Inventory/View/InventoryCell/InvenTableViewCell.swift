//
//  InvenTableViewCell.swift
//  BIVN
//
//  Created by Tinhvan on 01/11/2023.
//

import UIKit
import Localize_Swift

class InvenTableViewCell: BaseTableViewCell {
    
    @IBOutlet weak var numberTextField: UITextField!
    @IBOutlet weak var binsTextField: UITextField!
    @IBOutlet weak var closeView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var viewRight: UIView!
    @IBOutlet weak var viewLeft: UIView!
    @IBOutlet weak var iconRight: UIImageView!
    @IBOutlet weak var iconLeft: UIImageView!
    @IBOutlet weak var lineViewBottom: UIView!
    
    var deleteRow: ((Int) -> ())?
    var sumTotal: ((Int, String, String, Bool) -> ())?
    var sumTotalMonitor: ((Int, String, String, Bool) -> ())?
    var isCheckMonitor: ((Int,Bool) -> ())?
    var index: Int = -1
    var isCheckBox = false
    var regionUS = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setFontPlaceHolder()
        updateNumberFormatter()
        numberTextField.delegate = self
        binsTextField.delegate = self
        numberTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        binsTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    func setDataToCell(data: DocComponentABEs, index: Int, isLast: Bool = false) {
        
        if data.quantityPerBom != nil {
            binsTextField.text = (Double(data.quantityPerBom ?? 0)) >= 0 ? numberFormatter.string(from: NSNumber(value: Double("\(data.quantityPerBom ?? 0)") ?? 0)) : ""
        } else {
            binsTextField.text = ""
        }
        if  data.quantityOfBom != nil {
            numberTextField.text = (Double(data.quantityOfBom ?? 0)) >= 0 ? numberFormatter.string(from: NSNumber(value: Double("\(data.quantityOfBom ?? 0)") ?? 0)) : ""
        } else {
            numberTextField.text = ""
        }
        
        self.index = index
        
        binsTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        numberTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        lineViewBottom.isHidden = !isLast
        closeView.isHidden = true
        closeView.addTapGestureRecognizer {
            self.deleteRow?(index)
        }
        iconRight.isHidden = true
    }
    
    func updateBackgroundColor(for textField: UITextField) {
        // Kiểm tra nếu textField có giá trị
        if let text = textField.text, !text.isEmpty {
            // Kiểm tra giá trị có phải là 0 không
            if let value = Double(text), value == 0 {
                textField.backgroundColor = UIColor.red // Nếu giá trị bằng 0, nền đỏ
            } else {
                textField.backgroundColor = UIColor.clear // Nếu không phải 0, nền trong suốt
            }
        } else {
            // Nếu không có giá trị (trường hợp rỗng), đặt nền trong suốt
            textField.backgroundColor = UIColor.clear
        }
    }
    
    func setFontPlaceHolder() {
        let attributes = [
            NSAttributedString.Key.foregroundColor: UIColor(named: R.color.textGray.name),
            NSAttributedString.Key.font : fontUtils.size14.regular
        ]
        
        numberTextField.attributedPlaceholder = NSAttributedString(string: "Nhập SL...".localized(), attributes:attributes as [NSAttributedString.Key : Any])
        binsTextField.attributedPlaceholder = NSAttributedString(string: "Nhập SL/thùng...".localized(), attributes:attributes as [NSAttributedString.Key : Any])
    }
    
    func setDataToCellMonitor(data: DocComponentABEs?, index: Int, isLast: Bool = false, isHiddenCheckBox: Bool = true, isHideTextField: Bool = true) {
        binsTextField.isUserInteractionEnabled = isHideTextField
        numberTextField.isUserInteractionEnabled = isHideTextField
        self.isCheckBox = data?.isCheckBox ?? false
        self.iconRight.image = UIImage(named: data?.isCheckBox ?? false ? R.image.ic_checkbox.name : R.image.ic_uncheckbox.name)
        
        if data?.quantityPerBom != nil {
            binsTextField.text = (Double(data?.quantityPerBom ?? 0)) >= 0 ? numberFormatter.string(from: NSNumber(value: Double("\(data?.quantityPerBom ?? 0)") ?? 0)) : ""
        } else {
            binsTextField.text = ""
        }
        if  data?.quantityOfBom != nil {
            numberTextField.text = (Double(data?.quantityOfBom ?? 0)) >= 0 ? numberFormatter.string(from: NSNumber(value: Double("\(data?.quantityOfBom ?? 0)") ?? 0)) : ""
        } else {
            numberTextField.text = ""
        }
        
        self.index = index
        
        binsTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        numberTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        lineViewBottom.isHidden = !isLast
        closeView.isHidden = true
        closeView.addTapGestureRecognizer {
            self.index = -1
            self.deleteRow?(index)
        }
        iconRight.isHidden = isHiddenCheckBox
        viewRight.addTapGestureRecognizer {
            self.isCheckBox = !self.isCheckBox
            self.iconRight.image = UIImage(named: self.isCheckBox ? R.image.ic_checkbox.name : R.image.ic_uncheckbox.name)
            self.isCheckMonitor?(self.index,self.isCheckBox)
        }
    }
    
    func setDataToCellDetailMonitor(data: DocComponentABEs, index: Int, isLast: Bool = false, isHiddenCheckBox: Bool = true, isHideTextField: Bool = true) {
        binsTextField.isUserInteractionEnabled = isHideTextField
        numberTextField.isUserInteractionEnabled = isHideTextField
        self.isCheckBox = false
        self.iconRight.image = UIImage(named: self.isCheckBox ? R.image.ic_checkbox.name : R.image.ic_uncheckbox.name)
        if let formattedBinNumber = numberFormatter.string(from: NSNumber(value: Double(data.quantityPerBom ?? 0) )) {
            binsTextField.text = formattedBinNumber
        }
        if let formattedNumber = numberFormatter.string(from: NSNumber(value: Double(data.quantityOfBom ?? 0) )) {
            numberTextField.text = formattedNumber
        }
        self.index = index
        
        binsTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        numberTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        lineViewBottom.isHidden = !isLast
        closeView.isHidden = true
        closeView.addTapGestureRecognizer {
            self.deleteRow?(index)
        }
        iconRight.isHidden = isHiddenCheckBox
        viewRight.addTapGestureRecognizer {
            self.isCheckBox = !self.isCheckBox
            
            self.iconRight.image = UIImage(named: self.isCheckBox ? R.image.ic_checkbox.name : R.image.ic_uncheckbox.name)
            self.sumTotalMonitor?(self.index, self.binsTextField.text ?? "0", self.numberTextField.text ?? "0", self.isCheckBox)
            
            self.sumTotal?(self.index , self.binsTextField.text ?? "0" , self.numberTextField.text ?? "0", self.isCheckBox)
        }
    }
    
    func setDataToCellQRScanItem(data: DocComponentABEs, index: Int, isLast: Bool = false) {
        
        let attributes = [
            NSAttributedString.Key.foregroundColor: UIColor(named: R.color.textGray.name),
            NSAttributedString.Key.font : fontUtils.size14.regular
        ]
        numberTextField.attributedPlaceholder = NSAttributedString(string: "", attributes:attributes as [NSAttributedString.Key : Any])
        binsTextField.attributedPlaceholder = NSAttributedString(string: "", attributes:attributes as [NSAttributedString.Key : Any])
        
        binsTextField.text = (data.quantityPerBom ?? 0) > 0 ? numberFormatter.string(from: NSNumber(value: Double("\(data.quantityPerBom ?? 0)") ?? 0)) : ""
        numberTextField.text = (data.quantityOfBom ?? 0) > 0 ? numberFormatter.string(from: NSNumber(value: Double("\(data.quantityOfBom ?? 0)") ?? 0)) : ""
        self.index = index
        
        numberTextField.isUserInteractionEnabled = false
        binsTextField.isUserInteractionEnabled = false
        
        binsTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        numberTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        lineViewBottom.isHidden = !isLast
        closeView.isHidden = true
        closeView.addTapGestureRecognizer {
            self.deleteRow?(index)
        }
        
        self.iconRight.isHidden = true
    }
    
    func setEditView(isHidden: Bool) {
        binsTextField.isUserInteractionEnabled = isHidden
        numberTextField.isUserInteractionEnabled = isHidden
        iconRight.isHidden = !isHidden
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if textField == numberTextField || textField == binsTextField {
            sumTotalMonitor?(self.index , binsTextField.text ?? "0" ,numberTextField.text ?? "0", self.isCheckBox)
            sumTotal?(self.index, binsTextField.text ?? "0", numberTextField.text ?? "0", self.isCheckBox)
        }
    }
    
    private func addBorder() {
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(named: R.color.buttonBlue.name)?.cgColor
        
        viewLeft.backgroundColor = UIColor(named: R.color.buttonBlue.name)
    }
    
    private func removeBorder() {
        containerView.layer.borderWidth = 0
        
        viewLeft.backgroundColor = UIColor.clear
    }
}

extension InvenTableViewCell: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == numberTextField || textField == binsTextField {
            var result: String.SubSequence
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
            
            if textField == binsTextField {
                result = completeString.prefix(6)
            } else {
                result = completeString.prefix(3)
            }
            
            var value = Double(result)
            
            if regionUS {
                if let _ = result.range(of: ".0") {
                    value = nil
                }
            }
            
            if value != nil {
                let formattedNumber = value?.formattedString(numberFormatter: numberFormatter)
                textField.text = formattedNumber
                updateBackgroundColor(for: textField)
                self.sumTotal?(self.index , self.binsTextField.text ?? "0" , self.numberTextField.text ?? "0", self.isCheckBox)
                return string == numberFormatter.decimalSeparator
            } else {
                if completeString.count > 7 {
                    return false
                }
            }
            
            return result.count < 8
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        closeView.isHidden = false
        
        addBorder()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        closeView.isHidden = true
        
        removeBorder()
        updateBackgroundColor(for: textField)
    }
}

extension Double {
    func formattedString(_ maximumFractionDigits: Double = 5, numberFormatter: NumberFormatter) -> String? {
        numberFormatter.maximumFractionDigits = Int(maximumFractionDigits)
        
        return numberFormatter.string(for:self)
    }
}
