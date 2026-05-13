//
//  HomeTableViewCell.swift
//  BIVN
//
//  Created by Luyện Đào on 14/09/2023.
//

import UIKit

class HomeTableViewCell: UITableViewCell {
    @IBOutlet weak var avatarMC: UIImageView!
    @IBOutlet weak var titleMCLabel: UILabel!
    @IBOutlet weak var contentMCLabel: UILabel!
    @IBOutlet weak var arrowImageMC: UIImageView!
    @IBOutlet weak var mcView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        mcView.backgroundColor = UIColor(named: R.color.white.name)
        contentMCLabel.textColor = UIColor(named: R.color.textDefault.name)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fillData(title: String?, content: String?, avatarName: String? = R.image.ic_home_warehouse.name) {
        avatarMC.image = UIImage(named: avatarName ?? "")
            arrowImageMC.image = UIImage(named: R.image.ic_arrow_right.name)
        titleMCLabel.text = title
        contentMCLabel.text = content
    }
}
