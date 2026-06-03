//
//  TestTableViewCell.swift
//  BIVN
//
//  Created by TVO_M1 on 15/1/25.
//

import UIKit

class HistoryItemTableViewCell: UITableViewCell {

    @IBOutlet weak var lblEdit: UILabel!
    @IBOutlet weak var lblType: UILabel!
    @IBOutlet weak var lblDetailEdit: UILabel!
    @IBOutlet weak var lblAuthor: UILabel!
    @IBOutlet weak var lblTimeEdit: UILabel!
    @IBOutlet weak var lblTimeConfirm: UILabel!
    @IBOutlet weak var lblImage: UILabel!
    @IBOutlet weak var imgFirst: UIImageView!
    @IBOutlet weak var imgSecond: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
    
    }

    func fillData(historyData: HistoryData?){
        let lableEdit = "\("Điều chỉnh lần".localized()) \(String(historyData?.index ?? 0)): \("Từ".localized())"
        let eidtValue = "\(String(formatStringNumberWithCommas(historyData?.oldValue ?? ""))) => \(formatStringNumberWithCommas(historyData?.newValue ?? ""))"
        lblEdit.attributedText = buildItemView(lable: lableEdit, value: eidtValue)
        lblType.attributedText = buildItemView(lable: "\("Phân loại:".localized())", value: historyData?.errorCategoryName ?? "")
        lblDetailEdit.attributedText = buildItemView(lable: "\("Chi tiết điều tra:".localized())", value: historyData?.errorDetail ?? "")
        lblAuthor.attributedText = buildItemView(lable: "\("Người điều tra:".localized())", value: historyData?.investigator ?? "")
        lblTimeEdit.attributedText = buildItemView(lable:  "\("Thời điểm điều tra:".localized())", value: historyData?.investigationTime ?? "")
        lblTimeConfirm.attributedText = buildItemView(lable: "\("Thời điểm xác nhận:".localized())", value: historyData?.confirmInvestigationTime ?? "")
        lblImage.attributedText = buildItemView(lable: "\("Hình ảnh:".localized())", value: "")
        
        imgFirst.kf.setImage(with: combineURLImage(path: historyData?.confirmationImage1 ?? ""), placeholder: UIImage(named: R.image.ic_avatar.name))
        imgSecond.kf.setImage(with: combineURLImage(path: historyData?.confirmationImage2 ?? "" ), placeholder: UIImage(named: R.image.ic_avatar.name))
        
    }
    
    func buildItemView(lable: String, value: String) -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: "\(lable) \(value)")
        let buildLableRange = ("\(lable) \(value)" as NSString).range(of: lable)
        
        attributedString.addAttribute(.foregroundColor, value: UIColor(named: R.color.textDefault.name) ?? 0, range: buildLableRange)
        attributedString.addAttribute(.font, value: fontUtils.size12.regular, range: buildLableRange)
        
        
        let buildValueRange = ("\(lable) \(value)" as NSString).range(of: value)
        attributedString.addAttribute(.foregroundColor, value: UIColor(named: R.color.textDefault.name) ?? 0, range: buildValueRange)
        attributedString.addAttribute(.font, value: fontUtils.size12.bold, range: buildValueRange)
        
        return attributedString
    }
    
    func combineURLImage(path: String) -> URL? {
        if let absoluteURL = URL(string: path), absoluteURL.scheme != nil {
            return absoluteURL
        }

        let ssid = UserDefaults.standard.string(forKey: "nameWifi")
        var domain: URL

        if Environment.rootURL.description.contains("tinhvan") {
            domain = Environment.rootURL
        } else if ssid == "bivnioswifim01" {
            domain = URL(string: "http://172.26.248.26/gateway_inv_test")!
        } else {
            domain = Environment.rootURL
        }

        guard var components = URLComponents(url: domain, resolvingAgainstBaseURL: false) else {
            return nil
        }
        let pathEdit = path.replacingOccurrences(of: "\\", with: "/")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if pathEdit.isEmpty {
            return components.url
        }

        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if basePath.isEmpty {
            components.path = "/\(pathEdit)"
        } else {
            components.path = "/\(basePath)/\(pathEdit)"
        }
        return components.url
    }
}
