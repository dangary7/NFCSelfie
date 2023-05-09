//
//  NoChipViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 03/05/23.
//

import UIKit

class NoChipViewController: UIViewController {
    
    @IBOutlet weak var noChipTitleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var tryAgainButton: UIButton!
    override func viewDidLoad() {
        setTexts()
    }
    
    func setTexts() {
        noChipTitleLabel.text = NSLocalizedString("no_chip_title", comment: "")
        infoLabel.text = NSLocalizedString("no_chip_label", comment: "")
        tryAgainButton.titleLabel?.text = NSLocalizedString("try_again_button", comment: "")
    }
}
