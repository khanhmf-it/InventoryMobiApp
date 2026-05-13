//
//  Environment.swift
//  BIVN
//
//  Created by Luyện Đào on 07/11/2023.
//

import Foundation

enum Environment {
    private static let infoDict: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("plist is not found")
        }
        return dict
    }()
    
    
    static let rootURL: URL = {
        guard let urlString = Environment.infoDict["Root_URL"] as? String else {
            fatalError("Root_URL is not found")
        }
        
        guard let url = URL(string: urlString) else {
            fatalError("Root_URL is invalid")
        }
        return url
    }()
}
