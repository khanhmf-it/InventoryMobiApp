//
//  HistoryController.swift
//  BIVN
//
//  Created by TVO_M1 on 14/1/25.
//

import Foundation
import UIKit
import Moya

enum EnumTypeSection {
    case historyTicketCell
    case historyTableItemCell
    static let all = [historyTicketCell, historyTableItemCell]
}

class HistoryController : BaseViewController, UITableViewDelegate, UITableViewDataSource {


    @IBOutlet weak var tableView: UITableView! {
        didSet{
            tableView.register(R.nib.historyItemTableViewCell)
            tableView.register(R.nib.historyTicketCell)
        }
    }
    @IBOutlet weak var lblEmpty: UILabel!
    var resultModel: ResultErrorModel?
    let netWorkManager: NetworkManager = NetworkManager()
    var historyData: [HistoryData]?
 
    override func viewDidLoad() {
        setupUI()
    }
    
    func setupUI() {
        lblEmpty.isHidden = true
        lblEmpty.text = "Không có dữ liệu".localized()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        self.navigationItem.title = "Lịch sử điều tra".localized()
        self.navigationItem.setHidesBackButton(true, animated: true)
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: #selector(onTapBack))
        self.navigationItem.leftBarButtonItem = buttonLeft
    }
    
    @objc func onTapBack(){
        self.navigationController?.popViewController(animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return EnumTypeSection.all.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch EnumTypeSection.all[section] {
        case .historyTicketCell:
            return 1
        case .historyTableItemCell:
            return historyData?.count ?? 0
            
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch EnumTypeSection.all[indexPath.section] {
        case .historyTicketCell:
            guard let cellInfo = tableView.dequeueReusableCell(withIdentifier: R.nib.historyTicketCell, for: indexPath) else {return UITableViewCell()}
            cellInfo.fillData(itemCode: resultModel?.componentCode ?? "", itemName: resultModel?.componentName ?? "", position: resultModel?.positionCode ?? "", item: resultModel?.componentName ?? "")
            return cellInfo
        case .historyTableItemCell:
            let itemData = historyData?[indexPath.row]
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.historyItemTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.fillData(historyData: itemData)
            return cell
        }
    }
}
