//
//  ShowImageDetailVC.swift
//  BIVN
//
//  Created by Tinhvan on 25/12/2023.
//

import UIKit
import Kingfisher

class ShowImageDetailVC: UIViewController {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var imgBack: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var titleString = ""
    var imageCapture = UIImage()
    var disPlayDetailHistory: Bool = false
    var url: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = true
        
        titleLabel.text = titleString
        
        imgView.isUserInteractionEnabled = true
        imgView.contentMode = .scaleAspectFit
        imgView.image = imageCapture
        if disPlayDetailHistory {
            imgView.kf.setImage(with: URL(string: url))
        }
        
        imgView.addTapGestureRecognizer { [weak self] in
            guard let self = self  else { return }
            self.dismiss(animated: true)
        }
        
        imgBack.addTapGestureRecognizer { [weak self] in
            guard let self = self  else { return }
            self.dismiss(animated: true)
        }
    }
    
}
