//
//  TitleInventoryCell.swift
//  BIVN
//
//  Created by Tinhvan on 02/11/2023.
//

import UIKit
import Localize_Swift

class TitleInventoryCell: UITableViewCell {
    @IBOutlet weak var numberOfBoxLabel: UILabel!
    @IBOutlet weak var qualityPerBoxLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        numberOfBoxLabel.text = "Số thùng".localized()
        qualityPerBoxLabel.text = "Số lượng/ thùng".localized()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
