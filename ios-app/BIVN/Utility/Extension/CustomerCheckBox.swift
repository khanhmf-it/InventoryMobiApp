//
//  CustomerCheckBox.swift
//  BIVN
//
//  Created by Tan Tran on 08/12/2023.
//

import UIKit

class CustomerCheckBox: UIButton {
    // Images
    let checkedImage = UIImage(named: R.image.icCheckboxTick.name)! as UIImage
    let uncheckedImage = UIImage(named: R.image.icCheckboxUntick.name)! as UIImage
    
    // Bool property
    var isChecked: Bool = false {
        didSet {
            if isChecked == true {
                self.setImage(checkedImage, for: UIControl.State.normal)
            } else {
                self.setImage(uncheckedImage, for: UIControl.State.normal)
            }
        }
    }
        
    override func awakeFromNib() {
        self.addTarget(self, action:#selector(buttonClicked(sender:)), for: UIControl.Event.touchUpInside)
        self.isChecked = false
    }
        
    @objc func buttonClicked(sender: UIButton) {
        if sender == self {
            isChecked = !isChecked
        }
    }
}
