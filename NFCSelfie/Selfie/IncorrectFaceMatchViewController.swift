//
//  IncorrectFaceMatchViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 10/11/22.
//

import UIKit

class IncorrectFaceMatchViewController: UIViewController {
    
    @IBOutlet weak var incorrectFaceValidationLabel: UILabel!
    
    override func viewDidLoad() {
        incorrectFaceValidationLabel.text = NSLocalizedString("failed_facial_verification_label", comment: "")
        delay()
    }
    
    func delay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.navigate()
        }
    }
    
    func navigate() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "ResultsViewController")
        nextVC.modalPresentationStyle = .fullScreen
        present(nextVC, animated: true)
    }
}
