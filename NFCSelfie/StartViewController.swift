//
//  ViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 11/10/22.
//

import UIKit

class StartViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var NFCLabel: UILabel!
    @IBOutlet weak var NFCButton: UIButton!
    
    let viewModel = StartViewModel()
    
    let userDefault = UserDefaults.standard
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let domain = Bundle.main.bundleIdentifier!
        userDefault.removePersistentDomain(forName: domain)
        userDefault.synchronize()
        
        titleLabel.text = "NFC & Selfie Demo"
        
        NFCButton.setTitle("Empezar", for: .normal)
        
        userDefault.set(false, forKey: "selfieCapturada")
        userDefault.set(false, forKey: "NFCEscaneado")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NFCLabel.text = viewModel.setNFCLabel()
        
        NFCLabel.textColor = viewModel.setNFCTextColor()
    }

    @IBAction func goToNFC(_ sender: Any) {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "ScanMRZViewController")
        nextVC.modalPresentationStyle = .fullScreen
        present(nextVC, animated: true)
    }
}

