//
//  HistoryInventoryDetailViewController.swift
//  BIVN
//
//  Created by tinhvan on 01/12/2023.
//

import UIKit
import Moya

enum HistorInventory: Int {
    case titleInventory = 0
    case rowInventory = 1
    case sumInventory = 2
    case noteInventory = 3
    case historyInventoryDetail = 4
    case imageViewCell = 5
}


class HistoryInventoryDetailViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var componentLabel: UILabel!
    @IBOutlet weak var componentNameLabel: UILabel!
    
    var historyDetailId: String = ""
    var componentCode: String = ""
    var componentName: String = ""
    var createAt: String = ""
    var modelDetal: ResultDataHistory?
    var arrayData: [DocComponentABEs] = []
    var note: String = ""
    var evicenceImg: String?
    private var imageCapture: UIImage?
    private var valueSumTest: Double = 0
    let networkManager: NetworkManager = NetworkManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        callApiHistoryDetail(params: [:])
    }
    
    func setupUI() {
        componentLabel.text = componentCode
        componentNameLabel.text = componentName
        let yourBackImage = UIImage(named: R.image.ic_back.name)
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.tintColor = UIColor.gray
        self.navigationItem.setHidesBackButton(true, animated: true)
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: #selector(onTapNotification))
        self.navigationItem.leftBarButtonItem = buttonLeft
        self.title = createAt
    }
    
    @objc private func onTapNotification(){
        navigationController?.popViewController(animated: true)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(R.nib.titleInventoryCell)
        tableView.register(R.nib.invenTableViewCell)
        tableView.register(R.nib.totalItemTableViewCell)
        tableView.register(R.nib.imageViewCell)
        tableView.register(R.nib.noteCell)
        tableView.register(R.nib.historyDetailTableViewCell)
        tableView.contentInset.bottom = 16
        
    }
    
    private func callApiHistoryDetail(params: Dictionary<String, Any>) {
        self.startLoading()
        networkManager.getHistoryDetail(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", historyId: historyDetailId, param: params, completion: { data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.stopLoading()
                    self.modelDetal = response.data
                    self.arrayData = response.data?.historyOutputs ?? []
                    self.evicenceImg = response.data?.evicenceImg
                    self.note = response.data?.comment ?? ""
                    self.setupTableView()
                    self.setupUI()
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        callApiHistoryDetail(params: [:])
                    }
                } else {
                    self.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
                }
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self.showAlertConfigTimeOut()
                    }
                }
                print(error.localizedDescription)
            }
        })
    }
}

extension HistoryInventoryDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch HistorInventory(rawValue: section) {
        case .rowInventory:
            return arrayData.count
        case .imageViewCell:
            if evicenceImg?.count ?? 0 > 0 {
                return 1
            } else {
                return 0
            }
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch HistorInventory(rawValue: indexPath.section) {
        case .titleInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            return cell
        case .rowInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.invenTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setDataToCellDetailMonitor(data: arrayData[indexPath.row],index: indexPath.row, isLast: (arrayData.count - 1) == indexPath.row ? true : false, isHiddenCheckBox: true, isHideTextField: false)
            var totalValue = 0.0
            for item in self.arrayData {
                let result = item.quantityPerBom ?? 0.0
                let result2 = item.quantityOfBom ?? 0.0
                totalValue = ((result) * (result2)) + totalValue
            }
            self.valueSumTest = totalValue
            return cell
        case .sumInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.totalItemTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setDataToCell(totalValue: valueSumTest)
            
            return cell
        case .noteInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.noteCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.isHiddenAddButton = false
            cell.cellDelegate = self
            cell.setDataForHistory(note: note)
            return cell
        case .historyInventoryDetail:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.historyDetailTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setData(data: self.modelDetal ?? ResultDataHistory())
            return cell
        case .imageViewCell:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.imageViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            if evicenceImg != nil {
                let modifiedString = evicenceImg?.replacingOccurrences(of: "\\", with: "/")
                cell.fillDataHistoryDetail(url: modifiedString ?? "")
            } else {
                cell.setDataToCell(data: self.imageCapture ?? UIImage())
            }
            cell.deleteAction = {
                if self.imageCapture != nil {
                    self.imageCapture = nil
                    self.tableView.reloadData()
                }
            }
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch HistorInventory(rawValue: indexPath.section) {
        case .noteInventory:
            return self.note.isEmpty ? 0 : UITableView.automaticDimension
        case .historyInventoryDetail, .imageViewCell :
            return UITableView.automaticDimension
            
        default:
            return 60
        }
    }
    
}

extension HistoryInventoryDetailViewController: NoteCellProtocol {
    func updateHeightNote(_ cell: NoteCell, _ textView: UITextView) {
        let size = textView.bounds.size
        let newSize = tableView.sizeThatFits(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude))
        if size.height != newSize.height {
            UITableView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            tableView.endUpdates()
            UITableView.setAnimationsEnabled(true)
            if let indexPath = tableView.indexPath(for: cell) {
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
        }
    }
}
