import UIKit
import SwiftUI
import Localize_Swift

struct AlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct MainFeatureItem: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let imageName: String
}

struct DocTypeChoiceItem: Identifiable {
    let id = UUID()
    let title: String
    let action: () -> Void
}

struct LegacyFlowDestination: Identifiable {
    let id = UUID()
    let build: () -> UIViewController
}

final class MainSwiftUIViewModel: ObservableObject {
    @Published var features: [MainFeatureItem] = []
    @Published var dataStorage: [DataStorageModel] = []
    @Published var selectedStorageIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var alert: AlertMessage?
    @Published var flowDestination: LegacyFlowDestination?
    @Published var docTypeChoices: [DocTypeChoiceItem] = []

    let role: TypeRole
    let userName: String
    let userCode: String

    var dataDocType: DocTypeModel?
    let networkManager = NetworkManager()
    weak var router: AppLaunchRouter?

    init(role: TypeRole, router: AppLaunchRouter) {
        self.role = role
        self.router = router
        self.userName = UserDefault.shared.getDataLoginModel().username ?? ""
        self.userCode = UserDefault.shared.getUserID()
        features = Self.buildFeatures(for: role)
    }

    func onAppear() {
        if role == .pcb || role == .mc {
            getStorageRequest()
        } else {
            getDocType()
        }
    }

    func clearPresentedFlow() {
        flowDestination = nil
    }

    func clearDocTypeChoices() {
        docTypeChoices = []
    }
}

struct LegacyRootControllerHost: UIViewControllerRepresentable {
    let build: () -> UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        build()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
