//
//  PassportCapturedViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 04/11/22.
//

import UIKit

class PassportCapturedViewController: UIViewController {
    
    @IBOutlet weak var passImage: UIImageView!
    
    override func viewDidLoad() {
        passImage.image = UIImage(data: UserDefaults.standard.data(forKey: "imagenDoc")!)
    }
    
    @IBAction func continuar(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let resultVC = storyboard.instantiateViewController(withIdentifier: "OCRResultsViewController")
        resultVC.modalPresentationStyle = .fullScreen
        present(resultVC, animated: true)
    }
    
    @IBAction func tomarOtraFoto(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "otraFoto")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "ScanMRZViewController")
        nextVC.modalPresentationStyle = .fullScreen
        present(nextVC, animated: true)
    }
}
