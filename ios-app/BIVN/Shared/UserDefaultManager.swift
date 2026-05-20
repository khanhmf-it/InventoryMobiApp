//
//  UserDefault.swift
//  BIVN
//
//  Created by Tinhvan on 25/09/2023.
//

import Foundation
import Localize_Swift

class UserDefault {
    static let shared = UserDefault()
    private let USER_ID = "userID"
    private let MODEL = "MODEL"
    private let MACHINE = "MACHINE"
    private let LINE = "LINE"
    private let RELOAD = "RELOAD"
    
    private init() {
        
    }
    
    func getDataLoginModel() -> DataLoginModel {
        var dataLoginModel = DataLoginModel()
        
        if let dataLogin = UserDefaults.standard.object(forKey: "dataLoginModel") as? Data {
            if let modelLogin = try? JSONDecoder().decode(DataLoginModel.self, from: dataLogin) {
                //print("modelLogin: \(modelLogin)")
                dataLoginModel = modelLogin
            }
        }
        
        return dataLoginModel
    }
    
    func setUserID(userID : String){
        UserDefaults.standard.set(userID, forKey: USER_ID)
    }
    
    func getUserID() -> String{
        let userID = UserDefaults.standard.string(forKey: USER_ID)
        return userID ?? ""
    }
    
    func showErrorText(errorCode: Int) -> String {
        var errorString = ""
        switch errorCode {
        case 19:
            errorString = "Chữ ký của Token không hợp lệ".localized()
        case 20:
            errorString = "Mã nhân viên đã tồn tại. Vui lòng nhập lại.".localized()
        case 55:
            errorString = "Mã linh kiện đã tồn tại trong hệ thống".localized()
        case 56:
            errorString = "Vị trí cố định không thuộc nhà máy được phân quyền".localized()
        case 57:
            errorString = "Mã linh kiện hoặc tên linh kiện đã tồn tại trên hệ thống".localized()
        case 58:
            errorString = "Mã nhà cung cấp hoặc tên nhà cung cấp đã tồn tại trên hệ thống".localized()
        case 59:
            errorString = "Mã nhà cung cấp, vị trí cố định và mã linh kiện đã tồn tại trên hệ thống".localized()
        case 60:
            errorString = "Quyền truy cập của tài khoản đã thay đổi".localized()
        case 61:
            errorString = "Tồn kho nhỏ nhất đang lớn hơn tồn kho lớn nhất, vui lòng kiểm tra lại.".localized()
        case 62:
            errorString = "Tồn kho thực tế đang lớn hơn tồn kho lớn nhất, vui lòng kiểm tra lại.".localized()
        case 63:
            errorString = "Đã tồn tại vị trí cố định chứa mã linh kiện, vui lòng kiểm tra lại.".localized()
        case 77:
            errorString = "Mã linh kiện này không thuộc khu vực giám sát. Vui lòng thử lại.".localized()
        case 10:
            errorString = "Tài khoản của bạn đã bị khóa. Vui lòng liên hệ với quản lý để được trợ giúp.".localized()
        case 11:
            errorString = "Tài khoản của bạn đã bị khóa. Vui lòng liên hệ với quản lý để được trợ giúp.".localized()
        case 12:
            errorString = "Tài khoản của bạn đã bị khóa. Vui lòng liên hệ với quản lý để được trợ giúp.".localized()
        case 13:
            errorString = "Tài khoản không tồn tại trên hệ thống.Vui lòng thử lại.".localized()
        case 14:
            errorString = "Thông tin đăng nhập không đúng. Vui lòng liên hệ với quản lý để được trợ giúp.".localized()
        case 16:
            errorString = "Tài khoản không tồn tại trên hệ thống.Vui lòng thử lại.".localized()
        case 17, 18:
            errorString = "Vui lòng đăng nhập lại.".localized()
        case 50:
            errorString = "Mã linh kiện không đúng.Vui lòng nhập lại.".localized()
        case 51:
            errorString = "Lỗi \(errorCode)"
        case 52:
            errorString = "Vui lòng không xuất quá số lượng tồn.".localized()
        case 53:
            errorString = "Vui lòng không nhập kho quá sức chứa hiện tại.".localized()
        case 75:
            errorString = "Mã linh kiện này chưa được thực hiện xác nhận kiểm kê. Vui lòng thử lại".localized()
        case 80:
            errorString = "Mã linh kiện không tồn tại. Vui lòng thử lại.".localized()
        case 81:
            errorString = "Mã linh kiện này không nằm trong danh sách thực hiện kiểm kê của bạn. Vui lòng thử lại.".localized()
        case 83:
            errorString = "Mã linh kiện này chưa được thực hiện kiểm kê. Vui lòng thử lại".localized()
        case 43:
            errorString = "Tài khoản đăng nhập chưa được gán vai trò thao tác. Vui lòng liên hệ quản lý để gán vai trò cho tài khoản này.".localized()
        case 74:
            errorString = "Mã linh kiện này không nằm trong danh sách thực hiện giám sát kiểm kê của bạn. Vui lòng thử lại.".localized()
        case 404:
            errorString = "Không tìm thấy dữ liệu phù hợp.".localized()
        case 96:
            errorString = "Đợt kiểm kê đã bị khóa"
        case 76:
            errorString = "Mã linh kiện này không nằm trong danh sách giám sát. Vui lòng thử lại."
        case 100:
            errorString = "Mã linh kiện không có trên hệ thống. Vui lòng thử lại."
        case 64:
            errorString = "Bạn không thể thay đổi trạng thái của đợt kiểm kê do chưa đến thời gian kiếm kê"
        case 65:
            errorString = "Tài khoản chưa được assign vào phiếu kiểm kê".localized()
        case 101:
            errorString = "Không tìm thấy danh sách linh kiện điều tra sai số.".localized()
        case 102:
            errorString = "Đang trong thời gian kiểm kê.Không được thực hiện điều tra sai số.Vui lòng thử lại sau.".localized()
        case 103:
            errorString = "Không được điều chỉnh số lượng cùng dấu với số lượng sai số.".localized()
        case 104:
            errorString = "Điều chỉnh sai số đang có trạng thái khác trạng thái điều tra.".localized()
        case 105:
            errorString = "Điều chỉnh sai số đang có trạng thái là điều tra.".localized()
        case 106:
            errorString = "Linh kiện đang được điều tra sai số.".localized()
        case 107:
            errorString = "Số lượng điều chỉnh không được lớn hơn số lượng chênh lệch.".localized()
        case 108:
            errorString = "Linh kiện chưa có lịch sử điều tra.Vui lòng tiến hành điều tra sai số.".localized()
        case 113:
            errorString = "Mã linh kiện này chưa được kiểm kê hoặc đã được giám sát. Vui lòng thử lại.".localized()
        case 112:
            errorString = "Mã linh kiện này đã được giám sát. Không được thực hiện kiển kê và xác nhận lại.".localized()
        default:
            errorString = "Lỗi \(errorCode)"
        }
        return errorString
    }
    
