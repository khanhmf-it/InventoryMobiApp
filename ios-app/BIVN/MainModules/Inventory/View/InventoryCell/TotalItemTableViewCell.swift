//
//  TotalItemTableViewCell.swift
//  BIVN
//
//  Created by Tinhvan on 02/11/2023.
//

import UIKit
import Localize_Swift

class TotalItemTableViewCell: BaseTableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var totalTextField: UITextField!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = "Tổng".localized()
        totalTextField.isUserInteractionEnabled = false
        updateNumberFormatter()
    }
    
    func setDataToCell(totalValue: Double) {
        if let formattedNumber = numberFormatter.string(from: NSNumber(value: Double(totalValue) )) {
            totalTextField.font = fontUtils.size24.bold
            totalTextField.text = formattedNumber
            
        }
    }
}
