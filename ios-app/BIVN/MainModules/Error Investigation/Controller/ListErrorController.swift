//
//  ListErrorController.swift
//  BIVN
//
//  Created by Bi on 7/1/25.
//

import UIKit
import DropDown
import Localize_Swift
import Moya

enum StatusEnum: Int, CaseIterable {
    case all = 3
    case Investigated = 2
    case NotInvestigated = 0
    case UnderInvestigation = 1
    
    var displayName: String {
        switch self {
        case .all:
            return "Tất cả".localized()
        case .Investigated:
            return "Đã điều tra".localized()
        case .NotInvestigated:
            return "Chưa điều tra".localized()
        case .UnderInvestigation:
            return "Đang điều tra".localized()
        }
    }
    
    var color: UIColor {
        switch self {
        case .all:
            return UIColor(named: R.color.textOrange.name) ?? UIColor.black
        case .Investigated:
            return UIColor(named: R.color.greenColor.name) ?? UIColor.green
        case .NotInvestigated:
            return UIColor(named: R.color.greyDC.name) ?? UIColor.red
        case .UnderInvestigation:
            return UIColor(named: R.color.textOrange.name) ?? UIColor.orange
        }
    }
    
    static func fromRawValue(_ rawValue: Int) -> StatusEnum? {
        return StatusEnum(rawValue: rawValue)
    }
}

enum StatusDisplayError: Int, CaseIterable {
    case NotInvestigated = 0
    case UnderInvestigation = 1
    case Investigated = 2
    
    var displayName: String {
        switch self {
        case .Investigated:
            return "Đã điều tra".localized()
        case .NotInvestigated:
            return "Chưa điều tra".localized()
        case .UnderInvestigation:
            return "Đang điều tra".localized()
        }
    }
    
    var color: UIColor {
        switch self {
        case .Investigated:
            return UIColor(named: R.color.greenColor.name) ?? UIColor.green
        case .NotInvestigated:
            return UIColor(named: R.color.greyStatus.name) ?? UIColor.red
        case .UnderInvestigation:
            return UIColor(named: R.color.textOrange.name) ?? UIColor.orange
        }
    }
    
    var colorBacground: UIColor {
        switch self {
        case .Investigated:
            return UIColor(named: R.color.greyDC.name) ?? UIColor.green
        case .NotInvestigated, .UnderInvestigation:
            return UIColor(named: R.color.white.name) ?? UIColor.red
        }
    }
    
    static func fromRawValue(_ rawValue: Int) -> StatusDisplayError? {
        return StatusDisplayError(rawValue: rawValue)
    }
}

