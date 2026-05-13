//
//  PartCodeTableViewCell.swift
//  BIVN
//
//  Created by Luyện Đào on 22/11/2023.
//
import UIKit

class PartCodeTableViewCell: BaseTableViewCell {
    @IBOutlet weak var quantityPerBomTextField: UITextField!
    @IBOutlet weak var sttLabel: UILabel!
    @IBOutlet weak var partCodeLabel: UILabel!
    @IBOutlet weak var quantityOfBomLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var emptyDataLabel: UILabel!
    @IBOutlet weak var checkbokUIButton: CustomerCheckBox!
    
    var qualityNew: String?
    var passDataClosure: ((_ model: DocComponentCs, Bool) -> Void)?
    var dataTest: DocComponentCs?
    var quantityPerBom: String = ""
    var textquantityPerBom: String?
    var sumTotal: ((Int, String, Bool) -> ())?
    var index: Int = -1
    var valueSum: Double?
    var regionUS = false
    var isShowCheck : Bool = false
    var isCheck : Bool? = false
    var isTickCheckBox : Bool = false
    var checkboxOnclick : ((Bool, Int) ->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        emptyDataLabel.isHidden = true
        quantityPerBomTextField.delegate = self
        quantityPerBomTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        checkbokUIButton.setTitle("", for: .normal)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fillDataQuality(valueSum: Double, quantityOfBom: Double, index: Int, isCheckHideTextField: Bool = true, isHighLight: Bool = false, isCheck: Bool = false, isHightlightLocal: Bool = false, isTickCheckBox: Bool = false, defaultSum: Double = 0, isDetailHistoryScreen: Bool = false) {
        self.index = index
        self.isCheck = isCheck
        self.isTickCheckBox = isTickCheckBox
        quantityPerBomTextField.isUserInteractionEnabled = isCheckHideTextField
        if dataTest?.componentCode == "" {
            partCodeLabel.text = dataTest?.modelCode
        } else {
            partCodeLabel.text = dataTest?.componentCode
        }
        let quantityOfBomTotal = Int(dataTest?.quantityOfBom ?? 0)
        quantityOfBomLabel.text = "\(quantityOfBomTotal)"
        quantityPerBomTextField.text = dataTest?.quantityPerBom?.description
        self.index = index
        let result = unFormatNumber(stringValue: "\(valueSum.removeZerosFromEnd())", regionUS: regionUS)
        var total = "\(result * (Double(quantityOfBom)))"
        
        if (dataTest?.isCheck ?? false == false || dataTest?.isCheck == nil) {
            if dataTest?.isHighLight ?? false && defaultSum == valueSum {
                total = dataTest?.quantityPerBom?.description ?? ""
            } else {
                total = "\(result * (Double(quantityOfBom)))"
            }
            
        } else {
            total = dataTest?.quantityPerBom?.description ?? ""
        }
        
        if isDetailHistoryScreen {
            total = dataTest?.quantityPerBom?.description ?? ""
        }
        
        quantityPerBom = total
        if let formattedNumber = numberFormatter.string(from: NSNumber(value: Double(total) ?? 0)) {
            quantityPerBomTextField.text = formattedNumber
            qualityNew = formattedNumber
        }
        
        if valueSum == 0 {
            quantityPerBomTextField.text = "0"
        }
        
        if (isHighLight && defaultSum == valueSum) || isHightlightLocal {
            containerView.backgroundColor = UIColor(named: R.color.yellow.name)
        } else  {
            containerView.backgroundColor = .white
        }

        if isShowCheck {
            checkbokUIButton.isHidden = false
        } else {
            checkbokUIButton.isHidden = true
        }
        if isTickCheckBox {
            checkbokUIButton.isChecked = true
        } else {
            checkbokUIButton.isChecked = false
        }
    }
    
    @IBAction func checkBoxOnClick(_ sender: Any) {
        guard self.isCheck != nil else {return}
        if let listener = self.checkboxOnclick {
            listener(!isTickCheckBox, self.index)
        } else {}
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
    }
    
}

extension PartCodeTableViewCell: UITextFieldDelegate {
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let dataTest = dataTest else {return}
        let result = Int(valueSum ?? 0)
        let result2 = Int(dataTest.quantityOfBom ?? 0)
        if textField.text != "\(result * result2)" {
            dataTest.isCheck = true
            sumTotal?(self.index ,textField.text ?? "", false)
            passDataClosure?(dataTest, true)
        } else {
            passDataClosure?(dataTest, false)
        }
    }
}

