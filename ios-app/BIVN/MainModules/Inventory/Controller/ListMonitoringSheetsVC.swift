//
//  ListMonitoringSheetsVC.swift
//  BIVN
//
//  Created by Tinhvan on 08/11/2023.
//

import UIKit
import Localize_Swift

class ListMonitoringSheetsVC: UIViewController {
    
    @IBOutlet weak var icMenu: UIImageView!
    @IBOutlet weak var inventoryTotalLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var viewBottomSheet: UIView!
    @IBOutlet weak var contentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.tintColor = UIColor.gray
    }
    
    private func setupUI() {
        let backImage = UIImage(named: R.image.ic_back.name)
        self.navigationController?.navigationBar.backIndicatorImage = backImage
        self.navigationItem.setHidesBackButton(true, animated: true)
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: #selector(onTapBack))
        self.navigationItem.leftBarButtonItem = buttonLeft
        self.title = "Danh sách phiếu cần giám sát".localized()
        
        inventoryTotalLabel.attributedText = setAtribute(message1: "Đã giám sát: ".localized(), message2: "10/30 phiếu")
        
        viewBottomSheet.isHidden = true
        contentViewHeight.constant = 350
        contentViewBottomConstraint.constant = -350
        viewBottomSheet.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        icMenu.addTapGestureRecognizer {
            self.showBottom()
        }
        viewBottomSheet.addTapGestureRecognizer {
            self.hideBottom()
        }
        
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.register(R.nib.monitoringSheetsCell)
        tableView.contentInset.bottom = 16
    }
    
    func setAtribute(message1: String, message2: String)  -> NSAttributedString {
        let attributedText = NSMutableAttributedString()
        let str1 = message1
        let str2 = message2
        let attr1 = [NSAttributedString.Key.foregroundColor: UIColor(named: R.color.textDefault.name), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .regular)]
        let attr2 = [NSAttributedString.Key.foregroundColor: UIColor(named: R.color.greenColor.name), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .regular)]
        attributedText.append(NSAttributedString(string: str1, attributes: attr1 as [NSAttributedString.Key : Any]))
        attributedText.append(NSAttributedString(string: str2, attributes: attr2 as [NSAttributedString.Key : Any]))
        
        return attributedText
    }
    
    @objc private func onTapBack() {
        navigationController?.popViewController(animated: true)
    }
    
    private func showBottom() {
        viewBottomSheet.isHidden = false
        UIView.animate(withDuration: 0.6) {
            self.viewBottomSheet.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            self.contentViewBottomConstraint.constant = 0
            self.viewBottomSheet.layoutIfNeeded()
        }
    }
    
    private func hideBottom() {
        UIView.animate(withDuration: 0.6) {
            self.viewBottomSheet.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            self.contentViewBottomConstraint.constant = -350
            self.viewBottomSheet.layoutIfNeeded()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 ) {
            self.viewBottomSheet.isHidden = true
        }
    }
    
}

extension ListMonitoringSheetsVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 9
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.monitoringSheetsCell, for: indexPath) else {return UITableViewCell()}
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(withIdentifier: R.storyboard.main.inventorySheetVC)
        navigationController?.pushViewController(vc!, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
}
