//
//  BaseApi.swift
//  BIVN
//
//  Created by Luyện Đào on 12/09/2023.
//

import Foundation
import Moya
import Alamofire


enum API {
    case userDetail
    case login(params: Dictionary<String, Any>)
    case loginOverride(params: Dictionary<String, Any>)
    case refreshToken(params: Dictionary<String, Any>)
    case logout(params: Dictionary<String, Any>)
    case getStorage
    case getPosition(layout: String, componentCode: String)
    case inputStorage(params: Dictionary<String, Any>)
    case outputStorage(params: Dictionary<String, Any>)
    case getListDropdownModel(inventoryId: String, accountId: String)
    case getListDropdownModelB(inventoryId: String, accountId: String)
    case getListDropdownMachines(inventoryId: String, accountId: String, modelCode: String)
    case getListDropdownMachinesB(inventoryId: String, accountId: String, modelCode: String)
    case getListDropdownModelCodeB(inventoryId: String, accountId: String, machineModel: String, machineType: String)
    case getlistLinesB(inventoryId: String, accountId: String, machineModel: String, machineType: String, modelCode: String)
    case getlistLines(inventoryId: String, accountId: String, modelCode: String, machineType: String)
    case getListdocB(params: Dictionary<String, Any>)
    case getListdocAE(params: Dictionary<String, Any>)
    case scanDocB(isErrorInvestigation: Bool, params: Dictionary<String, Any>)
    case scanListDocC(params: Dictionary<String, Any>)
    case getListdocC(params: Dictionary<String, Any>)
    case getListDropdownDepartment(inventoryId: String, accountId: String)
    case getListDropdownLocation(inventoryId: String, accountId: String, departmentName: String)
    case getListDropdownComponent(inventoryId: String, accountId: String, departmentName: String, locationName: String)
    case getListAudit(params: Dictionary<String, Any>)
    case getListParCode(inventoryId: String, accountId: String, documentId: String, action: String, params: Dictionary<String, Any>)
    case submitInventory(userCode: String, inventoryId: String, accountId: String, documentId: String,containerModel: [DocComponentABEs], docTypeCModel: [DocComponentCs], image: Data, isCheckPushImage: Bool, isCheckPushDocC: Bool, idsDeleteDocOutPut: [String])
    case getDetailTicket(inventoryId: String, accountId: String, componentCode: String, isConfirm: Bool, params: Dictionary<String, Any>)
    case getInventoryHistoryDetail(inventoryId: String, accountId: String, historyId: String, params: Dictionary<String, Any>)
    case getDocType(inventoryId : String, accountId: String)
    case getDetailSheetsMonitor(inventoryId : String, accountId: String, documentId : String, actionType: Int)
    case submitAudit(userCode: String, comment: String, inventoryId: String, accountId: String, documentId: String, actionType: Int, containerModel: [DocComponentABEs], deleteDocOutPut: [String])
    case getHistoryDetail(inventoryId : String, accountId: String, historyId : String, params: Dictionary<String, Any>)
    case submitTicketCDoc(userCode: String, comment: String, inventoryId: String, accountId: String, documentId: String, actionType: String, containerModel: [DocComponentABEs], docTypeCModel: [DocComponentCs], image: Data, isCheckPushImage: Bool, idsDeleteDocOutPut: [String])
    case getDetailMonitor(inventoryId: String, accountId: String, componentCode: String)
    case getHightlight(params: Dictionary<String, Any>)
    case getInvestigationDetail(inventoryID: String, componentCode: String, params: Dictionary<String, Any>)
    case getListErrorTotal(inventoryId: String, params: Dictionary<String, Any>)
    case getViewDetailError(inventoryId: String, componentCode: String)
    case submitErrorCorrection(inventoryId: String,componentCode: String, type: Int, quantity: Double, errorCategory: Int, errorDetails: String, confirmationImage1: Data, confirmationImage2: Data, isDeleteImage1: Bool, isDeleteImage2: Bool,userCode: String)
    case getHistoryInvestigation(inventoryId: String, componentCode: String)
    case updateStatus(inventoryId: String, componentCode: String)
    case errorCategory
    case documentCheck(inventoryId: String, componentCode: String, params: Dictionary<String, Any>)
}
extension API: TargetType {
    var headers: [String : String]? {
        let tokenValue: String = UserDefault.shared.getDataLoginModel().token ?? ""
        switch self {
        case .loginOverride:
            return  [
                "Authorization" : "Bearer \(tokenValue)",
                "deviceId" : UIDevice.current.identifierForVendor?.uuidString ?? "",
                "allowOverrideLoginPersonalAccount" : "YES",
            ]
        case .login:
            return nil
        default:
            return  [
                "Authorization" : "Bearer \(tokenValue)",
                "deviceId" : UIDevice.current.identifierForVendor?.uuidString ?? "",
            ]
        }
    }
    
