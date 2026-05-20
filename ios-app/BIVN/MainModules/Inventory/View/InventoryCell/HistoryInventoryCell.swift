//
//  HistoryInventoryCell.swift
//  BIVN
//
//  Created by Tinhvan on 02/11/2023.
//

import UIKit
import Localize_Swift

class HistoryInventoryCell: BaseTableViewCell {
    
    @IBOutlet weak var updateDetailLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var nameInventoryLabel: UILabel!
    @IBOutlet weak var totalInventoryLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var updateDetailTicketLabel: UILabel!
    @IBOutlet weak var icRight: UIImageView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var noteLabel: UILabel!
    
    enum StatusInventoryType: Int {
        case progress = 1
        case finished = 2
        case waiting = 3
    }
    
    var colorTextStatus: UIColor = UIColor()
    var textStatus: String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = .zero
        containerView.layer.cornerRadius = 4
    }
    func clearShadowBorder() {
        containerView.layer.shadowOpacity = 0
        containerView.layer.shadowOffset = .zero
        containerView.layer.cornerRadius = 0
    }
    func fillDataDocC(data: DocHistory) {
        updateNumberFormatter()
        timeLabel.text = data.createdAt?.formatDateWithInputAndOutputType(inputFormat: TypeFormatDate.ServerFormat.rawValue, outputFormat: TypeFormatDate.DD_MM_YYYY_HH_mm.rawValue)
        nameInventoryLabel.attributedText = setAtribute(message1: data.getPerson(), message2: data.createdBy ?? "", message3: "", textColor1: UIColor(named: R.color.textDefault.name)!, textColor2: UIColor(named: R.color.textDefault.name)!, textColor3: UIColor(named: R.color.textDefault.name)!)
        let newTotal = numberFormatter.string(from: NSNumber(value: Double("\(data.changeLogModel?.newQuantity ?? 0)") ?? 0))
        let oldTotal = numberFormatter.string(from: NSNumber(value: Double("\(data.changeLogModel?.oldQuantity ?? 0)") ?? 0))
        if (data.changeLogModel?.newQuantity == 0 || data.changeLogModel?.newQuantity == nil) && (data.changeLogModel?.oldQuantity == 0 || data.changeLogModel?.oldQuantity == nil) || data.changeLogModel?.newQuantity == data.changeLogModel?.oldQuantity {
            totalInventoryLabel.isHidden = true
        } else if data.changeLogModel?.oldQuantity == 0 || data.changeLogModel?.oldQuantity == nil {
            totalInventoryLabel.isHidden = false
            totalInventoryLabel.attributedText = setAtribute(message1: "Nhập tổng SL: ".localized(), message2: newTotal ?? "", message3: "", textColor1: UIColor(named: R.color.textDefault.name)!, textColor2: UIColor(named: R.color.buttonBlue.name)!, textColor3: UIColor(named: R.color.buttonBlue.name)!)
        } else if  data.changeLogModel?.oldQuantity != data.changeLogModel?.newQuantity {
            totalInventoryLabel.isHidden = false
            totalInventoryLabel.attributedText = setAtribute(message1: "Cập nhật tổng SL: ".localized(), message2: "\(oldTotal ?? "") -> \(newTotal ?? "")", message3: "", textColor1: UIColor(named: R.color.textDefault.name)!, textColor2: UIColor(named: R.color.buttonBlue.name)!, textColor3: UIColor(named: R.color.buttonBlue.name)!)
        } else {
            totalInventoryLabel.isHidden = true
        }
        if data.changeLogModel?.oldStatus != data.changeLogModel?.newStatus {
            statusLabel.isHidden = false
            statusLabel.attributedText = setAtribute(message1: "Cập nhật trạng thái: ".localized(), message2: data.changeLogModel?.getNewStatus() ?? "", message3: "", textColor1: UIColor(named: R.color.textDefault.name)!, textColor2: UIColor(named: data.changeLogModel?.getColorNewStatus() ?? "")!, textColor3: UIColor(named: R.color.textDefault.name)!)
        } else {
            statusLabel.isHidden = true
        }
        if data.changeLogModel?.isChangeCDetail ?? false {
            updateDetailLabel.isHidden = false
            updateDetailLabel.attributedText = setAtribute(message1: "Cập nhật: ".localized(), message2: "Số lượng trong Bảng chi tiết".localized(), message3: "", textColor1: UIColor(named: R.color.textDefault.name)!, textColor2: UIColor(named: R.color.textDarkBlue.name)!, textColor3: UIColor(named: R.color.textDefault.name)!)
        } else {
            updateDetailLabel.isHidden = true
        }
        
        if (data.changeLogModel?.oldQuantity == data.changeLogModel?.newQuantity) && (data.changeLogModel?.oldStatus == data.changeLogModel?.newStatus) && data.changeLogModel?.isChangeCDetail == false {
            updateDetailTicketLabel.isHidden = false
            updateDetailTicketLabel.attributedText = setAtribute(message1: "Cập nhật dữ liệu chi tiết phiếu".localized(), message2: "", message3: "", textColor1: UIColor(named: R.color.textDefault.name)!, textColor2: UIColor(named: data.getColorStatus())!, textColor3: UIColor(named: R.color.textDefault.name)!)
        } else {
            updateDetailTicketLabel.isHidden = true
        }
        
    }
        
    func fillDataHistoryDetail(resultDataHistory: ResultDataHistory) {
        statusLabel.isHidden = false
        updateDetailLabel.isHidden = false
        updateDetailTicketLabel.isHidden = false
        noteLabel.isHidden = true
        
        updateNumberFormatter()
        icRight.isHidden = true
        if let comment = resultDataHistory.comment, !comment.isEmpty {
            noteLabel.isHidden = false
            noteLabel.attributedText = setAtribute(message1: "Ghi chú: ", message2: resultDataHistory.comment ?? "", message3: "", textColor1: UIColor(named: R.color.textDefault.name)!, textColor2: UIColor(named: R.color.textDefault.name)!, textColor3: UIColor(named: R.color.textDefault.name)!)
        }
        timeLabel.attributedText = setAtribute(message1: "Thời gian cập nhật: ".localized(), message2: resultDataHistory.createdAt?.formatDateWithInputAndOutputType(inputFormat: TypeFormatDate.ServerFormat.rawValue, outputFormat: TypeFormatDate.DD_MM_YYYY_HH_mm.rawValue) ?? "", message3: "", textColor1: UIColor(named: R.color.textDefault.name)!, textColor2: UIColor(named: R.color.textDefault.name)!, textColor3: UIColor(named: R.color.buttonBlue.name)!)
        nameInventoryLabel.attributedText = setAtribute(message1: resultDataHistory.getPersonHistory(), message2: resultDataHistory.createdBy ?? "", message3: "", textColor1: UIColor(named: R.color.textDefault.name)!, textColor2: UIColor(named: R.color.textDefault.name)!, textColor3: UIColor(named: R.color.textDefault.name)!)
        
        let newTotal = numberFormatter.string(from: NSNumber(value: Double("\(resultDataHistory.changeLogModel?.newQuantity ?? 0)") ?? 0))
        let oldTotal = numberFormatter.string(from: NSNumber(value: Double("\(resultDataHistory.changeLogModel?.oldQuantity ?? 0)") ?? 0))
        
        if (resultDataHistory.changeLogModel?.newQuantity == 0 || resultDataHistory.changeLogModel?.newQuantity == nil) && (resultDataHistory.changeLogModel?.oldQuantity == 0 || resultDataHistory.changeLogModel?.oldQuantity == nil) || resultDataHistory.changeLogModel?.newQuantity == resultDataHistory.changeLogModel?.oldQuantity {
            totalInventoryLabel.isHidden = true
        } else if resultDataHistory.changeLogModel?.oldQuantity == 0 || resultDataHistory.changeLogModel?.oldQuantity == nil {
            totalInventoryLabel.attributedText = setAtribute(message1: "Nhập tổng SL: ".localized(), message2: newTotal ?? "", message3: "", textColor1: UIColor(named: R.color.textDefault.name)!, textColor2: UIColor(named: R.color.buttonBlue.name)!, textColor3: UIColor(named: R.color.buttonBlue.name)!)
        } else if  resultDataHistory.changeLogModel?.oldQuantity != resultDataHistory.changeLogModel?.newQuantity {
            totalInventoryLabel.attributedText = setAtribute(message1: "Cập nhật tổng SL: ".localized(), message2: "\(oldTotal ?? "") -> \(newTotal ?? "")", message3: "", textColor1: UIColor(named: R.color.textDefault.name)!, textColor2: UIColor(named: R.color.buttonBlue.name)!, textColor3: UIColor(named: R.color.buttonBlue.name)!)
        }
        
        if resultDataHistory.changeLogModel?.oldStatus != resultDataHistory.changeLogModel?.newStatus {
            statusLabel.attributedText = setAtribute(message1: "Cập nhật trạng thái: ".localized(), message2: resultDataHistory.changeLogModel?.getNewStatus() ?? "", message3: "", textColor1: UIColor(named: R.color.textDefault.name)!, textColor2: UIColor(named: resultDataHistory.changeLogModel?.getColorNewStatus() ?? "")!, textColor3: UIColor(named: R.color.textDefault.name)!)
        } else {
            statusLabel.isHidden = true
        }
        
        if resultDataHistory.changeLogModel?.isChangeCDetail ?? false {
            updateDetailLabel.attributedText = setAtribute(message1: "Cập nhật: ".localized(), message2: "Số lượng trong Bảng chi tiết".localized(), message3: "", textColor1: UIColor(named: R.color.textDefault.name)!, textColor2: UIColor(named: R.color.textDarkBlue.name)!, textColor3: UIColor(named: R.color.textDefault.name)!)
        } else {
            updateDetailLabel.isHidden = true
        }
        
        if (resultDataHistory.changeLogModel?.oldQuantity == resultDataHistory.changeLogModel?.newQuantity) && (resultDataHistory.changeLogModel?.oldStatus == resultDataHistory.changeLogModel?.newStatus) && resultDataHistory.changeLogModel?.isChangeCDetail == false {
            updateDetailTicketLabel.attributedText = setAtribute(message1: "Cập nhật dữ liệu chi tiết phiếu".localized(), message2: "", message3: "", textColor1: UIColor(named: R.color.textDefault.name)!, textColor2: UIColor(named: resultDataHistory.getColorStatus())!, textColor3: UIColor(named: R.color.textDefault.name)!)
        } else {
            updateDetailTicketLabel.isHidden = true
        }
    }
    
    func setAtribute(message1: String, message2: String, message3: String, textColor1: UIColor, textColor2: UIColor, textColor3: UIColor)  -> NSAttributedString {
        
        let attributedText = NSMutableAttributedString()
        let str1 = message1
        let str2 = message2
        let str3 = message3
        let attr1 = [NSAttributedString.Key.foregroundColor: textColor1, NSAttributedString.Key.font: fontUtils.size14.regular]
        let attr2 = [NSAttributedString.Key.foregroundColor: textColor2, NSAttributedString.Key.font: fontUtils.size14.medium]
        let attr3 = [NSAttributedString.Key.foregroundColor: textColor3, NSAttributedString.Key.font: fontUtils.size14.medium]
        attributedText.append(NSAttributedString(string: str1, attributes: attr1 as [NSAttributedString.Key : Any]))
        attributedText.append(NSAttributedString(string: str2, attributes: attr2 as [NSAttributedString.Key : Any]))
        attributedText.append(NSAttributedString(string: str3, attributes: attr3 as [NSAttributedString.Key : Any]))
        
        return attributedText
    }
}
