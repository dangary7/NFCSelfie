//
//  WrongPassportViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 07/11/22.
//

import UIKit

class WrongPassportViewController: UIViewController {
    
    @IBOutlet weak var wrongPassportLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var tryAgainButton: UIButton!
    
    override func viewDidLoad() {
        setTexts()
    }
    
    func setTexts() {
        wrongPassportLabel.text = NSLocalizedString("incorrect_passport_title", comment: "")
        infoLabel.text = NSLocalizedString("incorrect_passport_label", comment: "")
        tryAgainButton.titleLabel?.text = NSLocalizedString("try_again_button", comment: "")
    }
    
    @IBAction func scanAgain(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "NFCStartViewController")
        nextVC.modalPresentationStyle = .fullScreen
        self.present(nextVC, animated: true)
    }
}
