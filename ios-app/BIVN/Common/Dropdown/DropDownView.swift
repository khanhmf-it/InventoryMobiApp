//
//  DropDownView.swift
//  BIVN
//
//  Created by Tinhvan on 15/09/2023.
//

import UIKit
import Foundation

class CellClass: UITableViewCell {
    
}

class DropDownView: UIView {
    @IBOutlet var contentView: UIView!
    
    let tableView = UITableView()
    let transparentView = UIView()
    var selectedView = UIView()
    
    var arrayData: [DataStorageModel] = []
    var didSelectRow: ((DataStorageModel, Int) -> ())?
    var indexChoose = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    private func initView() {
        Bundle.main.loadNibNamed("DropDownView", owner: self, options: nil)
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        addSubview(contentView)
        
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.register(R.nib.chooseTableViewCell)
        tableView.reloadData()
    }
    
    func addTransparentView(frames: CGRect, viewSelect: UIView, data: [DataStorageModel], indexChoose: Int) {
        self.arrayData = data
        let window = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        
        self.indexChoose = indexChoose
        transparentView.frame = window?.frame ?? self.frame
        self.addSubview(transparentView)
        
        tableView.frame = CGRect(x: frames.origin.x, y: frames.origin.y + frames.height, width: frames.width, height: 0)
        self.addSubview(tableView)
        tableView.layer.cornerRadius = 5
        tableView.reloadData()
        
        UIView.animate(withDuration: 1.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.tableView.frame = CGRect(x: frames.width * 0.1, y: frames.origin.y +  frames.height + 5, width: frames.width * 0.8, height: CGFloat((self.arrayData.count > 10 ? 9 : self.arrayData.count) * 44))
        }, completion: nil)
    }
    
    @objc private func removeTransparentView() {
        let frames = selectedView.frame
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.tableView.frame = CGRect(x: frames.origin.x, y: frames.origin.y + CGFloat((self.arrayData.count > 10 ? 9 : self.arrayData.count) * 44), width: frames.width, height: 0)
        }, completion: nil)
    }
    
}

extension DropDownView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

extension DropDownView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.chooseTableViewCell, for: indexPath) else {return UITableViewCell()}
        cell.setDataToCell(data: arrayData[indexPath.row].layout ?? "", isSelected: indexChoose == indexPath.row ? true : false)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.didSelectRow?(arrayData[indexPath.row], indexPath.row)
        self.tableView.reloadData()
    }
}
