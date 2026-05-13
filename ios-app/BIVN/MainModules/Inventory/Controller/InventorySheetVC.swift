//
//  InventorySheetVC.swift
//  BIVN
//
//  Created by Tinhvan on 03/11/2023.
//

import UIKit
import Localize_Swift

class InventorySheetVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addRowButton: UIButton!
    @IBOutlet weak var containerView: UIStackView!
    
    private var rowSelected = -1
    private var arrayData: [Int] = []
    private var arrayHistoryInventory: [Int] = [1]
    private var valueSumTest: Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    private func setupUI() {
        self.hideKeyboardWhenTappedAround()
        let yourBackImage = UIImage(named: R.image.ic_back.name)
        self.navigationController?.navigationBar.backIndicatorImage = yourBackImage
        self.navigationController?.navigationBar.tintColor = UIColor.gray
        self.navigationItem.setHidesBackButton(true, animated: true)
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: #selector(onTapBack))
        self.navigationItem.leftBarButtonItem = buttonLeft
        self.title = "Inventory Sheet"
        addRowButton.setTitle("+ Thêm dòng".localized(), for: .normal)
        addRowButton.addTarget(self, action: #selector(addOnTap), for: .touchUpInside)
        
        setupTableView()
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
        tableView.register(R.nib.contentSheetTBCell)
        tableView.register(R.nib.pageTBCell)
        tableView.contentInset.bottom = 16

    }
    
    @objc private func onTapBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func onTapCapture() {
        
    }
    
    @objc private func sendOnTap() {
        
    }
    
    @objc private func addOnTap() {
        arrayData.append(1)
        tableView.reloadData()
    }
    
    private var indexChooseStorage = 0
    private func addViewDropDown() {
        let dataStorage = [DataStorageModel(id: "1", layout: "DA123847"), DataStorageModel(id: "2", layout: "DB123536")]
        
        let dropDownWindow = DropDownWindow(frames: containerView.frame, viewSelect: containerView, data: dataStorage, indexChoose: self.indexChooseStorage)
        dropDownWindow.dropDownData = { (data, index) in
            print(data.layout!)
            self.indexChooseStorage = index
        }
        self.present(dropDownWindow, animated: true)
    }

}

extension InventorySheetVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 9
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SectionInventory(rawValue: section) {
        case .titleInventory,
            .sumInventory,
            .noteInventory:
            return arrayData.count > 0 ? 1 : 0
        case .rowInventory:
            return arrayData.count
        case .titleHistory:
            return arrayHistoryInventory.count
        case .historyInventory:
            return arrayHistoryInventory.count
        case .titleTableInventory:
            return 1
        case .tableInventory:
            return 9
        case .pageTableInventory:
            return 1
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
//            cell.setDataToCell(index: indexPath.row, isLast: (arrayData.count - 1) == indexPath.row ? true : false)
            cell.deleteRow = { (index) in
                self.arrayData.remove(at: index)
                self.tableView.reloadData()
            }
//            cell.sumTotal = { (value) in
//                self.valueSumTest = value
//                self.tableView.reloadSections(IndexSet(integer: 2), with: .none)
//            }
            
            return cell
        case .sumInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.totalItemTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            
            cell.setDataToCell(totalValue: valueSumTest)
            
            return cell
        case .noteInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.noteCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setDataToView()
            cell.placeholderLabel.text = "Nhập mã linh kiện".localized()
            cell.titleLabel.text = "Chi tiết".localized()
            return cell
        case .titleHistory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.noteCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setDataForTitle()
            return cell
        case .titleTableInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.contentSheetTBCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setDataToCell(isContent: false, index: indexPath.row)
            return cell
        case .tableInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.contentSheetTBCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setDataToCell(isContent: true, index: indexPath.row)
            return cell
        case .pageTableInventory:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.pageTBCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setDataToCell()
            cell.dropDownPage = {
                self.addViewDropDown()
            }
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch SectionInventory(rawValue: indexPath.section) {
        case .noteInventory:
            return 120
        case .titleHistory:
            return 60
        case .historyInventory:
            return 80
        case .titleTableInventory:
            return 50
        case .tableInventory:
            return 50
        case .pageTableInventory:
            return 50
        default:
            return 60
        }
    }
    
}
