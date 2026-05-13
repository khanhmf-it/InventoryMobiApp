//
//  AccessoryCell.swift
//  BIVN
//
//  Created by TVO_M1 on 8/1/25.
//

import UIKit
import Localize_Swift

class AccessoryCell: UITableViewCell{
    
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblQuantity: UILabel!
    @IBOutlet weak var lblValueName: UILabel!
    @IBOutlet weak var lblValueQuantity: UILabel!
    @IBOutlet weak var viewContent: UIView!
    
    func fillData(billName: String, billQuantity: String, bom: String?){
        let numberValue = bom != nil && bom != "0" ?  "\(billQuantity) [ \(bom!) ]" : "\(billQuantity)"
        let attributedString = NSMutableAttributedString(string: numberValue)
        let buildQuantityRange = (numberValue as NSString).range(of: billQuantity)
        attributedString.addAttribute(.foregroundColor, value: UIColor(named: R.color.textDarkBlue.name) ?? 0, range: buildQuantityRange)
        if(numberValue.contains("[")){
            let buillBom = (numberValue as NSString).range(of: "[ \(bom ?? "") ]")
            attributedString.addAttribute(.foregroundColor, value: UIColor(named: R.color.textRed.name) ?? 0, range: buillBom)
        }
        lblName.text = "Số phiếu".localized()
        lblQuantity.text = "Số lượng".localized()
        lblValueName.text = billName
        lblValueQuantity.attributedText = attributedString
        
        lblName.font = fontUtils.size14.regular
        lblQuantity.font = fontUtils.size14.regular
        lblValueName.font = fontUtils.size14.medium
        lblValueQuantity.font = fontUtils.size14.medium
        
    }
}
