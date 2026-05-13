//
//  ListErrorTableViewCell.swift
//  BIVN
//
//  Created by Bi on 7/1/25.
//

import UIKit
import Localize_Swift
import SwiftUICore

class ListErrorTableViewCell: UITableViewCell {
    @IBOutlet weak var partNumberLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    @IBOutlet weak var partNumberValueLabel: UILabel!
    @IBOutlet weak var quantityValueLabel: UILabel!
    @IBOutlet weak var moneyValueLabel: UILabel!
    @IBOutlet weak var statusValueLabel: UILabel!
    @IBOutlet weak var locationValueLabel: UILabel!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var arowImage: UIImageView!
    @IBOutlet weak var contentViewtotal: UIView!
    
    var onClickHistory: ((ResultErrorModel?) -> ())?
    var resultErrorModel: ResultErrorModel?
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    func setupUI() {
        detailButton.isHidden = true
        arowImage.isHidden = true
        detailButton.layer.cornerRadius = 4
        detailButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        detailButton.clipsToBounds = true
        partNumberValueLabel.font = fontUtils.size14.medium
        quantityValueLabel.font = fontUtils.size14.bold
        moneyValueLabel.font = fontUtils.size14.medium
        statusValueLabel.font = fontUtils.size14.medium
        locationValueLabel.font = fontUtils.size14.medium
        //locationLabel.text = "Giá trị".localized()
        detailButton.setTitle("Xem lịch sử".localized(), for: .normal)
        detailButton.titleLabel?.font = fontUtils.size9.medium

//        partNumberLabel.text = "Mã linh kiện".localized()
//        locationLabel.text = "Vị trí".localized()
//        statusLabel.text = "Trạng thái".localized()
//        quantityLabel.text = "Số lượng".localized()
//        valueLabel.text = "Giá trị".localized()
        partNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            partNumberLabel.widthAnchor.constraint(equalToConstant: 100),
        ])

    }
    
    func hidenButton(){
        detailButton.isHidden = true
        arowImage.isHidden = true
    }
    
    func fillData(listErrorModel: ResultErrorModel?) {
        resultErrorModel = listErrorModel
        detailButton.isHidden = false
        arowImage.isHidden = false
        partNumberValueLabel.text = listErrorModel?.componentCode!.uppercased(with: .autoupdatingCurrent) ?? ""
        if let status = StatusDisplayError(rawValue: Int(listErrorModel?.status ?? 0)) {
            statusValueLabel.text = status.displayName
            statusValueLabel.textColor = status.color
            contentViewtotal.backgroundColor = status.colorBacground
        }
        moneyValueLabel.text = "\(formatStringNumberWithCommas(listErrorModel?.errorMoneyAbs ?? "0.0"))$"
        let number = CustomDouble(value: Double(listErrorModel?.quantity ?? "") ?? 0)
        quantityValueLabel.text = formatStringNumberWithCommas(number.formattedValue)
        if let quantityString = listErrorModel?.quantity, let quantity = Double(quantityString) {
            quantityValueLabel.textColor = quantity < 0 ?
                UIColor(named: R.color.textRed.name) :
                UIColor(named: R.color.buttonBlue.name)
        } else {
            quantityValueLabel.textColor = UIColor.gray
        }
        locationValueLabel.text = listErrorModel?.positionCode ?? ""
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    @IBAction func onclickHistory(_ sender: Any) {
        self.onClickHistory?(resultErrorModel)
    }
}
