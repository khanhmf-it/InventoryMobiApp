//
//  InfoTicketTableViewCell.swift
//  BIVN
//
//  Created by Tan Tran on 27/12/2023.
//

import UIKit
import Localize_Swift

protocol AddRowCell: AnyObject {
    func addRowCell()
}

class InfoTicketTableViewCell: BaseTableViewCell {
    @IBOutlet weak var titleTicketNameLabel: UILabel!
    @IBOutlet weak var titleStatusLabel: UILabel!
    @IBOutlet weak var titleSalesOrderLabel: UILabel!
    @IBOutlet weak var titleNoteLabel: UILabel!
    @IBOutlet weak var titleLocationLabel: UILabel!
    @IBOutlet weak var titleNameLabel: UILabel!
    
    @IBOutlet weak var ticketNameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var salesOrderLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var saleOrderStackView: UIStackView!
    @IBOutlet weak var noteStackView: UIStackView!
    
    @IBOutlet weak var loacationStackView: UIStackView!
    @IBOutlet weak var ticketStackView: UIStackView!
    
    @IBOutlet weak var scanQrButton: UIButton!
    @IBOutlet weak var addRowButton: UIButton!
    @IBOutlet weak var stackAddButton: UIStackView!
    
    weak var delegateAddRow: AddRowCell?
    var onTapQR: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setupUI() {
        ticketNameLabel.font = fontUtils.size14.regular
        statusLabel.font = fontUtils.size14.regular
        salesOrderLabel.font = fontUtils.size14.regular
        noteLabel.font = fontUtils.size14.regular
        noteLabel.textColor = UIColor(named: R.color.textRed.name)
    }
    
    func setupTitle() {
        titleTicketNameLabel.text = "Tên phiếu:".localized()
        titleStatusLabel.text = "Trạng thái:".localized()
        titleSalesOrderLabel.text = "Sales order:".localized()
        titleNoteLabel.text = "Lưu ý:".localized()
        addRowButton.setTitle("+ Thêm dòng".localized(), for: .normal)
    }
    
    func fillData(model: ResultData?) {
        setupUI()
        setupTitle()
        scanQrButton.isHidden = true
        loacationStackView.isHidden = true
        ticketStackView.isHidden = true
        ticketNameLabel.text = "\(model?.machineModel ?? "") - \(model?.machineType ?? "") - \(model?.lineName ?? "") - \(model?.stageName ?? "")"
        statusLabel.text = model?.getStatusPartCode()
        statusLabel.textColor = UIColor(named: model?.getColorStatus() ?? "")
        
        if let saleOrder = model?.salesOrder, saleOrder != "" {
            saleOrderStackView.isHidden = false
            salesOrderLabel.text = saleOrder
        } else {
            saleOrderStackView.isHidden = true
        }
        if let note  = model?.note, note != "" {
            noteStackView.isHidden = false
            noteLabel.text = note
        } else {
            noteStackView.isHidden = true
        }
    }
    
    @IBAction func onTapAddRow(_ sender: UIButton) {
        delegateAddRow?.addRowCell()
    }
    
    @IBAction func onTapQRCode(_ sender: Any) {
        self.onTapQR?()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setupUIMonitor() {
        ticketNameLabel.font = fontUtils.size24.bold
        ticketNameLabel.textColor = UIColor(named: R.color.buttonBlue.name)!
        statusLabel.font = fontUtils.size14.regular
        salesOrderLabel.font = fontUtils.size14.regular
        noteLabel.font = fontUtils.size14.regular
        locationLabel.font = fontUtils.size14.regular
        nameLabel.font = fontUtils.size14.regular
        nameLabel.textColor = UIColor(named: R.color.textRed.name)!
        addRowButton.titleLabel?.font = fontUtils.size16.medium
        addRowButton.setTitle("+ Thêm dòng".localized(), for: .normal)
    }
    
    func fillDataMonitor(model: ResultData?) {
        setupUIMonitor()
        scanQrButton.isHidden = true
        addRowButton.isHidden = model?.status == 6
        addRowButton.setTitle("+ Thêm dòng".localized(), for: .normal)
        titleTicketNameLabel.text = "Mã linh kiện:".localized()
        titleStatusLabel.text = "Tên linh kiện:".localized()
        titleSalesOrderLabel.text = "Vị trí:".localized()
        titleNoteLabel.text = "Trạng thái:".localized()
        titleLocationLabel.text = "Sales order:".localized()
        titleNameLabel.text = "Lưu ý:".localized()
        ticketNameLabel.text = model?.componentCode
        statusLabel.text = model?.componentName
        salesOrderLabel.text = model?.positionCode
        noteLabel.text = model?.getStatusPartCode()
        noteLabel.textColor = UIColor(named: model?.getColorStatus() ?? "")
        locationLabel.text = model?.salesOrder
        nameLabel.text = model?.note
        
        loacationStackView.isHidden = model?.salesOrder?.isEmpty ?? true
        ticketStackView.isHidden = model?.note?.isEmpty ?? true
    }
    
    func setDataToCell(model: InventoryDoc?, isConfirmScan: Bool) {
        setupUIMonitor()
        scanQrButton.isHidden = isConfirmScan
        addRowButton.isHidden = model?.status == 6
        addRowButton.setTitle("+ Thêm dòng".localized(), for: .normal)
        titleTicketNameLabel.text = "Mã linh kiện:".localized()
        titleStatusLabel.text = "Tên linh kiện:".localized()
        titleSalesOrderLabel.text = "Vị trí:".localized()
        titleNoteLabel.text = "Trạng thái:".localized()
        titleLocationLabel.text = "Sales order:".localized()
        titleNameLabel.text = "Lưu ý:".localized()
        ticketNameLabel.text = model?.componentCode
        statusLabel.text = model?.componentName
        salesOrderLabel.text = model?.positionCode
        noteLabel.text = model?.getColorStatusPartCode()
        noteLabel.textColor = UIColor(named: model?.getColorStatus() ?? "")
        locationLabel.text = model?.saleOrderNo
        nameLabel.text = model?.note
        
        loacationStackView.isHidden = model?.saleOrderNo?.isEmpty ?? true
        ticketStackView.isHidden = model?.note?.isEmpty ?? true
    }
}
