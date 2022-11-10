//
//  OCRResultsViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 01/11/22.
//

import UIKit
import DocumentReader

class OCRResultsViewController: UIViewController {
    
    let usDef = UserDefaults.standard
    
    @IBOutlet weak var nombresTextField: UITextField!
    @IBOutlet weak var apellidosTextField: UITextField!
    @IBOutlet weak var dobTextField: UITextField!
    @IBOutlet weak var pasaporteTextField: UITextField!
    
    override func viewDidLoad() {
        nombresTextField.text = usDef.string(forKey: "nombresOCR")
        apellidosTextField.text = usDef.string(forKey: "apellidosOCR")
        dobTextField.text = usDef.string(forKey: "dobOCR")
        pasaporteTextField.text = usDef.string(forKey: "pasaporteOCR")
    }
    
    @IBAction func validarPasaporte(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "SelfieViewController")
        nextVC.modalPresentationStyle = .fullScreen
        present(nextVC, animated: true)
    }
}
