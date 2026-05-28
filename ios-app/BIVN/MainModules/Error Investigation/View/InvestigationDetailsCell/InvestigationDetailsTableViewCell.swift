//
//  InvestigationDetailsTableViewCell.swift
//  BIVN
//
//  Created by Bi on 13/1/25.
//

import UIKit
import Kingfisher
import Localize_Swift

protocol InvestigationDetailsCellDelegate: AnyObject {
    func didEditInformation()
}

class InvestigationDetailsTableViewCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var deleteButtonImage2: UIButton!
    @IBOutlet weak var deleteButtonImage1: UIButton!
    @IBOutlet weak var titleNameLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewErrorLabel: UILabel!
    @IBOutlet weak var firstImageView: UIImageView!
    @IBOutlet weak var secondImageView: UIImageView!
    @IBOutlet weak var captureImage1Button: UIButton!
    @IBOutlet weak var captureImage2Button: UIButton!
    private var placeholderLabel: UILabel!
    private var capturedImages: [UIImage] = []
    @IBOutlet weak var containerView1: UIView!
    @IBOutlet weak var containerView2: UIView!
    
    
    
    weak var delegate: InvestigationDetailsCellDelegate?
    var deleteImageHandler: ((Int) -> Void)?
    var captureImageHandler: ((Int) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    func roundCorners(_ button: UIButton, radius: CGFloat = 10) {
        button.layer.cornerRadius = radius
        button.clipsToBounds = true
    }
    
    private func setupUI() {
        roundCorners(captureImage1Button)
        roundCorners(captureImage2Button)
        firstImageView.image = UIImage(named: R.image.image1834.name)
        secondImageView.image = UIImage(named: R.image.image1834.name)
        [firstImageView, secondImageView].forEach {
            $0?.layer.cornerRadius = 4
            $0?.clipsToBounds = true
            $0?.contentMode = .scaleAspectFill
        }
        deleteButtonImage2.setTitle("", for: .normal)
        deleteButtonImage1.setTitle("", for: .normal)
        titleNameLabel.text = "Chi tiết đầu ra".localized()
        titleNameLabel.font = fontUtils.size12.bold
        textView.layer.cornerRadius = 4
        textView.layer.borderWidth = 0.4
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.backgroundColor = UIColor(named: R.color.grey1.name)
        textView.delegate = self
        setupPlaceholder()
        textViewErrorLabel.isHidden = true
        textViewErrorLabel.textColor = .red
        textViewErrorLabel.font = UIFont.systemFont(ofSize: 12)
    }
    
    private func setupPlaceholder() {
        placeholderLabel = UILabel()
        placeholderLabel.text = "Nhập chi tiết điều tra...".localized()
        placeholderLabel.font = textView.font
        placeholderLabel.textColor = .lightGray
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 5),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -5)
        ])
        
        checkPlaceholderVisibility()
    }
    
    func checkPlaceholderVisibility() {
        placeholderLabel.isHidden = !textView.text.isEmpty
        if !textView.text.isEmpty {
            hideTextViewError()
        }
    }

    
    func showTextViewError(message: String) {
        textViewErrorLabel.text = message
        textViewErrorLabel.isHidden = false
    }
    
    func hideTextViewError() {
        textViewErrorLabel.isHidden = true
    }
    
    func fillImage(for imageView: UIImageView, urlString: String?) {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            imageView.image = UIImage(named: R.image.ic_avatar.name) // Placeholder
            return
        }
        imageView.kf.setImage(with: url, placeholder: UIImage(named: R.image.image1834.name))
    }
    
    func fillData(url1: String, url2: String) {
        let ssid = UserDefaults.standard.string(forKey: "nameWifi")
        let baseUrl: URL? = {
            if Environment.rootURL.description.contains("tinhvan") {
                return Environment.rootURL
            } else if ssid == "bivnioswifim01" {
                return URL(string: "http://172.26.248.26/gateway_inv_dev_test")
            } else {
                return Environment.rootURL
            }
        }()
        
        firstImageView.kf.setImage(
            with: getFullImageUrl(baseUrl: baseUrl, path: url1),
            placeholder: UIImage(named: R.image.image1834.name)
        )
        secondImageView.kf.setImage(
            with: getFullImageUrl(baseUrl: baseUrl, path: url2),
            placeholder: UIImage(named: R.image.image1834.name)
        )
    }
    
    func getFullImageUrl(baseUrl: URL?, path: String) -> URL? {
        guard let baseUrl = baseUrl else { return nil }
        return URL(string: "\(baseUrl)/\(path)")
    }
    
    
    @IBAction func ontapDeleteImage1(_ sender: Any) {
        deleteImageHandler?(0)
    }
    
    @IBAction func ontapDeleteImage2(_ sender: Any) {
        deleteImageHandler?(1)
    }
    
    @IBAction func captureImage1Tapped(_ sender: UIButton) {
        captureImageHandler?(0)
    }

    @IBAction func captureImage2Tapped(_ sender: UIButton) {
        captureImageHandler?(1)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        checkPlaceholderVisibility()
        delegate?.didEditInformation()
    }
    
}