    var baseURL: URL {
        var url: URL?
        let userName = UserDefaults.standard.string(forKey: "userNameLogin")
        let nameWifi = UserDefaults.standard.string(forKey: "nameWifi")
        if Environment.rootURL.description.contains("192.168.50.152:9121") {
            url = Environment.rootURL
        } else {
            if userName == "user_perform" {
                url = URL(string: "http://14.160.64.50:9121")
            } else {
                if nameWifi == "bivnioswifim01" {
                    url = URL(string: "http://172.26.248.26/gateway_inv_test")
                } else if nameWifi == "B-WINS" {
                    url = Environment.rootURL
                } else {
                    url = Environment.rootURL
                }
            }
        }
        return url ?? URL(string: "")!
    }
    
    var path: String {
        switch self {
        case .userDetail:
            return "todos/"
        case .login, .loginOverride:
            return "/api/identity/login"
        case .logout:
            return "api/identity/logout"
        case .getStorage:
            return "api/storage"
        case .getPosition(let layout, let componentCode):
            return "api/storage/\(layout)/component/\(componentCode)/info"
        case .inputStorage:
            return "api/storage/input"
        case .outputStorage:
            return "api/storage/output"
        case .getListDropdownModel(let inventoryId, let accountId):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/doc-c/dropdown/models"
        case .getListDropdownModelB(let inventoryId, let accountId):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/doc-b/dropdown/models"
        case .getListDropdownMachines(let inventoryId, let accountId, let modelCode):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/doc-c/dropdown/\(modelCode)/machines"
        case .getListDropdownMachinesB(let inventoryId, let accountId, let modelCode):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/doc-b/dropdown/\(modelCode)/machines"
        case .getListDropdownModelCodeB(inventoryId: let inventoryId, accountId: let accountId, machineModel: let machineModel, machineType: let machineType):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/doc-b/dropdown/\(machineModel)/machines/\(machineType)/modelcodes"
        case .getlistLinesB(inventoryId: let inventoryId, accountId: let accountId, machineModel: let machineModel, machineType: let machineType, modelCode: let modelCode):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/doc-b/dropdown/\(machineModel)/machines/\(machineType)/modelcodes/\(modelCode)"
        case .getlistLines(inventoryId: let inventoryId, accountId: let accountId, modelCode: let modelCode, machineType: let machineType):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/doc-c/dropdown/\(modelCode)/machines/\(machineType)/lines"
        case .getListdocB:
            return "/api/inventory/doc-b"
        case .getListdocAE:
            return "/api/inventory/doc-ae"
        case .scanDocB:
            return "/api/inventory/scan/doc-b"
        case .scanListDocC:
            return "/api/inventory/list/doc-c"
        case .getListdocC:
            return "/api/inventory/doc-c"
        case .refreshToken:
            return "/api/identity/refresh-token"
        case .getListDropdownDepartment(let inventoryId, let accountId):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/dropdown/department"
        case .getListDropdownLocation(let inventoryId, let accountId, let departmentName):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/dropdown/department/\(departmentName)/location"
        case .getListDropdownComponent(let inventoryId, let accountId, let departmentName, let locationName):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/dropdown/department/\(departmentName)/location/\(locationName)/component"
        case .getListAudit:
            return "/api/inventory/list-audit"
        case .getListParCode(let inventoryId, let accountId, let documentId, let action, _):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/document/\(documentId)/action/\(action)"
        case .submitInventory(_,let inventoryId, let accountId, let documentId, _,_,_,_,_,_):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/document/\(documentId)/submit-inventory"
        case .getDetailTicket(let inventoryId, let accountId, let componentCode, let isConfirm, _):
            return "/api/inventory/\(inventoryId)/doc-ae/account/\(accountId)/code/\(componentCode)/action/\(isConfirm ? 1 : 0)/"
        case .getInventoryHistoryDetail(let inventoryId, let accountId, let historyId,_):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/history/\(historyId)"
        case .getDocType(let inventoryId, let accountId):
            return "api/inventory/\(inventoryId)/account/\(accountId)/inventory-check"
        case .getDetailSheetsMonitor(let inventoryId, let accountId, let documentId, let actionType):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/document/\(documentId)/action/\(actionType)"
        case .submitAudit(_, _, let inventoryId, let accountId, let documentId, let actionType, _, _):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/document/\(documentId)/action/\(actionType)/submit-audit"
        case .getHistoryDetail(let inventoryId, let accountId, let historyId, _):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/history/\(historyId)"
        case .submitTicketCDoc(_,_,let inventoryId, let accountId, let documentId, let actionType,_,_,_,_,_):
            return "/api/inventory/\(inventoryId)/account/\(accountId)/document/\(documentId)/action/\(actionType)/submit-confirm"
        case .getDetailMonitor(let inventoryId, let accountId, let componentCode):
            return "api/inventory/\(inventoryId)/account/\(accountId)/audit/scan/\(componentCode)"
        case .getHightlight:
            return "api/inventory/ishightlight-check"
        case .getInvestigationDetail(let inventoryID, let componentCode, _):
            return "api/error-investigation/inventory/\(inventoryID)/componentCode/\(componentCode)/documents"
        case .getListErrorTotal(let inventoryId, _):
            return "/api/error-investigation/inventory/\(inventoryId)"
        case .getViewDetailError(inventoryId: let inventoryId, componentCode: let componentCode):
            return "/api/error-investigation/inventory/\(inventoryId)/componentCode/\(componentCode)/view-detail"
        case .submitErrorCorrection(let inventoryId, let componentCode, let type,_,_,_,_,_,_,_,_):
            return "/api/error-investigation/inventory/\(inventoryId)/componentCode/\(componentCode)/type/\(type)"
        case .getHistoryInvestigation(let inventoryId, let componentCode):
            return "/api/error-investigation/inventory/\(inventoryId)/componentCode/\(componentCode)/histories"
        case .updateStatus(let inventoryId, let componentCode):
            return "/api/error-investigation/inventory/\(inventoryId)/componentCode/\(componentCode)/status"
        case .documentCheck(let inventoryId, let componentCode, _):
            return "/api/error-investigation/web/inventory/\(inventoryId)/componentCode/\(componentCode)/documents-check"
        case .errorCategory:
            return "/api/error-investigation/web/management/error-category"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case.login, .loginOverride, .inputStorage, .outputStorage, .getHightlight:
            return .post
        case .logout:
            return .post
        case .getStorage, .getPosition, .getDocType, .getInvestigationDetail:
            return .get
        case .getListdocC, .getListAudit, .getListdocB, .scanDocB, .getListdocAE, .scanListDocC, .refreshToken:
            return .post
        case .submitInventory, .submitAudit, .submitTicketCDoc, .submitErrorCorrection:
            return .post
        case .updateStatus:
            return .put
        default:
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .scanDocB(let isErrorInvestigation, let params):
                return .requestCompositeParameters(
                    bodyParameters: params,
                    bodyEncoding: JSONEncoding.default,
                    urlParameters: [
                        "isErrorInvestigation": isErrorInvestigation ? "true" : "false"
                    ]
                )
        case .userDetail, .getPosition, .getListDropdownModel, .getListDropdownModelB, .getListDropdownMachines, .getListDropdownMachinesB, .getListDropdownModelCodeB, .getlistLines, .getlistLinesB, .getListDropdownDepartment, .getListDropdownLocation, .getListDropdownComponent, .getDocType, .getDetailSheetsMonitor, .getDetailMonitor, .getHistoryInvestigation, .updateStatus:
            return .requestPlain
        case .login(let params), .loginOverride(let params):
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .logout(let params):
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .inputStorage(let params):
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .outputStorage(let params):
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .getListdocC(let params), .getListAudit(let params), .getListdocB(let params), .getListdocAE(let params), .scanListDocC(let params), .refreshToken(let params):
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .getStorage, .errorCategory:
            return .requestPlain
        case .getInventoryHistoryDetail(_,_, _, let params), .getDetailTicket(_, _, _, _, let params), .getListErrorTotal(_,let params), .documentCheck(_,_,let params), .getInvestigationDetail(_,_,let params):
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .getHistoryDetail(_,_,_, let params):
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .getListParCode(_,_,_,_, let params):
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .submitInventory(let userCode,_,_,_, let containerModel, let docCModel,let image, let isCheckPushImage, let isCheckDocC, let idsDeleteDocOutPut):
            var formData: [Moya.MultipartFormData] = []
            if isCheckPushImage {
                formData.append(Moya.MultipartFormData(provider: .data(image), name: "image", fileName: "image.jpg", mimeType: "image/jpeg"))
            }
            formData.append(Moya.MultipartFormData(provider: .data(userCode.data(using: .utf8)!), name: "UserCode"))
            for (index, model) in containerModel.enumerated() {
                let keyPrefix = "DocOutputs[\(index)]"
                if let id = model.id {
                    formData.append(Moya.MultipartFormData(provider: .data(id.data(using: .utf8)!), name: "\(keyPrefix).Id"))
                }
                formData.append(Moya.MultipartFormData(provider: .data("\(model.quantityOfBom ?? 0)".data(using: .utf8)!), name: "\(keyPrefix).QuantityOfBom"))
                formData.append(Moya.MultipartFormData(provider: .data("\(model.quantityPerBom ?? 0)".data(using: .utf8)!), name: "\(keyPrefix).QuantityPerBom"))
            }
            
            if isCheckDocC {
                for (index, model) in docCModel.enumerated() {
                    let keyPrefix = "DocTypeCDetails[\(index)]"
                    if let id = model.id {
                        formData.append(Moya.MultipartFormData(provider: .data(id.data(using: .utf8)!), name: "\(keyPrefix).Id"))
                    }
                    if let componentCode = model.componentCode {
                        formData.append(Moya.MultipartFormData(provider: .data(componentCode.data(using: .utf8)!), name: "\(keyPrefix).ComponentCode"))
                    }
                    formData.append(Moya.MultipartFormData(provider: .data("\(model.quantityOfBom ?? 0)".data(using: .utf8)!), name: "\(keyPrefix).QuantityOfBom"))
                    formData.append(Moya.MultipartFormData(provider: .data("\(model.quantityPerBom ?? 0)".data(using: .utf8)!), name: "\(keyPrefix).QuantityPerBom"))
                }
            }
            if !idsDeleteDocOutPut.isEmpty {
                for (index, model) in idsDeleteDocOutPut.enumerated() {
                    let keyPrefix = "IdsDeleteDocOutPut[\(index)]"
                    formData.append(Moya.MultipartFormData(provider: .data(model.data(using: .utf8)!), name: "\(keyPrefix)"))
                }
            }
            return .uploadMultipart(formData)
        case .submitAudit(let userCode, let comment, _, _, _, _, let containerModel, let deleteDocOutPut):
            var formData: [Moya.MultipartFormData] = []
            formData.append(Moya.MultipartFormData(provider: .data(userCode.data(using: .utf8)!), name: "UserCode"))
            formData.append(Moya.MultipartFormData(provider: .data(comment.data(using: .utf8)!), name: "Comment"))
            for (index, model) in containerModel.enumerated() {
                let keyPrefix = "DocOutputs[\(index)]"
                if let id = model.id {
                    formData.append(Moya.MultipartFormData(provider: .data(id.data(using: .utf8)!), name: "\(keyPrefix).Id"))
                }
                formData.append(Moya.MultipartFormData(provider: .data("\(model.quantityOfBom ?? 0)".data(using: .utf8)!), name: "\(keyPrefix).QuantityOfBom"))
                formData.append(Moya.MultipartFormData(provider: .data("\(model.quantityPerBom ?? 0)".data(using: .utf8)!), name: "\(keyPrefix).QuantityPerBom"))
            }
            for (index, data) in deleteDocOutPut.enumerated() {
                let keyPrefix = "IdsDeleteDocOutPut[\(index)]"
                formData.append(Moya.MultipartFormData(provider: .data(data.data(using: .utf8)!), name: "\(keyPrefix)"))
            }
            return .uploadMultipart(formData)
        case .submitTicketCDoc(let userCode, let comment, _, _,_, _,let containerModel,let docTypeCModel, let image, let isCheckPushImage, let idsDeleteDocOutPut):
            var formData: [Moya.MultipartFormData] = []
            if isCheckPushImage {
                formData.append(Moya.MultipartFormData(provider: .data(image), name: "image", fileName: "image.jpg", mimeType: "image/jpeg"))
            }
            formData.append(Moya.MultipartFormData(provider: .data(userCode.data(using: .utf8)!), name: "UserCode"))
            formData.append(Moya.MultipartFormData(provider: .data(comment.data(using: .utf8)!), name: "Comment"))
            
            for (index, model) in containerModel.enumerated() {
                let keyPrefix = "DocOutputs[\(index)]"
                if let id = model.id {
                    formData.append(Moya.MultipartFormData(provider: .data(id.data(using: .utf8)!), name: "\(keyPrefix).Id"))
                }
                formData.append(Moya.MultipartFormData(provider: .data("\(model.quantityOfBom ?? 0)".data(using: .utf8)!), name: "\(keyPrefix).QuantityOfBom"))
                formData.append(Moya.MultipartFormData(provider: .data("\(model.quantityPerBom ?? 0)".data(using: .utf8)!), name: "\(keyPrefix).QuantityPerBom"))
            }
            
            if !idsDeleteDocOutPut.isEmpty {
                for (index, model) in idsDeleteDocOutPut.enumerated() {
                    let keyPrefix = "IdsDeleteDocOutPut[\(index)]"
                    formData.append(Moya.MultipartFormData(provider: .data(model.data(using: .utf8)!), name: "\(keyPrefix)"))
                }
            }
            
            for (index, model) in docTypeCModel.enumerated() {
                let keyPrefix = "DocTypeCDetails[\(index)]"
                if let id = model.id {
                    formData.append(Moya.MultipartFormData(provider: .data(id.data(using: .utf8)!), name: "\(keyPrefix).Id"))
                }
                if let componentCode = model.componentCode {
                    formData.append(Moya.MultipartFormData(provider: .data(componentCode.data(using: .utf8)!), name: "\(keyPrefix).ComponentCode"))
                }
                formData.append(Moya.MultipartFormData(provider: .data("\(model.quantityOfBom ?? 0)".data(using: .utf8)!), name: "\(keyPrefix).QuantityOfBom"))
                formData.append(Moya.MultipartFormData(provider: .data("\(model.quantityPerBom ?? 0)".data(using: .utf8)!), name: "\(keyPrefix).QuantityPerBom"))
            }
            return .uploadMultipart(formData)
        case .getHightlight(let params):
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .getViewDetailError(inventoryId: _, componentCode: _):
            return .requestPlain
        case .submitErrorCorrection(_,_,_, let quantity, let errorCategory, let errorDetails, let confirmationImage1, let confirmationImage2, let isDeleteImage1, let isDeleteImage2, let userCode):
            var formData: [Moya.MultipartFormData] = []
            let quantityString = String(quantity)
            let isDeleteImage1String = isDeleteImage1 ? "true" : "false"
            let isDeleteImage2String = isDeleteImage2 ? "true" : "false"
            let errorCategoryString = String(errorCategory)
            formData.append(Moya.MultipartFormData(provider: .data(quantityString.data(using: .utf8)!), name: "Quantity"))
            formData.append(Moya.MultipartFormData(provider: .data(errorCategoryString.data(using: .utf8)!), name: "ErrorCategory"))
            formData.append(Moya.MultipartFormData(provider: .data(errorDetails.data(using: .utf8)!), name: "ErrorDetails"))
            formData.append(Moya.MultipartFormData(provider: .data(userCode.data(using: .utf8)!), name: "UserCode"))
            formData.append(Moya.MultipartFormData(provider: .data(isDeleteImage1String.data(using: .utf8)!), name: "IsDeleteImage1"))
            formData.append(Moya.MultipartFormData(provider: .data(isDeleteImage2String.data(using: .utf8)!), name: "IsDeleteImage2"))
            if !confirmationImage1.isEmpty {
                    formData.append(Moya.MultipartFormData(provider: .data(confirmationImage1), name: "ConfirmationImage1", fileName: "ConfirmationImage1.jpg", mimeType: "image/jpeg"))
                }
            if !confirmationImage2.isEmpty {
                    formData.append(Moya.MultipartFormData(provider: .data(confirmationImage2), name: "ConfirmationImage2", fileName: "ConfirmationImage2.jpg", mimeType: "image/jpeg"))
                }
            
            formData.append(Moya.MultipartFormData(provider: .data(confirmationImage2), name: "ConfirmationImage2", fileName: "ConfirmationImage2.jpg", mimeType: "image/jpeg"))
            return .uploadMultipart(formData)
        }
    }
}
