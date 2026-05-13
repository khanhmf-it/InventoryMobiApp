//
//  UIFont.swift
//  BIVN
//
//  Created by Luyện Đào on 01/12/2023.
//

import UIKit

let fontUtils = FontUtils()

@objc class FontType: NSObject {
    let size: CGFloat
    
    init(size: CGFloat) {
        self.size = size
    }
    
    private(set) lazy var bold: UIFont = {
        guard let font = UIFont(name: "Roboto-Bold", size: self.size) else {
            return UIFont.systemFont(ofSize: self.size)
        }
        return font
    }()
    
    private(set) lazy var regular: UIFont = {
        guard let font = UIFont(name: "Roboto-Regular", size: self.size) else {
            return UIFont.systemFont(ofSize: self.size)
        }
        return font
    }()
    
    private(set) lazy var medium: UIFont = {
        guard let font = UIFont(name: "Roboto-Medium", size: self.size) else {
            return UIFont.systemFont(ofSize: self.size)
        }
        return font
    }()
}

@objc class FontUtils: NSObject {
    fileprivate override init() {
        super.init()
    }
    
    // support objc
    @objc class func sharedInstance() -> FontUtils {
        return fontUtils
    }
    private(set) lazy var size9: FontType = {
        return FontType(size: 9)
    }()
    private(set) lazy var size12: FontType = {
        return FontType(size: 12)
    }()
    
    private(set) lazy var size14: FontType = {
        return FontType(size: 14)
    }()
    
    private(set) lazy var size16: FontType = {
        return FontType(size: 16)
    }()
    
    private(set) lazy var size18: FontType = {
        return FontType(size: 18)
    }()
    
    private(set) lazy var size24: FontType = {
        return FontType(size: 24)
    }()
    
    private(set) lazy var size32: FontType = {
        return FontType(size: 32)
    }()
}