class ListErrorController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var statusTextField: UITextField!
    @IBOutlet weak var eventTextField: UITextField!
    @IBOutlet weak var statusButton: UIButton!
    @IBOutlet weak var hideButton: UIButton!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(R.nib.listErrorTableViewCell)
        }
    }
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var titleStatusLabel: UILabel!
    @IBOutlet weak var titleaccessoryLabel: UILabel!
    
    
    let myDropDown = DropDown()
    let networkManager: NetworkManager = NetworkManager()
    var param = Dictionary<String, Any>()
    var listErrorModel: [ResultErrorModel] = []
    var currentPage = 1
    var hasMoreData = true
    var titleString: String?
    var loadingIndicator: UIActivityIndicatorView!
    var employeeID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateStatusLocally(_:)), name: NSNotification.Name("UpdateStatusSuccess"), object: nil)
        setupUI()
        callAPI(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "")
        employeeID = UserDefaults.standard.string(forKey: "MANHANVIEN")
    }
    
    @objc private func updateStatusLocally(_ notification: Notification) {
        guard let componentCode = notification.userInfo?["componentCode"] as? String else { return }

        if let index = listErrorModel.firstIndex(where: { $0.componentCode == componentCode }) {
            listErrorModel[index].status = StatusEnum.NotInvestigated.rawValue
            _ = listErrorModel.remove(at: index)
            fetchInvestigatedErrors { [weak self] newData in
                guard let self = self else { return }
                self.listErrorModel = newData
                self.tableView.reloadData()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setDisplay()
    }
    
    func setDisplay() {
        if let titleString = titleString {
            title = titleString
        }
    }
    
    @objc private func onTapBack() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupUI() {
        hideKeyboardWhenTappedAround()
        hideButton.isEnabled = false
        hideButton.setTitle("", for: .normal)
        let backImage = UIImage(named: R.image.ic_back.name)
        self.navigationController?.navigationBar.backIndicatorImage = backImage
        self.navigationItem.setHidesBackButton(true, animated: true)
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: #selector(onTapBack))
        self.navigationItem.leftBarButtonItem = buttonLeft
        titleStatusLabel.text = "Trạng thái".localized()
        titleStatusLabel.font = fontUtils.size12.bold
        titleaccessoryLabel.text = "Linh kiện".localized()
        titleaccessoryLabel.font = fontUtils.size12.bold
        errorLabel.isHidden = true
        errorLabel.text = "Không có kết quả phù hợp".localized()
        errorLabel.font = fontUtils.size14.medium
        statusTextField.text = "Tất cả".localized()
        eventTextField.placeholder = "Nhập mã linh kiện...".localized()
        eventTextField.text?.uppercased()
        statusButton.setTitle("", for: .normal)
        addDropdownImage(textField: statusTextField)
        let imageIcon = UIImageView()
        imageIcon.image = UIImage(named: R.image.ic_search.name)
        let contentView = UIView()
        contentView.addSubview(imageIcon)
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: UIImage(named: R.image.ic_search.name)?.size.width ?? 0, height: UIImage(named: R.image.ic_search.name)?.size.height ?? 0))
        contentView.addSubview(button)
        contentView.frame = CGRect(x: 0, y: 0, width: UIImage(named: R.image.ic_search.name)?.size.width ?? 0, height: UIImage(named: R.image.ic_search.name)?.size.height ?? 0)
        imageIcon.frame = CGRect(x: -10, y: 0, width: UIImage(named: R.image.ic_search.name)?.size.width ?? 0, height: UIImage(named: R.image.ic_search.name)?.size.height ?? 0)
        eventTextField.rightView = contentView
        eventTextField.rightViewMode = .always
        eventTextField.clearButtonMode = .whileEditing
        eventTextField.addTarget(self, action: #selector(onSearchComponentCode), for: .editingDidEndOnExit)
        eventTextField.addTarget(self, action: #selector(onSearchComponentCode), for: .editingDidEnd)
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.color = .gray
        loadingIndicator.center = self.view.center
        self.view.addSubview(loadingIndicator)
        
    }
    
    @objc private func onSearchComponentCode() {
        self.currentPage = 1
        self.listErrorModel = []
        self.hasMoreData = true
        callAPI(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        if offsetY > contentHeight - frameHeight - 100 && !isLoading && hasMoreData {
            loadMoreData()
        }
    }
    
    private func callAPIDocumentCheck(inventoryId: String, componentCode: String, itemData: ResultErrorModel) {
        var param = Dictionary<String, Any>()
        param["userCode"] = employeeID
        networkManager.documentCheck(inventoryId: inventoryId, componentCode: componentCode, param: param,  completion: { [weak self] data in
            guard let self = self else { return }
            self.isLoading = false
            switch data {
            case .success(let response):
                if response.code == 200 {
                    guard let vc = Storyboards.accessory.instantiate() as? AccessoryController else {return}
                    vc.componentCode = itemData.componentCode
                    navigationController?.pushViewController(vc, animated: true)
                } else {
                    self.showAlertNoti(
                        title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                        message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),
                        cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0),
                        acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0)
                    )
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
    
    private func fetchInvestigatedErrors(completion: @escaping ([ResultErrorModel]) -> Void) {
        self.param["status"] = StatusEnum.NotInvestigated.rawValue
        self.param["componentCode"] = eventTextField.text?.uppercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.param["pageNum"] = currentPage
        self.param["pageSize"] = 20
        
        networkManager.getListError(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", param: self.param) { result in
            switch result {
            case .success(let response):
                if response.code == 200 {
                    let investigatedErrors = response.data ?? []
                    completion(investigatedErrors)
                } else {
                    completion([])
                }
            case .failure(let error):
                print("Fetch investigated errors failed: \(error.localizedDescription)")
                completion([])
            }
        }
    }

    
    private func loadMoreData() {
        guard !isLoading else { return }
        loadingIndicator.startAnimating()
        hideButton.isEnabled = true
        isLoading = true
        currentPage += 1
        self.param["pageNum"] = currentPage
        networkManager.getListError(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", param: param) { [weak self] data in
            guard let self = self else { return }
            self.loadingIndicator.stopAnimating()
            hideButton.isEnabled = false
            self.isLoading = false
            switch data {
            case .success(let response):
                if response.code == 200 {
                    let newData = response.data ?? []
                    if newData.isEmpty {
                        self.hasMoreData = false
                    } else {
                        self.listErrorModel.append(contentsOf: newData)
                        self.tableView.reloadData()
                    }
                } else {
                    self.hasMoreData = false
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    
    func getHistory(resultErrorModel :ResultErrorModel?){
        self.showLoading()
        networkManager.getHistoryInvestigation(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "" , componentCode: resultErrorModel?.componentCode ?? "", completion: {[weak self] response in
            self?.hideLoading()
            switch response {
            case .success(let response):
                if response.code == 200 {
                    guard let historyData = response.data, !(response.data?.isEmpty ?? true) else {
                        self?.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
                        return
                    }
                    guard let historyVC = Storyboards.historyAccessory.instantiate() as? HistoryController else { return }
                     historyVC.resultModel = resultErrorModel
                    historyVC.historyData = historyData
                    self?.navigationController?.pushViewController(historyVC, animated: true)
                }
                else if response.code == 401 || response.code == 403 || response.code == 60 || response.code == 15 || response.code == 17 || response.code == 56 {
                   self?.showAlertExpiredToken(code: response.code) { [weak self] result in
                       guard let self = self else { return }
                       if result {
                           self.getHistory(resultErrorModel: resultErrorModel)
                       }
                   }
               }
                else {
                    self?.showAlertNoti(title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0), message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0) , acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0))
                }
                
            case .failure(let error):
                if case MoyaError.underlying(let underlyingError, _) = error {
                    if (underlyingError as NSError).code == 13 {
                        self?.showAlertConfigTimeOut()
                    }
                }
            }
        })
    }
    
    
    private func showDropdownStatus() {
        let dropdownModel = StatusEnum.allCases.map { $0.displayName }
        myDropDown.dataSource = dropdownModel
        myDropDown.anchorView = statusButton
        myDropDown.bottomOffset = CGPoint(x: 0, y: (statusTextField.frame.size.height + 5))
        myDropDown.topOffset = CGPoint(x: 0, y: -(myDropDown.anchorView?.plainView.bounds.height)!)
        myDropDown.dismissMode = .onTap
        myDropDown.direction = .bottom
        myDropDown.selectionAction = { (index: Int, item: String) in
            self.statusTextField.text = item
            let selectedStatus = StatusEnum.allCases[index]
            self.statusTextField.text = selectedStatus.displayName
            let selectedRawValue = selectedStatus.rawValue
            if selectedRawValue == 3 {
                self.param.removeValue(forKey: "status")
            } else {
                self.param["status"] = selectedRawValue
            }
            self.currentPage = 1
            self.listErrorModel = []
            self.hasMoreData = true
            self.isLoading = false
            self.callAPI(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "")
            
        }
        myDropDown.show()
    }
    
    private func addDropdownImage(textField: UITextField) {
        let imageIcon = UIImageView()
        imageIcon.image = UIImage(named: R.image.ic_dropDown.name)
        let contentView = UIView()
        contentView.addSubview(imageIcon)
        contentView.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        imageIcon.frame = CGRect(x: -10, y: 0, width: 18, height: 18)
        textField.rightView = contentView
        textField.rightViewMode = .always
        textField.clearButtonMode = .whileEditing
    }
    
    
    @IBAction func ontapDropdown(_ sender: UIButton) {
        showDropdownStatus()
    }
    
    private func callAPI(inventoryId: String?) {
        self.param["componentCode"] = eventTextField.text?.uppercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.param["pageNum"] = currentPage
        self.param["pageSize"] = 20
        loadingIndicator.startAnimating()
        self.tableView.isScrollEnabled = false
        networkManager.getListError(inventoryId: inventoryId ?? "", param: param) { [weak self] data in
            guard let self = self else { return }
            self.isLoading = false
            self.tableView.isScrollEnabled = true
            self.loadingIndicator.stopAnimating()
            switch data {
            case .success(let response):
                if response.code == 200 {
                    let newData = response.data ?? []
                    if newData.count == 0 {
                        errorLabel.isHidden = false
                        tableView.isHidden = true
                    } else {
                        errorLabel.isHidden = true
                        tableView.isHidden = false
                        if self.currentPage == 1 {
                            self.listErrorModel = newData
                        } else {
                            self.listErrorModel.append(contentsOf: newData)
                        }
                    }
                    self.tableView.reloadData()
                } else {
                    self.hasMoreData = false
                    self.showAlertNoti(
                        title: UserDefault.shared.showErrorTitle(errorCode: response.code ?? 0),
                        message: UserDefault.shared.showErrorText(errorCode: response.code ?? 0),
                        cancelButton: UserDefault.shared.titleCancel(errorCode: response.code ?? 0),
                        acceptButton: UserDefault.shared.titleAccept(errorCode: response.code ?? 0)
                    )
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listErrorModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.listErrorTableViewCell, for: indexPath) else {return UITableViewCell()}
        cell.fillData(listErrorModel: listErrorModel[indexPath.row])
        cell.selectionStyle = .none
        cell.onClickHistory = {(data) in
            self.getHistory(resultErrorModel: data)
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemData = listErrorModel[indexPath.row]
        self.callAPIDocumentCheck(inventoryId: UserDefault.shared.getDataLoginModel().inventoryLoggedInfo?.inventoryModel?.inventoryId ?? "", componentCode: itemData.componentCode ?? "", itemData: itemData)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
}

struct CustomDouble {
    var value: Double
    
    var formattedValue: String {
        let formattedString = String(format: "%.15g", value)
        return formattedString
    }
}
