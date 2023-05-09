//
//  ProcessingViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 03/05/23.
//

import UIKit

class ProcessingViewController: UIViewController {
    
    @IBOutlet weak var processingTitleLabel: UILabel!
    @IBOutlet weak var waitLabel: UILabel!
    
    override func viewDidLoad() {
        setTexts()
    }
    
    func setTexts() {
        processingTitleLabel.text = NSLocalizedString("nfc_processing_title", comment: "")
        waitLabel.text = NSLocalizedString("wait_a_moment_label", comment: "")
    }
}
