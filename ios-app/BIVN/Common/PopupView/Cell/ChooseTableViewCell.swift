//
//  ChooseTableViewCell.swift
//  BIVN
//
//  Created by tinhvan on 18/09/2023.
//

import UIKit

class ChooseTableViewCell: UITableViewCell {
    @IBOutlet weak var imgChoice: UIImageView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentLabel.numberOfLines = 0
        statusLabel.isHidden = true
    }
    
    func setDataToCell(data: String, status: Int = -1, isSelected: Bool = false) {
        contentLabel.attributedText = setAtribute(message1: "\(data) ", message2: getStatusPartCode(status: status) , textColor1: UIColor(named: R.color.textDefault.name) ?? UIColor.black, textColor2: UIColor(named: getColorStatus(status: status)) ?? UIColor.black)
        
        imgChoice.image = isSelected ? UIImage(named: "ic_checked") : UIImage(named: "ic_emptyCheckBox")
    }
    
    func isHiddenRadio(data: String) {
        imgChoice.isHidden = true
        contentLabel.text = data
    }
    
    func getColorStatus(status: Int) -> String {
        switch status {
        case 0:
            return R.color.textDarkBlue.name
        case 1:
            return R.color.textDefault.name
        case 2:
            return R.color.textGray.name
        case 3:
            return R.color.textYellow.name
        case 4:
            return R.color.textOrange.name
        case 5:
            return R.color.greenColor.name
        case 6:
            return R.color.textBlue.name
        case 7:
            return R.color.textRed.name
        default:
            return R.color.textDefault.name
        }
    }
    
    func getStatusPartCode(status: Int) -> String {
        switch status {
        case 0:
            return "Chưa tiếp nhận"
        case 1:
            return "Không kiểm kê"
        case 2:
            return "Chưa kiểm kê"
        case 3:
            return "Chờ xác nhận"
        case 4:
            return "Cần chỉnh sửa"
        case 5:
            return "Đã xác nhận"
        case 6:
            return "Đã đạt giám sát"
        case 7:
            return "Không đạt giám sát"
        default:
            return ""
        }
    }
    
    func setAtribute(message1: String, message2: String, textColor1: UIColor, textColor2: UIColor)  -> NSAttributedString {
        
        let attributedText = NSMutableAttributedString()
        let str1 = message1
        let str2 = message2
        let attr1 = [NSAttributedString.Key.foregroundColor: textColor1, NSAttributedString.Key.font: fontUtils.size16.regular]
        let attr2 = [NSAttributedString.Key.foregroundColor: textColor2, NSAttributedString.Key.font: fontUtils.size14.medium]
        attributedText.append(NSAttributedString(string: str1, attributes: attr1 as [NSAttributedString.Key : Any]))
        attributedText.append(NSAttributedString(string: str2, attributes: attr2 as [NSAttributedString.Key : Any]))
        
        return attributedText
    }
}
