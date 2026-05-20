//
//  QRInventoryVC.swift
//  BIVN
//
//  Created by Tinhvan on 22/11/2023.
//

import UIKit
import AVFoundation
import Localize_Swift

protocol QRInventoryVCProtocol {
    func senDataQR(arrayData: [DocComponentABEs])
}

class QRInventoryVC: BaseViewController {
    
    @IBOutlet weak var scanerView: UIView!
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var imageScanView: UIImageView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(R.nib.titleInventoryCell)
            tableView.register(R.nib.invenTableViewCell)
            tableView.register(R.nib.titleHistoryCell)
        }
    }
    private var isShowErrorView = false
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    var arrayAccessory: [AccessoryModel] = []
    var arrayDocABE: [DocComponentABEs] = []
    private var arrayStringCode: [String] = []
    var componentCodeABE = ""
    var delegateQR: QRInventoryVCProtocol?
    var checkDuplicateQR: (([AccessoryModel]) -> Void)?

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        imageScanView.image = UIImage(named: R.image.ic_scan.name)
        
        disPlayscanerCode()
    }
    
    private func setupUI() {
        self.hideKeyboardWhenTappedAround()
        self.navigationController?.navigationBar.backIndicatorImage = UIImage(named: R.image.ic_back.name)
        self.navigationController?.navigationBar.tintColor = UIColor.gray
        self.navigationItem.setHidesBackButton(true, animated: true)
        let buttonLeft = UIBarButtonItem(image: UIImage(named: R.image.ic_back.name), style: .plain, target: self, action: #selector(backTap))
        self.navigationItem.leftBarButtonItem = buttonLeft
        self.title = "Quét".localized()
        
        isShowErrorView = false
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.contentInset.bottom = 16
        contentLabel.text = "Đưa camera về tem linh kiện".localized()
        titleLabel.text = "Quét tem linh kiện".localized()
        sendButton.addTarget(self, action: #selector(sendOnTap), for: .touchUpInside)
        sendButton.setTitle("Xác nhận".localized(), for: .normal)
        
        setFontTitleNavBar()
    }
    
    @objc private func sendOnTap() {
        
        for docABE in self.arrayDocABE {
            if docABE.quantityOfBom == 0 || docABE.quantityOfBom == nil {
                self.isShowErrorView = true
            }
            
            if docABE.quantityPerBom == 0 || docABE.quantityPerBom == nil {
                self.isShowErrorView = true
            }
        }
        
        if isShowErrorView {
            self.tableView.reloadData()
        } else {
            self.delegateQR?.senDataQR(arrayData: self.arrayDocABE)
            self.checkDuplicateQR?(arrayAccessory)
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    @objc private func backTap() {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func disPlayscanerCode() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr, .code39]
        } else {
            failed()
            return
        }
        let layer = createScannerGradientLayer(for: animationView)
        animationView.layer.insertSublayer(layer, at: 0)
        let animation = createAnimation(for: layer)
        layer.removeAllAnimations()
        layer.add(animation, forKey: nil)
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = scanerView.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        scanerView.layer.addSublayer(previewLayer)
        captureSession.startRunning()
    }
    
    private func removeScanCode() {
        if (captureSession?.isRunning == true) {
            self.contentLabel.isHidden = true
            captureSession.stopRunning()
        }
    }
    
    private func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let nav = self.navigationController?.navigationBar
        nav?.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(named: R.color.textDefault.name) ?? UIColor.black]
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeScanCode()
    }
    
    private func showToast() {
        let attribute1 = [NSAttributedString.Key.font: fontUtils.size14.regular]
        let attrString1 = NSMutableAttributedString(string: "Đã cập nhật số lượng.".localized(), attributes: attribute1)
        self.view.showToastCompletion(attrString1, numberOfLine: 1, marginBottom: -132, img: UIImage(named: R.image.icTickCircle.name), isSee: false, completion: {
        })
    }
    
}

extension QRInventoryVC: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
    }
    
    private func found(code: String) {
        self.contentLabel.isHidden = true
        isShowErrorView = false
        
        self.arrayDocABE.removeAll(where: {
            ($0.quantityOfBom == 0 || $0.quantityOfBom == nil) && ($0.quantityPerBom == 0 || $0.quantityPerBom == nil)
        })
        
        let inputString = code
        let splits = inputString.components(separatedBy: "&")
        
        let occurrencies = inputString.filter( {$0 == "&"}).count
        guard occurrencies > 7 else {
            self.showAlertNoti(title: "Lỗi".localized(), message: "Tem linh kiện không đúng định dạng. Vui lòng thử lại.".localized(), acceptButton: "Đồng ý".localized(), acceptOnTap: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.captureSession.startRunning()
                }
            })
            return
        }
        
        self.arrayStringCode.removeAll()
        
        for item in splits {
            self.arrayStringCode.append(item)
        }
        
        //Check serial
        if self.arrayStringCode[3] != self.componentCodeABE {
            let contentError = "Tem linh kiện này không thuộc linh kiện mà bạn đang thực hiện kiểm kê. Vui lòng thao tác lại.".localized()
            self.showAlertNoti(title: "Lỗi".localized(), message: contentError, acceptButton: "Đồng ý".localized(), acceptOnTap:  { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.captureSession.startRunning()
                }
            })
        } else {
            if self.arrayAccessory.contains(where: {$0.content == code}) {
                let contentError = "Tem linh kiện này đã được quét. Vui lòng thao tác lại.".localized()
                self.showAlertNoti(title: "Lỗi".localized(), message: contentError, acceptButton: "Đồng ý".localized(), acceptOnTap:  { [weak self] in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.captureSession.startRunning()
                    }
                })
            } else {
                let accessory = AccessoryModel(content: code, code: self.arrayStringCode[0], boxes: self.arrayStringCode[7])
                self.arrayAccessory.append(accessory)
                
                if self.arrayDocABE.count > 0 {
                    
                    if let indexDocABE = self.arrayDocABE.enumerated().first(where: {$0.element.quantityPerBom == Double(self.arrayStringCode[7])}).map( {$0.offset} ) {
                        print(indexDocABE)
                        
                        self.arrayDocABE[indexDocABE].quantityOfBom = (self.arrayDocABE[indexDocABE].quantityOfBom ?? 0) + 1
                        self.showToast()
                    } else {
                        let docABE = DocComponentABEs(id: "", quantityOfBom: 1, quantityPerBom: Double(self.arrayStringCode[7]))
                        self.arrayDocABE.append(docABE)
                        self.showToast()
                    }
                    
                } else {
                    let docABE = DocComponentABEs(id: "", quantityOfBom: 1, quantityPerBom: Double(self.arrayStringCode[7]))
                    self.arrayDocABE.append(docABE)
                    self.showToast()
                }
                
                self.tableView.reloadData()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.captureSession.startRunning()
                }
            }
        }
    }
    
}

extension QRInventoryVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return arrayDocABE.count
        } else {
            return isShowErrorView ? 1 : 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleInventoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            return cell
        } else if indexPath.section == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.invenTableViewCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setDataToCellQRScanItem(data: arrayDocABE[indexPath.row], index: indexPath.row, isLast: (arrayDocABE.count - 1) == indexPath.row ? true : false)
            
            return cell
        } else if indexPath.section == 2 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.titleHistoryCell, for: indexPath) else {return UITableViewCell()}
            cell.selectionStyle = .none
            cell.setTitleError(content: "Vui lòng quét tem linh kiện.".localized())
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 60
        } else {
            return 60
        }
    }
    
}
