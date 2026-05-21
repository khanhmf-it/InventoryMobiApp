import UIKit
import SwiftUI
import Localize_Swift

struct MainSwiftUIView: View {
    @ObservedObject private var viewModel: MainSwiftUIViewModel
    @State private var showMenu = false

    init(role: TypeRole, router: AppLaunchRouter) {
        viewModel = MainSwiftUIViewModel(role: role, router: router)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.features.enumerated()), id: \.offset) { index, item in
                            Button(action: {
                                viewModel.didSelectFeature(index: index)
                            }) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(item.imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 32, height: 32)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.title)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color(UIColor(named: R.color.textDefault.name) ?? .black))
                                        Text(item.content)
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(UIColor.darkGray))
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                }
                                .padding(14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.18), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
                .background(Color(UIColor.systemGroupedBackground))
            }

            if showMenu {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showMenu = false
                        }
                    }
            }

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(viewModel.userName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(viewModel.userCode)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                    Divider().overlay(Color.white.opacity(0.4))
                    Button(action: {
                        showMenu = false
                        viewModel.logout()
                    }) {
                        HStack(spacing: 10) {
                            Image(R.image.ic_logout.name)
                            Text("Đăng xuất".localized())
                                .foregroundColor(.white)
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                    Spacer()
                }
                .padding(20)
                .frame(width: UIScreen.main.bounds.width * 0.72, alignment: .leading)
                .background(Color(UIColor(named: R.color.buttonBlue.name) ?? .systemBlue))

                Spacer(minLength: 0)
            }
            .offset(x: showMenu ? 0 : -(UIScreen.main.bounds.width * 0.72))
            .animation(.easeOut(duration: 0.2), value: showMenu)

            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.1)
                        .padding(20)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            viewModel.onAppear()
        }
        .alert(item: $viewModel.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("Đồng ý".localized())))
        }
        .confirmationDialog("Chọn loại phiếu".localized(), isPresented: Binding(
            get: { !viewModel.docTypeChoices.isEmpty },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearDocTypeChoices()
                }
            }
        ), titleVisibility: .visible) {
            ForEach(viewModel.docTypeChoices) { item in
                Button(item.title) {
                    viewModel.clearDocTypeChoices()
                    item.action()
                }
            }
            Button("Hủy".localized(), role: .cancel) {
                viewModel.clearDocTypeChoices()
            }
        }
        .fullScreenCover(item: $viewModel.flowDestination, onDismiss: {
            viewModel.clearPresentedFlow()
        }) { destination in
            LegacyRootControllerHost {
                let vc = destination.build()
                let navigationController = UINavigationController(rootViewController: vc)
                navigationController.modalPresentationStyle = .fullScreen
                return navigationController
            }
            .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showMenu.toggle()
                    }
                }) {
                    Image(R.image.ic_menu.name)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(viewModel.userName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(UIColor(named: R.color.textDefault.name) ?? .black))
                    Text(viewModel.userCode)
                        .font(.system(size: 12))
                        .foregroundColor(Color.gray)
                }
            }

            if viewModel.role == .mc || viewModel.role == .pcb {
                HStack {
                    Text("Kho".localized())
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.gray)
                    Spacer()
                    Picker("Storage", selection: $viewModel.selectedStorageIndex) {
                        ForEach(Array(viewModel.dataStorage.enumerated()), id: \.offset) { index, item in
                            Text(item.layout ?? "...").tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(Color.white)
        .overlay(Divider(), alignment: .bottom)
    }
}
