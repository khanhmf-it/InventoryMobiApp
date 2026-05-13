//
//  TitleHistoryCell.swift
//  BIVN
//
//  Created by Tan Tran on 28/12/2023.
//

import UIKit
import Localize_Swift

class TitleHistoryCell: BaseTableViewCell {

    @IBOutlet weak var contentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setTitleHistory() {
        contentLabel.textColor = UIColor(named: R.color.textDarkBlue.name)
        contentLabel.font = fontUtils.size18.bold
        contentLabel.text = "Lịch sử".localized()
    }
    
    func setTitleError(content: String) {
        contentLabel.textColor = UIColor(named: R.color.textRed.name)
        contentLabel.font = fontUtils.size14.regular
        contentLabel.text = content
    }
    
}
