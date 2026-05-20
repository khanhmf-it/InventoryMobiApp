//
//  NetworkManager.swift
//  BIVN
//
//  Created by Luyện Đào on 12/09/2023.
//

import Foundation
import Moya
import Alamofire

class DefaultAlamofireSession: Alamofire.Session {
    static let shared: DefaultAlamofireSession = {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.timeoutIntervalForRequest = 10 // as seconds, you can set your request timeout
        configuration.timeoutIntervalForResource = 10 // as seconds, you can set your resource timeout
        configuration.requestCachePolicy = .useProtocolCachePolicy
        return DefaultAlamofireSession(configuration: configuration)
    }()
}

protocol Networkable {
    associatedtype T: TargetType
    var provider: MoyaProvider<T> { get }
    func fetchUserDetail(completion: @escaping (Result<[User], Error>) -> ())
}

 class NetworkManager: Networkable {
    static var shared: NetworkManager = NetworkManager()
     
    var provider = MoyaProvider<API>(session: DefaultAlamofireSession.shared, plugins: [NetworkLoggerPlugin()])
    func fetchUserDetail(completion: @escaping (Result<[User], Error>) -> ()) {
        request(target: .userDetail, completion: completion)
    }
    
    func loginPostRequest(isOverride: Bool = false, param: Dictionary<String, Any>, completion: @escaping (Result<LoginModel, Error>) -> ()) {
        request(target: isOverride ? .loginOverride(params: param) : .login(params: param), completion: completion)
    }
     
    func refreshToken(param: Dictionary<String, Any>, completion: @escaping (Result<RefreshTokenModel, Error>) -> ()) {
        request(target: .refreshToken(params: param), completion: completion)
    }
    
    func logoutDeleteRequest(param: Dictionary<String, Any>, completion: @escaping (Result<LogoutModel, Error>) -> ()) {
        request(target: .logout(params: param), completion: completion)
    }
    
    func getStorage(completion: @escaping (Result<StorageModel, Error>) -> ()) {
        request(target: .getStorage, completion: completion)
    }
    
    func getPosition(layout: String, componentCode: String, completion: @escaping (Result<PositionModel, Error>) -> ()) {
        request(target: .getPosition(layout: layout, componentCode: componentCode), completion: completion)
    }
    
    func postInputStorage(param: Dictionary<String, Any>,completion: @escaping (Result<InputStorageModel, Error>) -> ()) {
        request(target: .inputStorage(params: param), completion: completion)
    }
    
    func postOutputStorage(param: Dictionary<String, Any>,completion: @escaping (Result<InputStorageModel, Error>) -> ()) {
        request(target: .outputStorage(params: param), completion: completion)
    }
    
    func getListDropdownModel(inventoryId: String, accountId: String, completion: @escaping (Result<DropdownModel, Error>) -> ()) {
        request(target: .getListDropdownModel(inventoryId: inventoryId, accountId: accountId), completion: completion)
    }
     
    func getListDropdownModelB(inventoryId: String, accountId: String, completion: @escaping (Result<DropdownModel, Error>) -> ()) {
        request(target: .getListDropdownModelB(inventoryId: inventoryId, accountId: accountId), completion: completion)
    }
    
    func getListDropdownMachines(inventoryId: String, accountId: String, modelCode: String, completion: @escaping (Result<DropdownMachine, Error>) -> ()) {
        request(target: .getListDropdownMachines(inventoryId: inventoryId, accountId: accountId, modelCode: modelCode), completion: completion)
    }
     
    func getListDropdownMachinesB(inventoryId: String, accountId: String, modelCode: String, completion: @escaping (Result<DropdownMachine, Error>) -> ()) {
        request(target: .getListDropdownMachinesB(inventoryId: inventoryId, accountId: accountId, modelCode: modelCode), completion: completion)
    }
    
    func getListDropdownModelCodeB(inventoryId: String, accountId: String, machineModel: String, machineType: String, completion: @escaping (Result<DropdownModelCode, Error>) -> ()) {
        request(target: .getListDropdownModelCodeB(inventoryId: inventoryId, accountId: accountId, machineModel: machineModel, machineType: machineType), completion: completion)
    }

     func getListDropdownLinesB(inventoryId: String, accountId: String, machineModel: String, machineType: String, modelCode: String, completion: @escaping (Result<DropdownMachine, Error>) -> ()) {
         request(target: .getlistLinesB(inventoryId: inventoryId, accountId: accountId, machineModel: machineModel, machineType: machineType, modelCode: modelCode), completion: completion)
    }

    func getListDropdownLines(inventoryId: String, accountId: String, modelCode: String, machineType: String, completion: @escaping (Result<DropdownMachine, Error>) -> ()) {
        request(target: .getlistLines(inventoryId: inventoryId, accountId: accountId, modelCode: modelCode, machineType: machineType), completion: completion)
    }
    
    func getListdocB(param: Dictionary<String, Any>, completion: @escaping (Result<DocBModel, Error>) -> ()) {
        request(target: .getListdocB(params: param), completion: completion)
    }

    func getListdocAE(param: Dictionary<String, Any>, completion: @escaping (Result<DocAEModel, Error>) -> ()) {
        request(target: .getListdocAE(params: param), completion: completion)
    }

     func scanDocB(isErrorInvestigation: Bool, param: Dictionary<String, Any>, completion: @escaping (Result<DetailTicketModel, Error>) -> ()) {
         request(target: .scanDocB(isErrorInvestigation: isErrorInvestigation, params: param), completion: completion)
    }

     func scanListDocC(param: Dictionary<String, Any>, completion: @escaping (Result<DocCModel, Error>) -> ()) {
         request(target: .scanListDocC(params: param), completion: completion)
     }

    func getListdocC(param: Dictionary<String, Any>, completion: @escaping (Result<DocCModel, Error>) -> ()) {
        request(target: .getListdocC(params: param), completion: completion)
    }
    
    func getListDropdownDepartment(inventoryId: String, accountId: String, completion: @escaping (Result<DropdownModel, Error>) -> ()) {
        request(target: .getListDropdownDepartment(inventoryId: inventoryId, accountId: accountId), completion: completion)
    }
    
    func getListDropdownLocation(inventoryId: String, accountId: String, departmentName: String, completion: @escaping (Result<DropdownModel, Error>) -> ()) {
        request(target: .getListDropdownLocation(inventoryId: inventoryId, accountId: accountId, departmentName: departmentName), completion: completion)
    }
    
    func getListDropdownComponent(inventoryId: String, accountId: String, departmentName: String , locationName: String, completion: @escaping (Result<DropdownModel, Error>) -> ()) {
        request(target: .getListDropdownComponent(inventoryId: inventoryId, accountId: accountId, departmentName: departmentName, locationName: locationName), completion: completion)
    }
    
    func getListAudit(param: Dictionary<String, Any>, completion: @escaping (Result<AuditModel, Error>) -> ()) {
        request(target: .getListAudit(params: param), completion: completion)
    }
    func getListParCode(inventoryId: String, accountId: String, documentId: String, actionId: String, param: Dictionary<String, Any>, completion: @escaping (Result<PartCodeModel, Error>) -> ()) {
        request(target: .getListParCode(inventoryId: inventoryId, accountId: accountId, documentId: documentId, action: actionId, params: param), completion: completion)
    }
    
    func submitInventory(userCode: String,inventoryId: String, accountId: String, documentId: String, containerModel: [DocComponentABEs], docTypeCModel: [DocComponentCs], image: Data, isCheckPushImage: Bool, isCheckDocC: Bool, idsDeleteDocOutPut: [String], completion: @escaping (Result<ResponseSubmitModel, Error>) -> ()) {
        request(target: .submitInventory(userCode: userCode,inventoryId: inventoryId, accountId: accountId, documentId: documentId, containerModel: containerModel, docTypeCModel: docTypeCModel, image: image, isCheckPushImage: isCheckPushImage, isCheckPushDocC: isCheckDocC, idsDeleteDocOutPut: idsDeleteDocOutPut), completion: completion)
    }
    
     func getDetailTicket(inventoryId: String, accountId: String, componentCode: String, isConfirm: Bool, param: Dictionary<String, Any>, completion: @escaping (Result<DetailTicketModel, Error>) -> ()) {
        request(target: .getDetailTicket(inventoryId: inventoryId, accountId: accountId, componentCode: componentCode, isConfirm: isConfirm, params: param), completion: completion)
    }
    
    func getInventoryHistoryDetail(inventoryId: String, accountId: String, historyId: String, param: Dictionary<String, Any>, completion: @escaping (Result<InventoryHistoryModel, Error>) -> ()) {
        request(target: .getInventoryHistoryDetail(inventoryId: inventoryId, accountId: accountId, historyId: historyId, params: param), completion: completion)
    }
    
    func getDocType(inventoryId: String, accountId: String, completion: @escaping (Result<DocTypeModel, Error>) -> ()){
        request(target: .getDocType(inventoryId: inventoryId, accountId: accountId), completion: completion)
    }
    
    func getDetailSheetsMonitor(inventoryId: String, accountId: String, documentId: String, actionType: Int, completion: @escaping (Result<PartCodeModel, Error>) -> ()){
        request(target: .getDetailSheetsMonitor(inventoryId: inventoryId, accountId: accountId, documentId: documentId, actionType: actionType), completion: completion)
    }
    
    func submitAudit(userCode: String, comment: String, inventoryId: String, accountId: String, documentId: String, containerModel: [DocComponentABEs], deleteDocOutPut: [String], actionType: Int, completion: @escaping (Result<ResponseSubmitModel, Error>) -> ()) {
        request(target: .submitAudit(userCode: userCode, comment: comment,inventoryId: inventoryId, accountId: accountId, documentId: documentId, actionType: actionType, containerModel: containerModel, deleteDocOutPut: deleteDocOutPut), completion: completion)
    }
    
    func getHistoryDetail(inventoryId: String, accountId: String, historyId: String, param: Dictionary<String, Any>, completion: @escaping (Result<DetailHistoryModel, Error>) -> ()){
        request(target: .getHistoryDetail(inventoryId: inventoryId, accountId: accountId, historyId: historyId, params: param), completion: completion)
    }
    
    func submitTicketCDoc(userCode: String, comment: String, actionType: String, inventoryId: String, accountId: String, documentId: String, containerModel: [DocComponentABEs], docTypeCModel: [DocComponentCs], image: Data, isCheckPushImage: Bool, idsDeleteDocOutPut: [String], completion: @escaping (Result<ResponseSubmitModel, Error>) -> ()) {
        request(target: .submitTicketCDoc(userCode: userCode, comment: comment, inventoryId: inventoryId, accountId: accountId, documentId: documentId, actionType: actionType, containerModel: containerModel, docTypeCModel: docTypeCModel, image: image, isCheckPushImage: isCheckPushImage, idsDeleteDocOutPut: idsDeleteDocOutPut), completion: completion)
    }
    
    func getDetailMonitor(inventoryId: String, accountId: String, componentCode: String, completion: @escaping (Result<AuditCondensedModel, Error>) -> ()) {
        request(target: .getDetailMonitor(inventoryId: inventoryId, accountId: accountId, componentCode: componentCode), completion: completion)
    }
     
     func getHightlight(param: Dictionary<String, Any>, completion: @escaping (Result<HightLightTicketC, Error>) -> ()){
         request(target: .getHightlight(params: param), completion: completion)
     }
     func getInvestigationDetail(inventoryID: String, componentCode: String, params: Dictionary<String, Any>, completion: @escaping(Result<AccessoryModels, Error>)-> ()){
         request(target: .getInvestigationDetail(inventoryID: inventoryID, componentCode: componentCode, params : params), completion: completion)
     }
     func getListError(inventoryId: String, param: Dictionary<String, Any>, completion: @escaping (Result<ListErrorModel, Error>) -> ()) {
         request(target: .getListErrorTotal(inventoryId: inventoryId, params: param),completion: completion)
     }
     func getViewDetailError(inventoryId: String, componentCode: String, completion: @escaping (Result<ViewDetailModel, Error>) -> ()) {
         request(target: .getViewDetailError(inventoryId: inventoryId, componentCode: componentCode),completion: completion)
     }
     
     func submitErrorCorrection(inventoryId: String, componentCode: String, type: Int, quantity: Double, errorCategory: Int, errorDetails: String, confirmationImage1: Data, confirmationImage2: Data, isDeleteImage1: Bool, isDeleteImage2: Bool, userCode: String, completion: @escaping (Result<ResponseSubmitModel, Error>) -> ()) {
         request(target: .submitErrorCorrection(inventoryId: inventoryId, componentCode: componentCode, type: type, quantity: quantity, errorCategory: errorCategory, errorDetails: errorDetails, confirmationImage1: confirmationImage1, confirmationImage2: confirmationImage2 , isDeleteImage1: isDeleteImage1, isDeleteImage2: isDeleteImage2, userCode: userCode), completion: completion)
     }
     
     func getHistoryInvestigation(inventoryId: String, componentCode: String, completion: @escaping (Result<HistoryAccessoryModels, Error>) -> ()){
         request(target: .getHistoryInvestigation(inventoryId: inventoryId, componentCode: componentCode), completion: completion)
     }
     
     func updateStatus(inventoryId: String, componentCode: String, completion: @escaping (Result<StatusModel, Error>) -> ()){
         request(target: .updateStatus(inventoryId: inventoryId, componentCode: componentCode), completion: completion)
     }
     
     func documentCheck(inventoryId: String, componentCode: String,param: Dictionary<String, Any>, completion: @escaping (Result<StatusModel, Error>) -> ()){
         request(target: .documentCheck(inventoryId: inventoryId, componentCode: componentCode, params: param), completion: completion)
     }
     
     func errorCategory(completion: @escaping (Result<ErrorCategoryModel, Error>) -> ()) {
         request(target: .errorCategory, completion: completion)
     }
}

private extension NetworkManager {
    private func request<T: Decodable>(target: API, completion: @escaping (Result<T, Error>) -> ()) {
        provider.request(target) { result in
            switch result {
            case let .success(response):
                do {
                    let results = try JSONDecoder().decode(T.self, from: response.data)
                    completion(.success(results))
                } catch let error {
                    if let jsonString = String(data: response.data, encoding: .utf8) {
                        print("Failed to decode JSON:")
                        print(jsonString)
                    } else {
                        print("Failed to decode JSON: Unable to convert data to String.")
                    }
                    print("Decode error: \(error.localizedDescription)")
                    
                    completion(.failure(error))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
