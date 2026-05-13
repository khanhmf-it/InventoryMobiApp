//
//  WaitConfirmMonitorViewController.swift
//  BIVN
//
//  Created by tinhvan on 11/12/2023.
//

import UIKit
import Moya
import Localize_Swift

class WaitConfirmMonitorViewController: BaseViewController {
    
    @IBOutlet weak var titlePartCodeLabel: UILabel!
    @IBOutlet weak var titleComponentNameLabel: UILabel!
    @IBOutlet weak var titleLocationLabel: UILabel!
    @IBOutlet weak var titleStatusLabel: UILabel!
    @IBOutlet weak var titleSaleLabel: UILabel!
    @IBOutlet weak var titleNoteLabel: UILabel!
    
    @IBOutlet weak var valuePartCodeLabel: UILabel!
    @IBOutlet weak var valueComponentNameLabel: UILabel!
    @IBOutlet weak var valueLocationLabel: UILabel!
    @IBOutlet weak var valueStatusLabel: UILabel!
    @IBOutlet weak var valueSaleLabel: UILabel!
    @IBOutlet weak var valueNoteLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    let networkManager: NetworkManager = NetworkManager()
    var documentId = ""
    var dataDetail: ResultData?
    var arrayData: [DocComponentABEs] = []
    var arrayHistory: [DocHistory] = []
    var valueSum: Double = 0
    var titleString: String?
    var message: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        callApi()
        setupUI()
        setupTableView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let navigationController = self.navigationController else {return}
            for viewController in navigationController.viewControllers where viewController is ScanCodeMCViewController {
                navigationController.popToViewController(viewController, animated: true)
            }
        }
    }
    
    private func callApi() {
        self.startLoading()
        networkManager.getDetailSheetsMonitor(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", accountId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.accountId ?? "", documentId: self.documentId, actionType: 2) {data in
            switch data {
            case .success(let response):
                if response.code == 200 {
                    self.stopLoading()
                    self.dataDetail = response.data
                    self.title = response.data?.docCode
                    self.arrayHistory = response.data?.docHistories ?? []
                    self.arrayData = response.data?.docComponentABEs ?? []
                    self.tableView.reloadData()
                    self.setupUI()
                    self.showToast()
                    self.setupTableView()
                } else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                    self.showAlertExpiredToken(code: response.code) { [weak self] result in
                        guard let self = self else { return }
                        if result {
                            self.callApi()
                        }
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
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(R.nib.titleInventoryCell)
        tableView.register(R.nib.invenTableViewCell)
        tableView.register(R.nib.totalItemTableViewCell)
        tableView.register(R.nib.noteCell)
        tableView.register(R.nib.historyInventoryCell)
        tableView.contentInset.bottom = 16
        
    }
    
    func setDisplay() {
        if let titleString = titleString {
            title = titleString
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setDisplay()
    }
    
    private func showToast() {
        let attribute1 = [NSAttributedString.Key.font: fontUtils.size14.regular]
        let attrString1 = NSMutableAttributedString(string: self.message, attributes: attribute1)
        self.view.showToastCompletion(attrString1, numberOfLine: 1, img: UIImage(named: R.image.icTickCircle.name), isSee: false, completion: {
        })
    }
    
    private func setupUI() {
        let yourBackImage = UIImage(named: R.image.ic_back.name)
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.tintColor = UIColor.gray
        self.navigationItem.setHidesBackButton(true, animated: true)
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: nil)
        self.navigationItem.leftBarButtonItem = buttonLeft
        titlePartCodeLabel.font = fontUtils.size14.regular
        titleComponentNameLabel.font = fontUtils.size14.regular
        titleLocationLabel.font = fontUtils.size14.regular
        titleStatusLabel.font = fontUtils.size14.regular
        titleSaleLabel.font = fontUtils.size14.regular
        titleNoteLabel.font = fontUtils.size14.regular
        
        valuePartCodeLabel.font = fontUtils.size24.bold
        valueComponentNameLabel.font = fontUtils.size14.regular
        valueLocationLabel.font = fontUtils.size14.regular
        valueStatusLabel.font = fontUtils.size14.regular
        valueSaleLabel.font = fontUtils.size14.regular
        valueNoteLabel.font = fontUtils.size14.regular
        
        valuePartCodeLabel.text = dataDetail?.componentCode
        valueComponentNameLabel.text = dataDetail?.componentName
        valueLocationLabel.text = dataDetail?.positionCode
        valueStatusLabel.text = self.dataDetail?.status == 6 ? "Đã đạt giám sát".localized() : "Không đạt giám sát".localized()
        valueStatusLabel.textColor = UIColor(named: self.dataDetail?.status == 6 ? R.color.textBlue.name : R.color.textRed.name)
        valueSaleLabel.text = dataDetail?.salesOrder
        valueNoteLabel.text = dataDetail?.note
        
        valueSaleLabel.isHidden = dataDetail?.salesOrder?.isEmpty ?? true
        valueNoteLabel.isHidden = dataDetail?.note?.isEmpty ?? true
        titleNoteLabel.isHidden = dataDetail?.note?.isEmpty ?? true
        titleSaleLabel.isHidden = dataDetail?.salesOrder?.isEmpty ?? true
    }
    
}

extension WaitConfirmMonitorViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 9
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SectionInventory(rawValue: section) {
        case .titleInventory,
                .sumInventory:
            return arrayData.count > 0 ? 1 : 0
        case .rowInventory:
            return arrayData.count
        case .titleHistory:
            return 1
        case .historyInventory:
            return arrayHistory.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch SectionInventory(rawValue: indexPath.section) {
        case .titleInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            return cell
        case .rowInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.invenTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setDataToCellMonitor(data: arrayData[indexPath.row],index: indexPath.row, isLast: (arrayData.count - 1) == indexPath.row ? true : false, isHiddenCheckBox: true, isHideTextField: false)
            
            var totalValue: Double = 0.0
            for item in self.arrayData {
                let result = item.quantityPerBom
                let result2 = item.quantityOfBom
                totalValue = ((result ?? 0) * (result2 ?? 0)) + totalValue
            }
            
            self.valueSum = totalValue
            return cell
        case .sumInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.totalItemTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setDataToCell(totalValue: valueSum)
            return cell
        case .titleHistory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.noteCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.isHiddenAddButton = true
            cell.setDataForTitle()
            return cell
        case .historyInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.historyInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.fillDataDocC(data: self.arrayHistory[indexPath.row])
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch SectionInventory(rawValue: indexPath.section) {
        case .noteInventory:
            return 0
        case .titleHistory:
            return 50
        case .historyInventory:
            return UITableView.automaticDimension
        default:
            return 60
        }
    }
    
}
