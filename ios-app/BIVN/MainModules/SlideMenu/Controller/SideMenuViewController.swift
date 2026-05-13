//
//  SideMenuViewController.swift
//  BIVN
//
//  Created by Tinhvan on 12/09/2023.
//

import UIKit
import Kingfisher
import Localize_Swift

protocol SideMenuViewControllerDelegate {
    func selectedCell(_ row: Int)
}

class SideMenuViewController: UIViewController {
    @IBOutlet weak var headerView: UIView!
    @IBOutlet var headerImageView: UIImageView!
    @IBOutlet var sideMenuTableView: UITableView!
    
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userIDLabel: UILabel!
    
    var delegate: SideMenuViewControllerDelegate?
    
    var defaultHighlightedCell: Int = -1
    
    var menu: [SideMenuModel] = []
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menu = [
            SideMenuModel(icon: UIImage(named: R.image.ic_logout.name) ?? UIImage(), title: "Đăng xuất".localized())
        ]
        self.view.backgroundColor = UIColor(named: R.color.white.name)
        avatarImage.cornerRadius()
        if let urlLink = UserDefault.shared.getDataLoginModel().avatar {
            let ssid = UserDefaults.standard.string(forKey: "ssid")
            if Environment.rootURL.description.contains("tinhvan") {
                url = Environment.rootURL
            } else {
                    if ssid == "bivnioswifim01" {
                        url = URL(string: "http://172.26.248.30/gateway_inv")
                    } else if ssid == "B-WINS" {
                        url = Environment.rootURL
                    } else {
                        url = Environment.rootURL
                    }
            }
            if let url = url, let url1 = URL(string: "\(url)/\(urlLink)") {
                avatarImage.kf.setImage(with: url1, placeholder: UIImage(named: R.image.ic_avatar.name))
            }
        }
        userNameLabel.textColor = UIColor(named: R.color.textDefault.name)
        userIDLabel.textColor = UIColor(named: R.color.textGray.name)
        userNameLabel.text = UserDefault.shared.getDataLoginModel().fullName
        let name2 = "Mã nhân viên".localized()
        userIDLabel.text = "\(name2): \(UserDefault.shared.getDataLoginModel().userCode ?? "")"
        
        // TableView
        self.sideMenuTableView.delegate = self
        self.sideMenuTableView.dataSource = self
        self.sideMenuTableView.backgroundColor = .clear
        self.sideMenuTableView.separatorStyle = .none
        
        // Set Highlighted Cell
        DispatchQueue.main.async {
            let defaultRow = IndexPath(row: self.defaultHighlightedCell, section: 0)
            self.sideMenuTableView.selectRow(at: defaultRow, animated: false, scrollPosition: .none)
        }
        
        // Register TableView Cell
        self.sideMenuTableView.register(SideMenuCell.nib, forCellReuseIdentifier: SideMenuCell.identifier)
        
        // Update TableView with the data
        self.sideMenuTableView.reloadData()
    }
    
}

// MARK: - UITableViewDelegate

extension SideMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

// MARK: - UITableViewDataSource

extension SideMenuViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.menu.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SideMenuCell.identifier, for: indexPath) as? SideMenuCell else { fatalError("xib doesn't exist") }
        
        cell.selectionStyle = .none
        cell.iconImageView.image = self.menu[indexPath.row].icon
        cell.titleLabel.textColor = UIColor(named: R.color.textRed.name)
        cell.titleLabel.text = self.menu[indexPath.row].title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.selectedCell(indexPath.row)
    }
}
