//
//  ListAccessoryNotInventoryABECell.swift
//  BIVN
//
//  Created by TinhVan Software on 09/05/2024.
//

import UIKit

class ListAccessoryNotInventoryABECell: UITableViewCell {

    @IBOutlet weak var borderView: UIView!
    @IBOutlet weak var accessoryCodeLabel: UILabel!
    @IBOutlet weak var accessoryLocationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderView.layer.borderWidth = 1
        borderView.layer.cornerRadius = 8
        borderView.layer.borderColor = UIColor(named: R.color.lineColor.name)?.cgColor
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fillDataDocB(model: DocBInfoModels) {
        accessoryCodeLabel.text = model.componentCode
        accessoryLocationLabel.text = model.positionCode
    }
    
    func fillDataDocAE(model: DocAEInfoModels) {
        accessoryCodeLabel.text = model.componentCode
        accessoryLocationLabel.text = model.positionCode
    }
}
