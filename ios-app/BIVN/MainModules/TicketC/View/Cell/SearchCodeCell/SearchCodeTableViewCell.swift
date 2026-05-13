//
//  SearchCodeTableViewCell.swift
//  BIVN
//
//  Created by Luyện Đào on 22/11/2023.
//

import UIKit
import Localize_Swift

class SearchCodeTableViewCell: UITableViewCell {
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    
    var onTapSearch: ((_ text: String?) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = "Chi tiết".localized()
        let imageIcon = UIImageView()
        imageIcon.image = UIImage(named: R.image.ic_search.name)
        let contentView = UIView()
        contentView.addSubview(imageIcon)
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: UIImage(named: R.image.ic_search.name)?.size.width ?? 0, height: UIImage(named: R.image.ic_search.name)?.size.height ?? 0))
        contentView.addSubview(button)
        contentView.frame = CGRect(x: 0, y: 0, width: UIImage(named: R.image.ic_search.name)?.size.width ?? 0, height: UIImage(named: R.image.ic_search.name)?.size.height ?? 0)
        imageIcon.frame = CGRect(x: -10, y: 0, width: UIImage(named: R.image.ic_search.name)?.size.width ?? 0, height: UIImage(named: R.image.ic_search.name)?.size.height ?? 0)
        searchTextField.rightView = contentView
        searchTextField.rightViewMode = .always
        searchTextField.clearButtonMode = .whileEditing
        button.setTitle("", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
    }
    
    @objc func buttonAction(sender: UIButton!) {
        onTapSearch?(searchTextField.text)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
