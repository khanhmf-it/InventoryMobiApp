//
//  ErrorInvestigation.swift
//  BIVN
//
//  Created by TVO_M1 on 15/1/25.
//

enum ErrorInvestigation {
    case errorInventory
    case packaging
    case nonStatistical
    case unknownCause
    case wrongBOM
    case misuse
    case other
    var errorMessage: String {
        switch self {
        case .errorInventory:
            return "\("Kiểm kê sai".localized())"
        case .packaging:
            return "\("Quy cách đóng gói".localized())"
        case .nonStatistical:
            return "\("Lỗi không thống kê".localized())"
        case .unknownCause:
            return "\("Không rõ nguyên nhân".localized())"
        case .wrongBOM:
            return "\("BOM sai".localized())"
        case .other:
            return "\("khác".localized())"
        case .misuse:
            return "\("Dùng nhầm".localized())"
        }
    }
    
    var errorType: Int {
        switch self {
        case .errorInventory:
            return 0
        case .packaging:
            return 1
        case .nonStatistical:
            return 2
        case .unknownCause:
            return 3
        case .wrongBOM:
            return 4
        case .misuse:
            return 5
        case .other:
            return 6
        }
    }
    
    static func findError(type: Int) -> ErrorInvestigation? {
        return ErrorInvestigation.allCases.first { $0.errorType == type }
    }
}
extension ErrorInvestigation: CaseIterable {}
