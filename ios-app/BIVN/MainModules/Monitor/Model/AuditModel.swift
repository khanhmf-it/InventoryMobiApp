//


import Foundation

struct AuditModel: Codable {
    var message: String?
    var code: Int?
    var data: ArrayDataAudit?
}

struct AuditCondensedModel: Codable {
    var message: String?
    var code: Int?
    var data: [AuditInfoModels]?
}

struct ArrayDataAudit: Codable {
    var auditInfoModels: [AuditInfoModels]?
    var finishCount: Int?
    var totalCount: Int?
}

struct AuditInfoModels: Codable {
    var id: String?
    var inventoryId: String?
    var accountId: String?
    var status: Int?
    var departmentName: String?
    var locationName: String?
    var componentCode: String?
    var positionCode: String?
    func getStatusMonitor() -> String {
        switch status {
        case 0:
            return "Chưa tiếp nhận"
        case 1:
            return "Không kiểm kê"
        case 2:
            return "Chưa kiểm kê"
        case 3:
            return "Chờ xác nhận"
        case 4:
            return "Cần chỉnh sửa"
        case 5:
            return "Đã xác nhận"
        case 6:
            return "Đã đạt giám sát"
        case 7:
            return "Không đạt giám sát"
        default:
            return ""
        }
    }
    
    func getColorStatusMonitor() -> String {
        switch status {
        case 0:
            return R.color.textDarkBlue.name
        case 1:
            return R.color.textDefault.name
        case 2:
            return R.color.textGray.name
        case 3:
            return R.color.textYellow.name
        case 4:
            return R.color.textOrange.name
        case 5:
            return R.color.greenColor.name
        case 6:
            return R.color.textBlue.name
        case 7:
            return R.color.textRed.name
        default:
            return R.color.textDefault.name
        }
    }
}
