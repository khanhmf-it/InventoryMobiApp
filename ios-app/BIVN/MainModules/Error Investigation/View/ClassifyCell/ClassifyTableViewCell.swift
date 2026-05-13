//
//  ClassifyTableViewCell.swift
//  BIVN
//
//  Created by Bi on 13/1/25.
//

import UIKit
import Localize_Swift

class ClassifyTableViewCell: UITableViewCell {
    @IBOutlet weak var classifyTextField: UITextField!
    @IBOutlet weak var dropdownButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var titleNameLabel: UILabel!
    
    
    var onTapDropdown: ((UIButton, UITextField) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleNameLabel.text = "Phân loại".localized()
        titleNameLabel.font = fontUtils.size12.bold
        classifyTextField.text = "Chọn phân loại".localized()
        addDropdownImage(textField: classifyTextField)
        classifyTextField.isUserInteractionEnabled = false
        dropdownButton.setTitle("", for: .normal)
        errorLabel.isHidden = true
        errorLabel.textColor = UIColor(named: R.color.textRed.name)
        errorLabel.font = UIFont.systemFont(ofSize: 12)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
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
    
    func showError(message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    func hideError() {
        errorLabel.isHidden = true
    }
    
    @IBAction func ontapDropdown(_ sender: UIButton) {
        onTapDropdown?(dropdownButton, classifyTextField)
    }
    
}
