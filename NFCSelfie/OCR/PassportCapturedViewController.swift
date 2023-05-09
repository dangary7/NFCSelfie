//
//  PassportCapturedViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 04/11/22.
//

import UIKit

class PassportCapturedViewController: UIViewController {
    
    @IBOutlet weak var passImage: UIImageView!
    @IBOutlet weak var reviewDataLabel: UILabel!
    @IBOutlet weak var correctPictureLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var retakePictureButton: UIButton!
    
    
    
    override func viewDidLoad() {
        setTexts()
        passImage.image = UIImage(data: UserDefaults.standard.data(forKey: "imagenDoc")!)
    }
    
    func setTexts() {
        reviewDataLabel.text = NSLocalizedString("data_can_be_read", comment: " ")
        correctPictureLabel.text = NSLocalizedString("good_picture_tittle", comment: "")
        continueButton.setTitle(NSLocalizedString("continue_button", comment: ""), for: .normal)
        retakePictureButton.setTitle(NSLocalizedString("capture_again_button", comment: ""), for: .normal)
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
