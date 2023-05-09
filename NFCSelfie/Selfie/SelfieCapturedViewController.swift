//
//  SelfieCapturedViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 10/11/22.
//

import UIKit

class SelfieCapturedViewController: UIViewController {
    
    @IBOutlet weak var sucCaptureLabel: UILabel!
    
    override func viewDidLoad() {
        sucCaptureLabel.text = NSLocalizedString("success_face_capture_label", comment: "")
        delay()
    }
    
    func delay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.navigate()
        }
    }
    
    func navigate() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "ShowSelfieViewController")
        nextVC.modalPresentationStyle = .fullScreen
        present(nextVC, animated: true)
    }
}
