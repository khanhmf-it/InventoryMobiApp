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
    @IBOutlet weak var titleModelLabel: UILabel!
    @IBOutlet weak var titleAddressLabel: UILabel!
    @IBOutlet weak var titleStatusLabel: UILabel!

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var roomLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setDataToCell(status: Int, model: AuditInfoModels) {
        titleRoomLabel.text = "Phòng ban".localized()
        titleArenaLabel.text = "Khu vực".localized()
        titleCodeLabel.text = "Mã linh kiện".localized()
        titleModelLabel.text = "Model code".localized()
        titleAddressLabel.text = "Vị trí".localized()
        titleStatusLabel.text = "Trạng thái".localized()
        statusLabel.text = model.getStatusMonitor()
        statusLabel.textColor = UIColor(named: model.getColorStatusMonitor())
        roomLabel.text = model.departmentName
        areaLabel.text = model.locationName
        let componentCode = model.componentCode?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let modelCode = model.modelCode?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        codeLabel.text = componentCode.isEmpty ? "--" : componentCode
        modelLabel.text = modelCode.isEmpty ? "--" : modelCode
        addressLabel.text = model.positionCode?.isEmpty == false ? model.positionCode : "--"
    }
    
}
