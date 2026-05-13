//
//  InventoryTableViewCell.swift
//  BIVN
//
//  Created by Luyện Đào on 24/11/2023.
//

import UIKit
import Localize_Swift

class InventoryTableViewCell: UITableViewCell {
    @IBOutlet weak var titleTypeOfStageLabel: UILabel!
    @IBOutlet weak var valueTypeOfStageLabel: UILabel!
    @IBOutlet weak var titleNumberStageLabel: UILabel!
    @IBOutlet weak var valueNumberStageLabel: UILabel!
    @IBOutlet weak var titleNameStageLabel: UILabel!
    @IBOutlet weak var valueNameStageLabel: UILabel!
    @IBOutlet weak var titleStatusLabel: UILabel!
    @IBOutlet weak var valueStatusLabel: UILabel!
    @IBOutlet weak var statusStackView: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        fillData()
    }
    
    func fillData() {
        titleTypeOfStageLabel.text = "Loại công đoạn".localized()
        titleNumberStageLabel.text = "STT công đoạn".localized()
        titleNameStageLabel.text = "Tên công đoạn".localized()
        titleStatusLabel.text = "Trạng thái".localized()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fillData(model: DocCInfoModels) {
        valueTypeOfStageLabel.text = model.lineType
        valueNumberStageLabel.text = model.stageNumber
        valueNameStageLabel.text = model.stageName
        valueStatusLabel.text = model.getStatus()
        valueStatusLabel.textColor = UIColor(named: model.getColorStatus())
    }
    
}