    func showErrorTitle(errorCode: Int) -> String {
        var errorString = ""
        switch errorCode {
        case 10, 96:
            errorString = "Thông báo".localized()
        case 11:
            errorString = "Thông báo".localized()
        case 12:
            errorString = "Thông báo".localized()
        case 13:
            errorString = "Lỗi".localized()
        case 14:
            errorString = "Lỗi đăng nhập".localized()
        case 16:
            errorString = "Lỗi".localized()
        case 17, 18:
            errorString = "Phiên đã hết hạn".localized()
        case 50, 75, 80, 81, 83, 74, 404, 76:
            errorString = "Lỗi".localized()
        case 51:
            errorString = ""
        case 52:
            errorString = "Không đủ số lượng".localized()
        case 53:
            errorString = "Quá sức chứa".localized()
        default:
            errorString = "Thông báo".localized()
        }
        return errorString
    }
    
    func titleAccept(errorCode: Int) -> String {
        var titleAcceptButton = ""
        switch errorCode {
        case 10, 96:
            titleAcceptButton = "Đóng".localized()
        case 11:
            titleAcceptButton = "Đóng".localized()
        case 12:
            titleAcceptButton = "Đóng".localized()
        case 13:
            titleAcceptButton = "Đồng ý".localized()
        case 14:
            titleAcceptButton = "Đồng ý".localized()
        case 16:
            titleAcceptButton = "Đồng ý".localized()
        case 17, 18:
            titleAcceptButton = "OK"
        case 50, 75, 80, 81 , 83:
            titleAcceptButton = "Đồng ý".localized()
        case 51:
            titleAcceptButton = "Đóng".localized()
        case 52:
            titleAcceptButton = "Đóng".localized()
        case 53, 43:
            titleAcceptButton = "Đóng".localized()
        default:
            titleAcceptButton = "Đóng".localized()
        }
        return titleAcceptButton
    }
    
    func titleCancel(errorCode: Int) -> String {
        var title = ""
        switch errorCode {
        case 10:
            title = ""
        case 11:
            title = ""
        case 12:
            title = ""
        case 13:
            title = ""
        case 14:
            title = ""
        case 16:
            title = ""
        case 17:
            title = ""
        case 18:
            title = ""
        case 50:
            title = ""
        case 51:
            title = ""
        case 52:
            title = ""
        case 53:
            title = ""
        default:
            title = ""
        }
        return title
    }
    
    func setModel(model: String) {
        UserDefaults.standard.set(model, forKey: MODEL)
    }
    
    func setMachine(machine: String) {
        UserDefaults.standard.set(machine, forKey: MACHINE)
    }
    
    func setLine(line: String) {
        UserDefaults.standard.set(line, forKey: LINE)
    }
    
    func setReload(isReload: Bool) {
        UserDefaults.standard.set(isReload, forKey: RELOAD)
    }
    
    func getModel() -> String {
        let model = UserDefaults.standard.string(forKey: MODEL)
        return model ?? ""
    }
    
    func getMachine() -> String {
        let machine = UserDefaults.standard.string(forKey: MACHINE)
        return machine ?? ""
    }
    
    func getLine() -> String {
        let line = UserDefaults.standard.string(forKey: LINE)
        return line ?? ""
    }
    
    func getReload() -> Bool {
        let reload = UserDefaults.standard.bool(forKey: RELOAD)
        return reload
    }
    
    func removeModel() {
        UserDefaults.standard.removeObject(forKey: MODEL)
    }
    
    func removeMachine() {
        UserDefaults.standard.removeObject(forKey: MACHINE)
    }
    
    func removeLine() {
        UserDefaults.standard.removeObject(forKey: LINE)
    }
}
