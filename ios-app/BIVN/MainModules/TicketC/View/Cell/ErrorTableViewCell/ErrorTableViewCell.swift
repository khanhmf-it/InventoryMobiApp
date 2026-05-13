//
//  ErrorTableViewCell.swift
//  BIVN
//
//  Created by Tan Tran on 26/12/2023.
//

import UIKit
import Localize_Swift

class ErrorTableViewCell: BaseTableViewCell {
    @IBOutlet weak var titleErrorLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    func setupUI() {
        titleErrorLabel.text = "Vui lòng nhập số lượng và số thùng.".localized()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
