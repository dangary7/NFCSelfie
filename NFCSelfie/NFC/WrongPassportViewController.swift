//
//  WrongPassportViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 07/11/22.
//

import UIKit

class WrongPassportViewController: UIViewController {
    
    override func viewDidLoad() {
        
    }
    @IBAction func scanAgain(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "NFCStartViewController")
        nextVC.modalPresentationStyle = .fullScreen
        self.present(nextVC, animated: true)
    }
}
