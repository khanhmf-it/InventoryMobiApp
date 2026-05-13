//
//  UIViewController.swift
//  BIVN
//
//  Created by Luyện Đào on 14/09/2023.
//
import UIKit

let LocalizeUserDefaultKey = "LocalizeUserDefaultKey"
var LocalizeUserDefautLanguage = "en"

extension UIViewController {
    static var identifier: String {
        return String(describing: self.self)
    }
    
    static var activityIndicatorTag = 12345
    static let regexUserID = "^[FMT][0-9]{7}"
    static let inventory = 0
    static let monitor = 1
    static let promote = 2
    static let errorInvestigation = 3
    
    func startLoading() {
        stopLoading()
        let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
        activityIndicator.tag = UIViewController.activityIndicatorTag
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .large
        
        DispatchQueue.main.async {
            self.view.addSubview(activityIndicator)
            activityIndicator.startAnimating()
        }
    }
    
    func stopLoading() {
        let activityIndicator = view.viewWithTag(UIViewController.activityIndicatorTag) as? UIActivityIndicatorView
        DispatchQueue.main.async {
            activityIndicator?.stopAnimating()
            activityIndicator?.removeFromSuperview()
        }
    }
    
    func createScannerGradientLayer(for view: UIView) -> CAGradientLayer {
        let height: CGFloat = 50
        let opacity: Float = 0.5
        let topColor = UIColor(named: R.color.buttonBlue.name)
        let bottomColor = topColor?.withAlphaComponent(0)
        
        let layer = CAGradientLayer()
        layer.colors = [topColor!.cgColor, bottomColor!.cgColor]
        layer.opacity = opacity
        layer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: height)
        return layer
    }
    
    func createAnimation(for layer: CAGradientLayer) -> CABasicAnimation {
        guard let superLayer = layer.superlayer else {
            fatalError("Unable to create animation, layer should have superlayer")
        }
        let superLayerHeight = superLayer.frame.height
        let layerHeight = layer.frame.height
        let value = superLayerHeight - layerHeight
        
        let initialYPosition = layer.position.y
        let finalYPosition = initialYPosition + value
        let duration: CFTimeInterval = 1
        
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = initialYPosition as NSNumber
        animation.toValue = finalYPosition as NSNumber
        animation.duration = duration
        animation.repeatCount = .infinity
        return animation
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
}

extension UITextField {
    func setupRightImage(iconAction: ((_ isShow: Bool) -> ())?) {
        var isShowPassword: Bool = true
        let imageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 20, height: 20))
        imageView.image = UIImage(named: "ic_eye")
        let imageContainerView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 44))
        imageContainerView.addSubview(imageView)
        rightView = imageContainerView
        rightViewMode = .always
        self.tintColor = .lightGray
        
        imageContainerView.addTapGestureRecognizer {
            isShowPassword = !isShowPassword
            imageView.image = isShowPassword ? UIImage(named: "ic_eye") : UIImage(named: "ic_eye_hide")
            
            iconAction?(isShowPassword)
        }
    }
    
    func setupLeftImage(imageName: String) {
        let imageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 20, height: 20))
        imageView.image = UIImage(named: imageName)
        let imageContainerView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 44))
        imageContainerView.addSubview(imageView)
        leftView = imageContainerView
        leftViewMode = .always
        self.tintColor = .lightGray
    }
    
    func placeholderColor(color: UIColor) {
        let attributeString = [
            NSAttributedString.Key.foregroundColor: color.withAlphaComponent(0.4),
            NSAttributedString.Key.font: self.font!
        ] as [NSAttributedString.Key : Any]
        self.attributedPlaceholder = NSAttributedString(string: self.placeholder!, attributes: attributeString)
    }
}

extension UIImageView {
    func cornerRadius() {
        self.layer.cornerRadius = (self.frame.width / 2)
        self.layer.masksToBounds = true
    }
}

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

extension UIView {
    fileprivate enum AssociatedObjectKeys {
        static var tapGestureRecognizer = "MediaViewerAssociatedObjectKey_mediaViewer"
    }
    
    fileprivate typealias Action = (() -> Void)?
    fileprivate var tapGestureRecognizerAction: Action? {
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedObjectKeys.tapGestureRecognizer, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            }
        }
        get {
            let tapGestureRecognizerActionInstance = objc_getAssociatedObject(self, &AssociatedObjectKeys.tapGestureRecognizer) as? Action
            return tapGestureRecognizerActionInstance
        }
    }
    
    @objc fileprivate func handleTapGesture(sender _: UITapGestureRecognizer) {
        if let action = tapGestureRecognizerAction {
            action?()
        } else {
            print("no action")
        }
    }
    
    public func addTapGestureRecognizer(action: (() -> Void)?) {
        isUserInteractionEnabled = true
        tapGestureRecognizerAction = action
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        addGestureRecognizer(tapGestureRecognizer)
    }
}


public typealias TextViewClosure = (String?) -> Void
fileprivate var addressKeyLimitCharacter = 1
fileprivate var closureAdapter = 2
fileprivate var addressColorPlaceholder = 3

fileprivate final class ClosuresWrapper {
    fileprivate var textViewClosure: TextViewClosure?
}

