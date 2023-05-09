//
//  NoSupportedViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 03/05/23.
//

import UIKit

class NoSupportedViewController: UIViewController {
    
    @IBOutlet weak var noSupportedTitleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var tryDifferentPassportButton: UIButton!
    
    override func viewDidLoad() {
        setTexts()
    }
    
    func setTexts() {
        noSupportedTitleLabel.text = NSLocalizedString("unsupported_passport_title", comment: "")
        infoLabel.text = NSLocalizedString("unsupported_passport_label", comment: "")
        tryDifferentPassportButton.titleLabel?.text = NSLocalizedString("try_other_passport_button", comment: "")
    }
}
