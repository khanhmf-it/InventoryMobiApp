//
//  TitleDetailTableViewCell.swift
//  BIVN
//
//  Created by Luyện Đào on 22/11/2023.
//

import UIKit
import Localize_Swift

class TitleDetailTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = "Chi tiết".localized()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
