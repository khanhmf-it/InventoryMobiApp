//
//  SideMenuCell.swift
//  BIVN
//
//  Created by Tinhvan on 12/09/2023.
//

import UIKit
import Localize_Swift

class SideMenuCell: UITableViewCell {
    
    class var identifier: String { return String(describing: self) }
    class var nib: UINib { return UINib(nibName: identifier, bundle: nil) }
    
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.iconImageView.tintColor = .white
        self.titleLabel.textColor = .white
        titleLabel.text = "Đăng xuất".localized()
        
    }
    
}
