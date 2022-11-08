//
//  NFCViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 11/10/22.
//

import UIKit

class NFCViewController : UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        
        titleLabel.text = "Escanear NFC"
    }
    
    @IBAction func goBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func startNFCScan(_ sender: Any) {
        let storyboard = UIStoryboard(name: "NFC", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "NFCStartViewController")
        present(nextVC, animated: true)
        modalPresentationStyle = .fullScreen
    }
}
