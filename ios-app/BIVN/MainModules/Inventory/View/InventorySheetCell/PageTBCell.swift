//
//  PageTBCell.swift
//  BIVN
//
//  Created by Tinhvan on 03/11/2023.
//

import UIKit

class PageTBCell: UITableViewCell {
    
    @IBOutlet weak var viewLeft: UIView!
    @IBOutlet weak var viewRight: UIView!
    @IBOutlet weak var viewPage: UIView!
    @IBOutlet weak var numberPageLabel: UILabel!
    @IBOutlet weak var textPageLabel: UILabel!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var numberButton: UIButton!
    
    var dropDownPage: (() -> ())?
    var rightPage: (() -> (Void))?
    var leftPage: (() -> (Void))?
    var onTapShowDropDown: ((UILabel, UIButton) -> (Void))?
    var isCheckNext: Bool = true
    var isCheckPrevious: Bool = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        rightButton.setTitle("", for: .normal)
        leftButton.setTitle("", for: .normal)
        numberButton.setTitle("", for: .normal)
    }
    
    func setDataToCell() {
        viewPage.addTapGestureRecognizer {
            self.dropDownPage?()
        }
    }
    
    private func onTapView(isLeft: Bool = false) {
        viewLeft.backgroundColor = isLeft ? UIColor(named: R.color.grey1.name) : UIColor.clear
        viewRight.backgroundColor = !isLeft ? UIColor(named: R.color.grey1.name) : UIColor.clear
    }
    
    @IBAction func onTapNextPage(_ sender: UIButton) {
        if isCheckNext {
            self.rightPage?()
        }
    }
    @IBAction func onTapPreviousPage(_ sender: UIButton) {
        if isCheckPrevious {
            self.leftPage?()
        }
    }
    @IBAction func onTapNumberPage(_ sender: UIButton) {
        onTapShowDropDown?(numberPageLabel, sender)
    }
    
}
