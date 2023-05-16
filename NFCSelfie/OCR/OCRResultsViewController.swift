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
    
    @IBOutlet weak var vcTitleLabel: UILabel!
    @IBOutlet weak var passportTitleLabel: UILabel!
    @IBOutlet weak var validateDataLabel: UILabel!
    @IBOutlet weak var namesLabel: UILabel!
    @IBOutlet weak var familyNamesLabel: UILabel!
    @IBOutlet weak var dateOfBirthLabel: UILabel!
    @IBOutlet weak var passportNumberLabel: UILabel!
    @IBOutlet weak var validateButton: UIButton!
    @IBOutlet weak var nombresTextField: UITextField!
    @IBOutlet weak var apellidosTextField: UITextField!
    @IBOutlet weak var dobTextField: UITextField!
    @IBOutlet weak var pasaporteTextField: UITextField!
    
    override func viewDidLoad() {
        setTexts()
        
        nombresTextField.text = usDef.string(forKey: "nombresOCR")
        apellidosTextField.text = usDef.string(forKey: "apellidosOCR")
        dobTextField.text = usDef.string(forKey: "dobOCR")
        pasaporteTextField.text = usDef.string(forKey: "pasaporteOCR")
        
        nombresTextField.delegate = self
        apellidosTextField.delegate = self
        dobTextField.delegate = self
        pasaporteTextField.delegate = self
    }
    
    func setTexts() {
        vcTitleLabel.text = NSLocalizedString("passport_vc_title", comment: "")
        passportTitleLabel.text = NSLocalizedString("passport_title", comment: "")
        validateDataLabel.text = NSLocalizedString("validate_data", comment: "")
        namesLabel.text = NSLocalizedString("given_names_label", comment: "")
        familyNamesLabel.text = NSLocalizedString("surname_label", comment: "")
        dateOfBirthLabel.text = NSLocalizedString("birth_day_label", comment: "")
        passportNumberLabel.text = NSLocalizedString("passport_number_label", comment: "")
        validateButton.setTitle(NSLocalizedString("validate_button", comment: ""), for: .normal)
    }
    
    @IBAction func validarPasaporte(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "SelfieViewController")
        nextVC.modalPresentationStyle = .fullScreen
        present(nextVC, animated: true)
    }
    
    func updateOCRData() {
        usDef.set(nombresTextField.text, forKey: "nombresOCR")
        usDef.set(apellidosTextField.text, forKey: "apellidosOCR")
        usDef.set(dobTextField.text, forKey: "dobOCR")
        usDef.set(pasaporteTextField.text, forKey: "pasaporteOCR")
    }
}

extension OCRResultsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        updateOCRData()
        return false
    }
}
