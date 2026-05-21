import SwiftUI
import AVFoundation
import Localize_Swift

struct CodeScannerSwiftUIView: View {
    @SwiftUI.Environment(\.presentationMode) private var presentationMode
    let onScanned: (String) -> Void

    @State private var scannedCode: String?

    var body: some View {
        ZStack(alignment: .topLeading) {
            CodeScannerRepresentable { code in
                guard scannedCode == nil else { return }
                scannedCode = code
                onScanned(code)
                presentationMode.wrappedValue.dismiss()
            }
            .ignoresSafeArea()

            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }
            .padding(.leading, 16)
            .padding(.top, 16)
        }
    }
}

private struct CodeScannerRepresentable: UIViewControllerRepresentable {
    let onScanned: (String) -> Void

    func makeUIViewController(context: Context) -> CameraScannerViewController {
        let vc = CameraScannerViewController()
        vc.onScanned = onScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraScannerViewController, context: Context) {}
}

private final class CameraScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScanned: ((String) -> Void)?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var didEmitResult = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureScanner()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        didEmitResult = false
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    private func configureScanner() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
                metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr, .code39]
            }

            let preview = AVCaptureVideoPreviewLayer(session: captureSession)
            preview.videoGravity = .resizeAspectFill
            preview.frame = view.layer.bounds
            view.layer.addSublayer(preview)
            previewLayer = preview

            captureSession.startRunning()
        } catch {
            showPermissionAlert()
        }
    }

    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Thông báo".localized(),
            message: "Không thể mở camera. Vui lòng kiểm tra quyền truy cập camera.".localized(),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Đồng ý".localized(), style: .default))
        present(alert, animated: true)
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !didEmitResult else { return }
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadataObject.stringValue,
              !code.isEmpty else { return }

        didEmitResult = true
        captureSession.stopRunning()
        onScanned?(code)
    }
}
