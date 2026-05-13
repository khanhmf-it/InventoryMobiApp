//
//  BaseTableViewCell.swift
//  BIVN
//
//  Created by TVO_M1 on 11/12/2023.
//
import UIKit

class BaseTableViewCell: UITableViewCell {

    weak var delegate: AnyObject?
    var indexPath: IndexPath?
    let numberFormatter = NumberFormatter()
    
    var isEnableLongPressGestureRecognizer: Bool = false
    lazy var longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateNumberFormatter()
        if isEnableLongPressGestureRecognizer {
            addGestureRecognizer(longPressGestureRecognizer)
        }
        
        self.selectionStyle = .none
    }
    
    func setIndexPath(_ indexPath: IndexPath?, delegate: AnyObject?) {
        self.indexPath = indexPath
        self.delegate = delegate
    }
    
    func updateNumberFormatter() {
        numberFormatter.locale = NSLocale.current
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        numberFormatter.groupingSeparator = Locale.current.groupingSeparator
    }
    
    func unFormatNumber(stringValue: String, regionUS: Bool) -> Double {
        var number: Double = 0.0
        if regionUS {
            let completeString = stringValue.replacingOccurrences(of: ",", with: "", options: NSString.CompareOptions.literal, range: nil)
            
            number = Double(completeString) ?? 0.0
        } else {
            var completeString = stringValue.replacingOccurrences(of: ".", with: "", options: NSString.CompareOptions.literal, range: nil)
            completeString = completeString.replacingOccurrences(of: ",", with: ".", options: NSString.CompareOptions.literal, range: nil)
            
            number = Double(completeString) ?? 0.0
        }
        return number
    }    
}

extension BaseTableViewCell {
    
    @objc func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        
    }

    @objc class func identifier() -> String {
        return self.nibName()
    }
    
    @objc func setData(_ data: Any?) {
        
    }
    
    static func nibName() -> String {
            let nameSpaceClassName = NSStringFromClass(self)
            let className = nameSpaceClassName.components(separatedBy: ".").last! as String
            return className
        }
}
