//
//  RowInventoryTableViewCell.swift
//  BIVN
//
//  Created by Luyện Đào on 22/11/2023.
//

import UIKit
import Localize_Swift

class RowInventoryTableViewCell: BaseTableViewCell {
    
    @IBOutlet weak var quantityOfBomTextField: UITextField!
    @IBOutlet weak var quantityPerBomTextField: UITextField!
    @IBOutlet weak var closeView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var viewLeft: UIView!
    @IBOutlet weak var iconLeft: UIImageView!
    @IBOutlet weak var lineViewBottom: UIView!
    @IBOutlet weak var checkBoxButton: CustomerCheckBox!
    
    var deleteRow: ((Int) -> ())?
    var sumTotal: ((Int, String, String) -> ())?
    var index: Int = -1
    var isShowCheck : Bool = false
    var isCheck : Bool? = false
    var checkboxOnclick : ((Bool, Int) ->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setFontPlaceHolder()
        iconLeft.isHidden = true
        quantityOfBomTextField.font = fontUtils.size16.medium
        quantityPerBomTextField.font = fontUtils.size16.medium
        quantityOfBomTextField.delegate = self
        quantityPerBomTextField.delegate = self
        updateNumberFormatter()
        quantityPerBomTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        quantityOfBomTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        checkBoxButton.setTitle("", for: .normal)
        
    }
    
    func updateBackgroundColor(for textField: UITextField) {
        if let text = textField.text, let value = Double(text), value == 0 {
            textField.backgroundColor = UIColor.red
            
        } else {
            textField.backgroundColor = UIColor.clear
        }
    }
    
    
    func setFontPlaceHolder() {
        let attributes = [
            NSAttributedString.Key.foregroundColor: UIColor(named: R.color.textGray.name),
            NSAttributedString.Key.font : fontUtils.size14.regular
        ]
        
        quantityOfBomTextField.attributedPlaceholder = NSAttributedString(string: "Nhập SL...".localized(), attributes:attributes as [NSAttributedString.Key : Any])
        quantityPerBomTextField.attributedPlaceholder = NSAttributedString(string: "Nhập SL/thùng...".localized(), attributes:attributes as [NSAttributedString.Key : Any])
    }
    
    func setDataToCell(data: DocComponentABEs, index: Int, isLast: Bool = false, isCheck: Bool, isHideTextField: Bool = true) {
        if data.quantityPerBom != nil {
            quantityPerBomTextField.text = (Double(data.quantityPerBom ?? 0)) >= 0 ? numberFormatter.string(from: NSNumber(value: Double("\(data.quantityPerBom ?? 0)") ?? 0)) : ""
        } else {
            quantityPerBomTextField.text = ""
        }
        if  data.quantityOfBom != nil {
            quantityOfBomTextField.text = (Double(data.quantityOfBom ?? 0)) >= 0 ? numberFormatter.string(from: NSNumber(value: Double("\(data.quantityOfBom ?? 0)") ?? 0)) : ""
        } else {
            quantityOfBomTextField.text = ""
        }
        quantityPerBomTextField.isUserInteractionEnabled = isHideTextField
        quantityOfBomTextField.isUserInteractionEnabled = isHideTextField
        self.index = index
        lineViewBottom.isHidden = !isLast
        closeView.isHidden = true
        closeView.addTapGestureRecognizer {
            self.deleteRow?(index)
        }
        self.isCheck = isCheck
        self.checkBoxButton.isChecked = isCheck
        self.checkBoxButton.isHidden = !self.isShowCheck
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        
        if textField == quantityOfBomTextField || textField == quantityPerBomTextField {
            sumTotal?(self.index , quantityPerBomTextField.text ?? "0" ,quantityOfBomTextField.text ?? "0")
            
            textField.font = fontUtils.size16.medium
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
    
    @IBAction func checkBoxAction(_ sender: Any) {
        guard let isCheck = self.isCheck else {return}
        if let listener = self.checkboxOnclick {
            listener(!isCheck, self.index)
        } else {}
    }
}

extension RowInventoryTableViewCell: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == quantityPerBomTextField || textField == quantityOfBomTextField {
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
            
            if textField == quantityPerBomTextField {
                result = completeString.prefix(6)
            } else {
                result = completeString.prefix(3)
            }
            let value = Double(result)
            if value != nil {
                let formattedNumber = numberFormatter.string(from: NSNumber(value: value!)) ?? ""
                textField.text = formattedNumber
                updateBackgroundColor(for: textField)
                sumTotal?(self.index , quantityPerBomTextField.text ?? "0" ,quantityOfBomTextField.text ?? "0")
                return string == numberFormatter.decimalSeparator
            }
            
            return result.count < 7
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        closeView.isHidden = false
        iconLeft.isHidden = false
        closeView.backgroundColor = UIColor(named: R.color.buttonBlue.name)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        closeView.isHidden = true
        iconLeft.isHidden = true
        closeView.backgroundColor = UIColor(named: R.color.white.name)
        updateBackgroundColor(for: textField)
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


