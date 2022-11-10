//
//  ShowSelfieViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 04/11/22.
//

import UIKit

class ShowSelfieViewController: UIViewController {
    
    @IBOutlet weak var selfieImage: UIImageView!
    
    override func viewDidLoad() {
        selfieImage.image = UIImage(data: UserDefaults.standard.data(forKey: "selfie")!)
    }
    @IBAction func continuar(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "NFCStartViewController")
        nextVC.modalPresentationStyle = .fullScreen
        present(nextVC, animated: true)
    }
    
    @IBAction func tomarOtraFoto(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "SelfieViewController")
        nextVC.modalPresentationStyle = .fullScreen
        present(nextVC, animated: true)
    }
}
