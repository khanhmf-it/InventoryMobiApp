//
//  TitleHistoryTableViewCell.swift
//  BIVN
//
//  Created by Luyện Đào on 01/12/2023.
//

import UIKit
import Localize_Swift

class TitleHistoryTableViewCell: UITableViewCell {
    @IBOutlet weak var titleHistoryLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleHistoryLabel.text = "Lịch sử".localized()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
