//
//  ImageViewCell.swift
//  BIVN
//
//  Created by Tinhvan on 23/11/2023.
//

import UIKit
import Kingfisher
import Localize_Swift

class ImageViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageContent: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    var deleteAction: (() -> ())?
    var urlLink: URL?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = fontUtils.size16.bold
        titleLabel.text = "Ảnh kiểm kê".localized()
    }

    func setDataToCell(data: UIImage) {
        deleteButton.setTitle("", for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteTap), for: .touchUpInside)
        imageContent.image = data
    }
    
    func fillDataHistoryDetail(url: String) {
        deleteButton.isHidden = true
        let ssid = UserDefaults.standard.string(forKey: "nameWifi")
        if Environment.rootURL.description.contains("tinhvan") {
            urlLink = Environment.rootURL
        } else {
                if ssid == "bivnioswifim01" {
                    urlLink = URL(string: "http://172.26.248.30/gateway_inv")
                } else if ssid == "B-WINS" {
                    urlLink = Environment.rootURL
                } else {
                    urlLink = Environment.rootURL
                }
        }
        if let urlLink = urlLink, let url = URL(string: "\(urlLink)/\(url)") {
            imageContent.kf.setImage(with: url, placeholder: UIImage(named: R.image.ic_avatar.name))
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageContent.image = nil
    }
    
    @objc private func deleteTap() {
        self.deleteAction?()
    }
    
}
