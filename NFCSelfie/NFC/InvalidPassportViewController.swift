//
//  InvalidPassportViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 03/05/23.
//

import UIKit

class InvalidPassportViewController: UIViewController {
    
    @IBOutlet weak var invalidPassportLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var tryAgainButton: UIButton!
    
    override func viewDidLoad() {
        setTexts()
    }
    
    func setTexts() {
        invalidPassportLabel.text = NSLocalizedString("invalid_passport_title", comment: "")
        infoLabel.text = NSLocalizedString("invalid_passport_label", comment: "")
        tryAgainButton.titleLabel?.text = NSLocalizedString("try_again_button", comment: "")
    }
}
