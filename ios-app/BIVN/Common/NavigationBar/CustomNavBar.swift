//
//  CustomNavBar.swift
//  BIVN
//
//  Created by Tinhvan on 12/09/2023.
//

import UIKit

protocol NavigationBarProtocol {
    func menuButtonAction()
    func dropDownAction()
}

class CustomNavBar: UIView {
    @IBOutlet weak var bgView: UIView!
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var notificationButton: UIButton!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var codeNameLabel: UILabel!
    @IBOutlet weak var storageLabel: UILabel!
    @IBOutlet weak var codeStorageLabel: UILabel!
    @IBOutlet weak var codeStorageView: UIView!
    @IBOutlet weak var typeRoleLabel: UILabel!
    @IBOutlet weak var viewNameUser: UIView!
    @IBOutlet weak var viewLayoutPosition: UIView!
    
    var type: TypeRole?
    var menuAction: (() -> ())?
    var delegate: NavigationBarProtocol?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    private func initView() {
        Bundle.main.loadNibNamed("CustomNavBar", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [ .flexibleHeight, .flexibleWidth]
        contentView.backgroundColor = UIColor(named: R.color.white.name)
        
        setupView()
    }
    
    func setupView() {
        notificationButton.isHidden = true
        bgView.backgroundColor = UIColor.white
        userNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        codeNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        storageLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        codeStorageLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        
        menuButton.setTitle("", for: .normal)
        notificationButton.setTitle("", for: .normal)
        
        userNameLabel.textColor = UIColor(named: R.color.textDefault.name)
        userNameLabel.text = "\(UserDefault.shared.getDataLoginModel().fullName ?? "")"
        codeNameLabel.textColor = UIColor(named: R.color.textGray.name)
        codeNameLabel.text = "(\(UserDefault.shared.getDataLoginModel().userCode ?? ""))"
        storageLabel.textColor = UIColor(named: R.color.textDefault.name)
        storageLabel.text = "- Khu vực:"
        codeStorageLabel.textColor = UIColor(named: R.color.textGray.name)
        codeStorageLabel.text = "..."
        codeStorageView.layer.borderWidth = 1
        codeStorageView.layer.borderColor = UIColor(named: R.color.lineColor.name)?.cgColor
        
        menuButton.addTarget(self, action: #selector(menuButtonAction), for: .touchUpInside)
        codeStorageView.addTapGestureRecognizer {
            self.delegate?.dropDownAction()
        }
        typeRoleLabel.text = type == .mc ? "MC" : "PCB"
        setupForInventoryAndMentor()
    }
    
    @objc private func menuButtonAction() {
        //self.menuAction?()
        delegate?.menuButtonAction()
    }
    
    
    private func setupForInventoryAndMentor(){
        if type == .inventory || type == .monitor {
            codeNameLabel.isHidden = true
            storageLabel.isHidden = true
            codeStorageView.isHidden = true
            typeRoleLabel.text = UserDefault.shared.getUserID()
        }
    }
    
}

