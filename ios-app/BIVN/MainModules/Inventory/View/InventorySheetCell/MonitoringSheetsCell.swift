//
//  MonitoringSheetsCell.swift
//  BIVN
//
//  Created by Tinhvan on 08/11/2023.
//

import UIKit
import Localize_Swift

class MonitoringSheetsCell: UITableViewCell {
    @IBOutlet weak var titleRoomLabel: UILabel!
    @IBOutlet weak var titleArenaLabel: UILabel!
    @IBOutlet weak var titleCodeLabel: UILabel!
    @IBOutlet weak var titleAddressLabel: UILabel!
    @IBOutlet weak var titleStatusLabel: UILabel!

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var roomLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setDataToCell(status: Int, model: AuditInfoModels) {
        titleRoomLabel.text = "Phòng ban".localized()
        titleRoomLabel.text = "Khu vực".localized()
        titleRoomLabel.text = "Mã linh kiện".localized()
        titleRoomLabel.text = "Vị trí".localized()
        titleRoomLabel.text = "Trạng thái".localized()
        statusLabel.text = model.getStatusMonitor()
        statusLabel.textColor = UIColor(named: model.getColorStatusMonitor())
        roomLabel.text = model.departmentName
        areaLabel.text = model.locationName
        codeLabel.text = model.componentCode
        addressLabel.text = model.positionCode
    }
    
}
