//
//  HomeTableViewCell.swift
//  BIVN
//
//  Created by Tan Tran on 14/09/2023.
//

import UIKit

class HomePCBTableViewCell: UITableViewCell {
    @IBOutlet weak var avatarMC: UIImageView!
    @IBOutlet weak var titleMCLabel: UILabel!
    @IBOutlet weak var contentMCLabel: UILabel!
    @IBOutlet weak var arrowImageMC: UIImageView!
    
    @IBOutlet weak var avatarPCB: UIImageView!
    @IBOutlet weak var titlePCBLabel: UILabel!
    @IBOutlet weak var contentPCBLabel: UILabel!
    @IBOutlet weak var arrowImagePCB: UIImageView!
    @IBOutlet weak var pcbView: UIView!
    @IBOutlet weak var mcView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fillData(typeRole: TypeRole?, titleMC: String?, titlePCB: String?) {
        if typeRole == .mc {
            pcbView.isHidden = true
            avatarMC.image = UIImage(named: R.image.ic_home_warehouse.name)
            arrowImageMC.image = UIImage(named: R.image.ic_arrow_right.name)
            titleMCLabel.text = "Xuất kho"
            contentMCLabel.text = "Thực quét mã linh kiện và nhập số lượng xuất kho."
        } else {
            pcbView.isHidden = false
            avatarMC.image = UIImage(named: R.image.ic_home_warehouse.name)
            arrowImageMC.image = UIImage(named: R.image.ic_arrow_right.name)
            titleMCLabel.text = titleMC ?? ""
            contentMCLabel.text = "Thực quét mã linh kiện và nhập số lượng xuất kho."
            
            avatarPCB.image = UIImage(named: R.image.ic_home_warehouse.name)
            arrowImagePCB.image = UIImage(named: R.image.ic_arrow_right.name)
            titlePCBLabel.text = titlePCB ?? ""
            contentPCBLabel.text = "Thực quét mã linh kiện và nhập số lượng nhập kho."
        }
    }
}
