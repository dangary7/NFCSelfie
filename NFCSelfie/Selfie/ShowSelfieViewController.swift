//
//  ShowSelfieViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 04/11/22.
//

import UIKit

class ShowSelfieViewController: UIViewController {
    
    @IBOutlet weak var vcTitle: UILabel!
    @IBOutlet weak var correctPictureLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var retakePictureButton: UIButton!
    @IBOutlet weak var selfieImage: UIImageView!
    
    override func viewDidLoad() {
        setTexts()
        selfieImage.image = UIImage(data: UserDefaults.standard.data(forKey: "selfie")!)
    }
    
    func setTexts() {
        vcTitle.text = NSLocalizedString("face_vc_title", comment: " ")
        correctPictureLabel.text = NSLocalizedString("good_picture_tittle", comment: "")
        continueButton.setTitle(NSLocalizedString("continue_button", comment: ""), for: .normal)
        retakePictureButton.setTitle(NSLocalizedString("capture_again_button", comment: ""), for: .normal)
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
