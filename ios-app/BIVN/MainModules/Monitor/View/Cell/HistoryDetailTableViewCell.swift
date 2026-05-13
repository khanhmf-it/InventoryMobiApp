//
//  HistoryDetailTableViewCell.swift
//  BIVN
//
//  Created by tinhvan on 01/12/2023.
//

import UIKit
import Localize_Swift

class HistoryDetailTableViewCell: BaseTableViewCell {
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTimeLabel: UILabel!
    @IBOutlet weak var titleUpdateStatusLabel: UILabel!
    @IBOutlet weak var totalView: UIStackView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var titleTotalLabel: UILabel!
    @IBOutlet weak var titlePersonLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var personLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleUpdateLable: UILabel!
    @IBOutlet weak var statusView: UIStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setData(data: ResultDataHistory) {
        titleTimeLabel.text = "Thời gian cập nhật:".localized()
        updateNumberFormatter()
        timeLabel.text = data.createdAt?.formatDateWithInputAndOutputType(inputFormat: TypeFormatDate.ServerFormat.rawValue, outputFormat: TypeFormatDate.DD_MM_YYYY_HH_mm.rawValue) ?? ""
        personLabel.text = data.createdBy
        titlePersonLabel.text = data.changeLogModel?.getPersonHistoryChange()
        statusLabel.text = data.changeLogModel?.getNewStatus()
        statusLabel.textColor = UIColor(named: data.changeLogModel?.getColorNewStatus() ?? "")
        let newTotal = numberFormatter.string(from: NSNumber(value: Double("\(data.changeLogModel?.newQuantity ?? 0)") ?? 0))
        let oldTotal = numberFormatter.string(from: NSNumber(value: Double("\(data.changeLogModel?.oldQuantity ?? 0)") ?? 0))
        if (data.changeLogModel?.newQuantity == 0 || data.changeLogModel?.newQuantity == nil) && (data.changeLogModel?.oldQuantity == 0 || data.changeLogModel?.oldQuantity == nil) {
            totalView.isHidden = true
        } else if data.changeLogModel?.oldQuantity == 0 || data.changeLogModel?.oldQuantity == nil {
            titleTotalLabel.text = "Nhập tổng SL: ".localized()
            totalLabel.text = newTotal ?? ""
            totalLabel.textColor = UIColor(named: R.color.buttonBlue.name)!
            widthConstraint.constant = 100
        }
        else if  data.changeLogModel?.oldQuantity != data.changeLogModel?.newQuantity{
            titleTotalLabel.text = "Cập nhật tổng SL: ".localized()
            totalLabel.text = "\(oldTotal ?? "") -> \(newTotal ?? "")"
            totalLabel.textColor = UIColor(named: R.color.buttonBlue.name)!
            widthConstraint.constant = 120
        } else {
            totalView.isHidden = true
        }
        if data.changeLogModel?.newStatus ?? 0 != data.changeLogModel?.oldStatus ?? 0 {
            titleUpdateStatusLabel.text = "Cập nhật trạng thái".localized()
            statusView.isHidden = false
        } else {
            statusView.isHidden = true
        }
        
        if (data.changeLogModel?.oldQuantity == data.changeLogModel?.newQuantity) && (data.changeLogModel?.oldStatus == data.changeLogModel?.newStatus) && data.changeLogModel?.isChangeCDetail == false {
            titleUpdateLable.text = "Cập nhật dữ liệu chi tiết phiếu".localized()
        } else {
            titleUpdateLable.isHidden = true
        }
    }
    
}
