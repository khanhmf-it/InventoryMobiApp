//
//  HistoryTicketCell.swift
//  BIVN
//
//  Created by TVO_M1 on 15/1/25.
//

import UIKit

class HistoryTicketCell: UITableViewCell {
    @IBOutlet weak var lblItem: UILabel!
    @IBOutlet weak var lblValueItem: UILabel!
    @IBOutlet weak var lblItemName: UILabel!
    @IBOutlet weak var lblIValueItemName: UILabel!
    @IBOutlet weak var lblPosition: UILabel!
    @IBOutlet weak var lblValuePosition: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func fillData(itemCode: String, itemName: String, position: String, item: String){
        lblIValueItemName.text = item
        lblValueItem.text = itemCode
        lblItemName.text = itemName
        lblValuePosition.text = position
        
        lblItem.text = "Mã linh kiện:".localized()
        lblItemName.text = "Tên linh kiện:".localized()
        lblPosition.text = "Vị trí:".localized()
    }
}
