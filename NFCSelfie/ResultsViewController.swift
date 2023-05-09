//
//  ResultsViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 11/10/22.
//

import UIKit
import IdentyFace

@available(iOS 13, *)
class ResultsViewController : UIViewController {
    
    @IBOutlet weak var NFCImage: UIImageView!
    @IBOutlet weak var selfieImage: UIImageView!
    @IBOutlet weak var noPasaporte: UILabel!
    @IBOutlet weak var nombre: UILabel!
    @IBOutlet weak var primerApellido: UILabel!
    @IBOutlet weak var fechaNacimiento: UILabel!
    @IBOutlet weak var nivelSimilitud: UILabel!
    @IBOutlet weak var indicatorView: UIView!
    @IBOutlet weak var indicatorLabel: UILabel!
    @IBOutlet weak var namesLabel: UILabel!
    @IBOutlet weak var familyNamesLabel: UILabel!
    @IBOutlet weak var dateOfBirthLabel: UILabel!
    @IBOutlet weak var passportNumberLabel: UILabel!
    
    var passport = NFCPassportModel()
    
    let usDef = UserDefaults.standard
    
    override func viewDidLoad() {
        setTexts()
        
        nombre.text = usDef.string(forKey: "nombre")
        primerApellido.text = usDef.string(forKey: "apellido")
        noPasaporte.text = usDef.string(forKey: "numeroPasaporte")
        fechaNacimiento.text = usDef.string(forKey: "dobOCR")
        NFCImage.image = UIImage(data: usDef.data(forKey: "foto")!)
        selfieImage.image = UIImage(data: usDef.data(forKey: "selfie")!)
        
        /*if usDef.float(forKey: "score") < 50 {
            indicatorView.backgroundColor = UIColor.red
            indicatorLabel.text = "Validación no exitosa"
        }*/
    }
    
    func setTexts() {
        if usDef.float(forKey: "score") < 50 {
            indicatorView.backgroundColor = UIColor.red
            indicatorLabel.text = NSLocalizedString("validation_fail_title", comment: "")
        } else {
            indicatorLabel.text = NSLocalizedString("validation_succes_title", comment: "")
        }
        
        namesLabel.text = NSLocalizedString("given_names_label", comment: "")
        familyNamesLabel.text = NSLocalizedString("surname_label", comment: "")
        dateOfBirthLabel.text = NSLocalizedString("birth_day_label", comment: "")
        passportNumberLabel.text = NSLocalizedString("passport_number_label", comment: "")
        
        //let temp: String = "\(usDef.float(forKey: "score"))" + NSLocalizedString("similarity_found_label", comment: "")
        let temp = "\(usDef.float(forKey: "score"))% " + String(format: NSLocalizedString("similarity_found_label", comment: ""), "")
        
        nivelSimilitud.text = temp
    }
    
    @IBAction func goHomeVC(_ sender: Any) {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let homeVC = storyboard.instantiateViewController(withIdentifier: "ScanMRZViewController")
        homeVC.modalPresentationStyle = .fullScreen
        self.present(homeVC, animated: true)
    }
}

