//
//  UIVIew.swift
//  BIVN
//
//  Created by tinhvan on 18/09/2023.
//

import Foundation
import UIKit
import SnapKit

extension UIView {
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }
    
    func addshadow(top: Bool,left: Bool,bottom: Bool,right: Bool,shadowRadius: CGFloat = 2.0) {

        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowOpacity = 1.0

        let path = UIBezierPath()
        var x: CGFloat = 0
        var y: CGFloat = 2
        var viewWidth = UIScreen.main.bounds.width
        var viewHeight = self.frame.height
        if (!top) {
            y+=(shadowRadius+1)
        }
        if (!bottom) {
            viewHeight-=(shadowRadius+1)
        }
        if (!left) {
            x+=(shadowRadius+1)
        }
        if (!right) {
            viewWidth-=(shadowRadius+1)
        }

        // selecting top most point
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x, y: viewHeight))
        path.addLine(to: CGPoint(x: viewWidth, y: viewHeight))
        path.addLine(to: CGPoint(x: viewWidth, y: y))
        path.close()
        self.layer.shadowPath = path.cgPath
      }
    
    func addBottomShadow() {
        layer.masksToBounds = false
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.3
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowOffset = CGSize(width: 0 , height: 2)
        layer.shadowPath = UIBezierPath(rect: CGRect(x: 0,
                                                     y: bounds.maxY - layer.shadowRadius,
                                                     width: bounds.width,
                                                     height: layer.shadowRadius)).cgPath
    }
    
    func showToastCompletion(_ msg: NSMutableAttributedString, numberOfLine: Int = 2, marginBottom: Int = -32, img: UIImage? = UIImage(named: "ic_heart_fill_white"), isSee: Bool = true, completion: @escaping (() -> Void)) {
        if let window = window {
            for view in window.subviews where view.tag == 9999 {
                view.removeFromSuperview()
            }
        }
        
        let window = UIApplication.shared.keyWindow
        let containerView = UIView()
        containerView.layer.cornerRadius = 6
        containerView.backgroundColor = UIColor(hexString: "333333").withAlphaComponent(0.95)
        containerView.tag = 9999
        window?.addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualToSuperview().offset(8)
            make.trailing.lessThanOrEqualToSuperview().offset(-8)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(marginBottom)
            make.height.equalTo(52)
        }
        
        let heart = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        heart.image = img
        containerView.addSubview(heart)
        
        let msgLabel = UILabel()
        msgLabel.font = fontUtils.size14.regular
        msgLabel.textColor = .white
        msgLabel.numberOfLines = numberOfLine
        msgLabel.attributedText = msg
        containerView.addSubview(msgLabel)
        
        heart.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
        }
        if isSee {
            let see = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
            see.setTitle("Xem", for: .normal)
            see.titleLabel?.font = fontUtils.size14.regular
            see.setTitleColor(UIColor(named: R.color.buttonBlue.name), for: .normal)
            containerView.addSubview(see)
            
            see.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-12)
                make.centerY.equalToSuperview()
            }
            see.addAction {
                completion()
            }
        }
        
        msgLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(48)
            make.trailing.equalToSuperview().offset(-48)
            make.centerY.equalToSuperview()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if let window = window {
                for view in window.subviews where view.tag == 9999 {
                    view.removeFromSuperview()
                }
            }
        }
    }

    func formatStringNumberWithCommas(_ numberString: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","

        if let number = Double(numberString) {
            return formatter.string(from: NSNumber(value: number)) ?? "0,0"
        }
        return "0,0"
    }
}

extension UIControl {
    func addAction(for controlEvents: UIControl.Event = .touchUpInside, _ closure: @escaping () -> Void) {
        @objc class ClosureSleeve: NSObject {
            let closure: () -> Void
            init(_ closure: @escaping() -> Void) { self.closure = closure }
            @objc func invoke() { closure() }
        }
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
        objc_setAssociatedObject(self, "\(UUID())", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}