extension UITextView: UITextViewDelegate {
    
    fileprivate var closuresWrapper: ClosuresWrapper {
        get {
            if let wrapper = objc_getAssociatedObject(self, &closureAdapter) as? ClosuresWrapper {
                return wrapper
            }
            let closuresWrapper = ClosuresWrapper()
            self.closuresWrapper = closuresWrapper
            return closuresWrapper
        }
        set {
            self.delegate = self
            objc_setAssociatedObject(self, &closureAdapter, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    public var limitCharacter: Int? {
        get {
            if let number = objc_getAssociatedObject(self, &addressKeyLimitCharacter) as? Int {
                return number
            }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &addressKeyLimitCharacter, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var textViewClosure: TextViewClosure? {
        get { return closuresWrapper.textViewClosure }
        set { closuresWrapper.textViewClosure = newValue }
    }
    
    private enum Keys {
        static let viewTagPlaceholder = 100
    }
    
    override open var bounds: CGRect {
        didSet {
            self.resizePlaceholder()
        }
    }
    
    // MARK: - init with code
    public convenience init(placeholder: String) {
        self.init()
        self.placeholder = placeholder
    }
    
    // MARK: - init with IB
    @IBInspectable public var placeholder: String? {
        get {
            var placeholderText: String?
            if let placeholderLabel = self.viewWithTag(Keys.viewTagPlaceholder) as? UILabel {
                placeholderText = placeholderLabel.text
            }
            return placeholderText
        }
        set {
            if let placeholderLabel = self.viewWithTag(Keys.viewTagPlaceholder) as? UILabel {
                placeholderLabel.text = newValue
                placeholderLabel.sizeToFit()
            } else {
                self.addPlaceholder(newValue)
            }
        }
    }
    
    @IBInspectable public var placeholderColor: UIColor? {
        get {
            if let wrapper = objc_getAssociatedObject(self, &addressColorPlaceholder) as? UIColor {
                return wrapper
            }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &addressColorPlaceholder, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        if let placeholderLabel = self.viewWithTag(Keys.viewTagPlaceholder) as? UILabel {
            placeholderLabel.isHidden = !self.text.isEmpty
            textViewClosure?(textView.text)
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        guard let limitCharacter = limitCharacter else {
            return true // not limit
        }
        return updatedText.count <= limitCharacter // Change limit based on your requirement.
    }
    
    
    private func resizePlaceholder() {
        if let placeholderLabel = self.viewWithTag(Keys.viewTagPlaceholder) as? UILabel {
            placeholderLabel.lineBreakMode = .byWordWrapping
            placeholderLabel.numberOfLines = 0
            placeholderLabel.adjustsFontSizeToFitWidth = true
            let labelX = self.textContainer.lineFragmentPadding
            let labelY = self.textContainerInset.top - 2
            let labelWidth = self.frame.width - (labelX * 2)
            let labelHeight = placeholderLabel.sizeThatFits(CGSize(width: labelWidth, height: self.frame.size.height)).height
            placeholderLabel.frame = CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)
        }
    }
    
    private func addPlaceholder(_ placeholderText: String?) {
        guard let placeholderText = placeholderText else {
            return
        }
        self.delegate = self
        let placeholderLabel = UILabel()
        placeholderLabel.text = placeholderText
        placeholderLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        placeholderLabel.textColor = placeholderColor ?? UIColor.lightGray
        placeholderLabel.tag = Keys.viewTagPlaceholder
        placeholderLabel.isHidden = !self.text.isEmpty
        self.addSubview(placeholderLabel)
        self.resizePlaceholder()
    }
}

extension String {
    func replace(string:String, replacement:String) -> String {
        return self.replacingOccurrences(of: string, with: replacement, options: NSString.CompareOptions.literal, range: nil)
    }
    
    func removeWhitespace() -> String {
        return self.replace(string: " ", replacement: "")
    }
    
    func containsOnlyLettersAndWhitespace() -> Bool {
        let allowed = CharacterSet.letters.union(.whitespaces)
        return unicodeScalars.allSatisfy(allowed.contains)
    }
    
    func checkUserId()-> Bool{
        let stringrange = self.range(of: UIViewController.regexUserID, options: .regularExpression, range: nil, locale: nil )
        if stringrange != nil { return true }
        return false
    }
    
    func translated() -> String {
        if let path = Bundle.main.path(forResource: LocalizeUserDefautLanguage, ofType: "en"), let bundle = Bundle(path: path) {
            return NSLocalizedString(self, bundle: bundle,  comment: "")
        }
        return ""
    }
    
}

extension Formatter {
    static let withSeparator: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()
}
extension Numeric {
    var formattedWithSeparator: String { Formatter.withSeparator.string(for: self) ?? "" }
}

extension UILabel {
    func underline() {
        if let textString = self.text {
          let attributedString = NSMutableAttributedString(string: textString)
            attributedString.addAttribute(NSAttributedString.Key.underlineStyle,
                                          value: NSUnderlineStyle.single.rawValue,
                                          range: NSRange(location: 0, length: attributedString.length))
          attributedText = attributedString
        }
    }
}
