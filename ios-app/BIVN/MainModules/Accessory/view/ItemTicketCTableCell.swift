//
//  ItemTicketCTableCell.swift
//  BIVN
//
//  Created by TVO_M1 on 22/1/25.
//

import UIKit

class ItemTicketCTableCell: BaseTableViewCell {
    @IBOutlet weak var quantityPerBomTextField: UITextField!
    @IBOutlet weak var sttLabel: UILabel!
    @IBOutlet weak var partCodeLabel: UILabel!
    @IBOutlet weak var quantityOfBomLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var emptyDataLabel: UILabel!
    @IBOutlet weak var checkbokUIButton: CustomerCheckBox!
    
    var passDataClosure: ((_ model: DocComponentCs, Bool) -> Void)?
    var dataTest: DocComponentCs?
    var regionUS = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        emptyDataLabel.isHidden = true
        checkbokUIButton.setTitle("", for: .normal)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fillDataQuality() {
        quantityPerBomTextField.isUserInteractionEnabled = false
        let quantityOfBomTotal = Int(dataTest?.quantityOfBom ?? 0)
        quantityOfBomLabel.text = "\(quantityOfBomTotal)"
        quantityPerBomTextField.text = dataTest?.quantityPerBom?.description
        if dataTest?.modelCode == "" {
            partCodeLabel.text = dataTest?.componentCode
        } else {
            partCodeLabel.text = dataTest?.modelCode
        }
        if let formattedNumber = numberFormatter.string(from: NSNumber(value: Double(dataTest?.quantityPerBom ?? 0))) {
            quantityPerBomTextField.text = formattedNumber
        }
        
        if dataTest?.isHighLight == true {
            containerView.backgroundColor = UIColor(named: R.color.yellow.name)
        } else  {
            containerView.backgroundColor = .white
        }

    }
    
}
