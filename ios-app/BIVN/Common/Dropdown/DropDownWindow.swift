//
//  DropDownWindow.swift
//  BIVN
//
//  Created by Tinhvan on 15/09/2023.
//

import UIKit
import Foundation



class DropDownWindow: UIViewController {
    let dropDownView = DropDownView()
    var dropDownData: ((DataStorageModel, Int) -> ())?
    
    init(frames: CGRect, viewSelect: UIView, data: [DataStorageModel], indexChoose: Int) {
        super.init(nibName: nil, bundle: nil)
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overFullScreen
        view.backgroundColor = .clear
        view = dropDownView
        
        
        dropDownView.addTransparentView(frames: frames, viewSelect: viewSelect, data: data, indexChoose: indexChoose)
        
        dropDownView.transparentView.addTapGestureRecognizer {
            self.dismissView()
        }
        
        dropDownView.didSelectRow = { (value, index) in
            self.dropDownData?(value, index)
            self.dismissView()
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @objc func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }


}
