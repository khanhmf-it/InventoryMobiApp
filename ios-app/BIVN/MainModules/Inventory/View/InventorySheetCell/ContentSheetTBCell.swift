//
//  ContentSheetTBCell.swift
//  BIVN
//
//  Created by Tinhvan on 03/11/2023.
//

import UIKit
import Localize_Swift

class ContentSheetTBCell: UITableViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var sttLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var bomLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var viewLineTop: UIView!
    @IBOutlet weak var viewLineBot: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        sttLabel.text = "STT".localized()
        codeLabel.text = "Mã linh kiện".localized()
        bomLabel.text = "BOM"
        numberLabel.text = "Số lượng".localized()
    }
    
    func setDataToCell(isContent: Bool, index: Int) {
        
        viewLineTop.backgroundColor = UIColor(named: R.color.lineColor.name)
        viewLineBot.backgroundColor = index == 8 ? UIColor(named: R.color.lineColor.name) : UIColor.clear
        
        if !isContent {
            containerView.backgroundColor = UIColor(named: R.color.grey1.name)
            
            sttLabel.font = .systemFont(ofSize: 16, weight: .medium)
            codeLabel.font = .systemFont(ofSize: 16, weight: .medium)
            bomLabel.font = .systemFont(ofSize: 16, weight: .medium)
            numberLabel.font = .systemFont(ofSize: 16, weight: .medium)
        } else {
            sttLabel.font = .systemFont(ofSize: 16, weight: .regular)
            codeLabel.font = .systemFont(ofSize: 16, weight: .regular)
            bomLabel.font = .systemFont(ofSize: 16, weight: .regular)
            numberLabel.font = .systemFont(ofSize: 16, weight: .regular)
            
            containerView.backgroundColor = UIColor.clear
            sttLabel.text = (index + 1).description
            codeLabel.text = "DOCC\(index + 1)"
            bomLabel.text = (index + 1).description
            numberLabel.text = (10 * (index + 1)).description
        }
    }
    
}
