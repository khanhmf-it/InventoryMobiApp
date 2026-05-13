//
//  NoteCell.swift
//  BIVN
//
//  Created by Tinhvan on 02/11/2023.
//

import UIKit
import Localize_Swift

protocol NoteCellProtocol: AnyObject {
    func updateHeightNote (_ cell: NoteCell, _ textView: UITextView)
}

class NoteCell: UITableViewCell {

    @IBOutlet weak var addNoteLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var reasonTextView: UITextView!
    @IBOutlet weak var errorReasonLabel: UILabel!
    @IBOutlet weak var viewTitle: UIView!
    @IBOutlet weak var heightContrainNote: NSLayoutConstraint!
    
    var placeholderLabel = UILabel()
    var isHiddenAddButton = true
    var isHiddenReason = true
    var hiddenReason: ((Bool) -> ())?
    var callBackListener : ((String) -> ())?
    var getNote: ((String) -> ())?
    var isMonitor: Bool = false
    weak var cellDelegate: NoteCellProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    func setDataToView() {
        configView()
    }
    
    func setDataForTitle() {
        addNoteLabel.isHidden = isHiddenAddButton
        errorReasonLabel.isHidden = true
        reasonTextView.isHidden = true
        titleLabel.text = "Lịch sử".localized()
        titleLabel.textColor = UIColor(named: R.color.buttonBlue.name)
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
    }
    
    
    private func configView() {
        viewTitle.isHidden = false
        errorReasonLabel.textColor = UIColor(named: R.color.textRed.name)
        errorReasonLabel.isHidden = true
        reasonTextView.isHidden = self.isHiddenReason
        
        reasonTextView!.layer.cornerRadius = 5
        reasonTextView!.layer.borderWidth = 1
        reasonTextView!.layer.borderColor = UIColor(named: R.color.lineColor.name)?.cgColor
        
        reasonTextView.delegate = self
        placeholderLabel.text = "Nhập ghi chú của bạn...".localized()
        placeholderLabel.font = .systemFont(ofSize: (reasonTextView.font?.pointSize)!, weight: .regular)
        placeholderLabel.sizeToFit()
        reasonTextView.addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPoint(x: 5, y: (reasonTextView.font?.pointSize)! / 2)
        placeholderLabel.textColor = UIColor(named: R.color.textDefault.name)?.withAlphaComponent(0.4)
        placeholderLabel.isHidden = !reasonTextView.text.isEmpty
        
        titleLabel.text = "Ghi chú".localized()
        titleLabel.textColor = UIColor(named: R.color.textDefault.name)
        titleLabel.font = fontUtils.size14.regular
        
        addNoteLabel.isHidden = isHiddenAddButton
        addNoteLabel.addTapGestureRecognizer {
            self.isHiddenReason = !self.isHiddenReason
            self.addNoteLabel.text = self.isHiddenReason ? "+" : "-"
            self.reasonTextView.isHidden = self.isHiddenReason
            self.hiddenReason?(self.isHiddenReason)
        }
        titleLabel.addTapGestureRecognizer {
            self.isHiddenReason = !self.isHiddenReason
            self.addNoteLabel.text = self.isHiddenReason ? "+" : "-"
            self.reasonTextView.isHidden = self.isHiddenReason
            self.hiddenReason?(self.isHiddenReason)
        }
    }
    
    func setDataForHistory(note: String) {
        errorReasonLabel.textColor = UIColor(named: R.color.textRed.name)
        errorReasonLabel.isHidden = true
        reasonTextView.isHidden = false
        reasonTextView.isScrollEnabled = false
        reasonTextView!.layer.cornerRadius = 5
        reasonTextView!.layer.borderWidth = 1
        reasonTextView!.layer.borderColor = UIColor(named: R.color.lineColor.name)?.cgColor
        
        reasonTextView.delegate = self
        reasonTextView.backgroundColor = .white
        reasonTextView.addSubview(placeholderLabel)
        reasonTextView.isUserInteractionEnabled = false
        reasonTextView.text = note
        titleLabel.text = "Ghi chú".localized()
        titleLabel.textColor = UIColor(named: R.color.textDefault.name)
        titleLabel.font = fontUtils.size14.regular
        addNoteLabel.isHidden = true
    }
    
    func showErrorTableView() {
        errorReasonLabel.isHidden = false
        reasonTextView.isHidden = true
        viewTitle.isHidden = true
        errorReasonLabel.textColor = UIColor(named: R.color.textRed.name)
        errorReasonLabel.text = "Vui lòng nhập số lượng và số thùng.".localized()
    }
}

extension NoteCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView == reasonTextView {
            if textView.text.count > 0 {
                errorReasonLabel.isHidden = true
            } else {
                errorReasonLabel.isHidden = false
            }
            if self.isMonitor {
                errorReasonLabel.isHidden = true
            }
            getNote?(self.reasonTextView.text ?? "")
            guard let callBack = self.callBackListener else {return}
            callBack(textView.text)
            if let delegate = cellDelegate {
                delegate.updateHeightNote(self, textView)
            }
        }
        
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !reasonTextView.text.isEmpty
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = true
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        if textView == reasonTextView {
            if newText.count > 200 {
                reasonTextView.text = String(newText.prefix(200))
            }
        }
        return numberOfChars < 201
    }
}
