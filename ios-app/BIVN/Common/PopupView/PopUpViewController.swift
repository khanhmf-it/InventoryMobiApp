//
//  PopUpViewController.swift
//  BIVN
//
//  Created by tinhvan on 18/09/2023.
//

import UIKit
import Localize_Swift

class PopUpViewController: UIViewController {
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var cstHeightView: NSLayoutConstraint!
    @IBOutlet var contentView: UIView!
    
    var indexChoice = 0
    var arrayData: [String] = []
    var arrayStatus: [Int] = []
    var cancelClosure: (() -> Void)?
    var accpectClosure: ((Int?) -> ())?
    var titleText = ""
    var isHiddenRadio: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        prioritizeInventory()
        updateUI()
        contentView.layer.shadowOpacity = 0.3
        contentView.layer.shadowOffset = .zero
        contentView.layer.cornerRadius = 8
        tableView.alwaysBounceVertical = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.cstHeightView.constant = !isHiddenRadio ? CGFloat(90 + (arrayData.count > 6 ? 200 : arrayData.count * 44)): 200
    }
    
    func updateUI() {
        tableView.delegate = self
        tableView.dataSource = self
        cancelButton.setTitle("Huỷ bỏ".localized(), for: .normal)
        acceptButton.setTitle("Đồng ý".localized(), for: .normal)
        tableView.register(R.nib.chooseTableViewCell)
        popupView.layer.shadowOpacity = 0.3
        popupView.layer.shadowOffset = .zero
        popupView.layer.cornerRadius = 8
        
        titleLabel.text = titleText
    }
    
    func prioritizeInventory() {
        var prioritize: Int = 0
        for (index,item) in arrayStatus.enumerated() {
            if prioritize == 0 {
                prioritize = item
                indexChoice = index
            } else {
                if item < prioritize {
                    prioritize = item
                    indexChoice = index
                }
            }
        }
    }
    
    @IBAction func onTapCancel(_ sender: UIButton) {
        dismiss(animated: true, completion: cancelClosure)
    }
    
    @IBAction func onTapAccept(_ sender: UIButton) {
        dismiss(animated: true) {
            self.accpectClosure?(self.indexChoice)
        }
    }
}

extension PopUpViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.chooseTableViewCell, for: indexPath) else {return UITableViewCell()}
        if !isHiddenRadio {
            if arrayStatus.count > 0 {
                cell.setDataToCell(data: arrayData[indexPath.row], status: arrayStatus[indexPath.row], isSelected: indexChoice == indexPath.row ? true : false)
            } else {
                cell.setDataToCell(data: arrayData[indexPath.row], isSelected: indexChoice == indexPath.row ? true : false)
            }
        } else {
            cell.isHiddenRadio(data:  arrayData[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        indexChoice = indexPath.row
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return !isHiddenRadio ? 44 : UITableView.automaticDimension
    }
}
