//
//  NFCStartViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 12/10/22.
//

import UIKit
import IdentyFace
import IdentyFaceLocal

@available(iOS 15, *)
class NFCStartViewController: UIViewController {
    
    @IBOutlet weak var cvtitleLabel: UILabel!
    @IBOutlet weak var passportCloserLabel: UILabel!
    @IBOutlet weak var instructionsLabel: UILabel!
    
    let bundlePath = Bundle.main.path(forResource: "1448-com.fad.bio-31-10-2022", ofType: "lic") ?? ""
    
    var settings = SettingsStore()
    var passportReader = PassportReader()
    
    let usDef = UserDefaults.standard
    
    var numPasaporte = ""
    var fechaNacimiento = ""
    var fechaExpiracion = ""
    
    let savePassportOnScan = false
    
    private var showDetails = false
    private var alertTitle : String = ""
    private var showingAlert = false
    
    override func viewDidLoad() {
        setTexts()
        
        let dobForNFC = dateForNFC(usDef.string(forKey: "dobOCR") ?? "")
        let doeForNFC = dateForNFC(usDef.string(forKey: "doeOCR") ?? "")
        numPasaporte = usDef.string(forKey: "pasaporteOCR") ?? ""
        fechaExpiracion = doeForNFC
        fechaNacimiento = dobForNFC
    }
    
    override func viewWillAppear(_ animated: Bool) {
        scanPassport()
    }
    
    func setTexts() {
        cvtitleLabel.text = NSLocalizedString("nfc_vc_title", comment: "")
        passportCloserLabel.text = NSLocalizedString("nfc_title", comment: "")
        instructionsLabel.text = NSLocalizedString("nfc_passport_label", comment: "")
    }
    
    func dateForNFC(_ str: String) -> String {
        let chars = Array(str)
        return "\(chars[8])\(chars[9])\(chars[3])\(chars[4])\(chars[0])\(chars[1])"
    }
    
    func formatDate(fecha: Date) -> String {
        let dF = DateFormatter()
        dF.timeZone = TimeZone(secondsFromGMT: 6)
        dF.dateFormat = "YYMMdd"
        
        return dF.string(from: fecha)
    }
    
    func scanPassport( ) {
        hideKeyboard()
        self.showDetails = false
        
        let pptNr = numPasaporte
        let dob = fechaNacimiento
        let doe = fechaExpiracion

        let mrzKey = Utilities().getMRZKey( passportNumber: pptNr, dateOfBirth: dob, dateOfExpiry: doe)
        print(mrzKey)

        let masterListURL = Bundle.main.url(forResource: "masterList", withExtension: ".pem")!
        passportReader.setMasterListURL( masterListURL )
        
        passportReader.passiveAuthenticationUsesOpenSSL = !settings.useNewVerificationMethod
        
        Log.logLevel = settings.logLevel
        Log.storeLogs = settings.shouldCaptureLogs
        Log.clearStoredLogs()
        
        Log.error( "Usando  versión \(UIApplication.version)" )
        
        Task {
            let customMessageHandler : (NFCViewDisplayMessage)->String? = { (displayMessage) in
                switch displayMessage {
                    case .requestPresentPassport:
                        return NSLocalizedString("reques_present_passport", comment: "")
                    default:
                        return nil
                }
            }

            do {
                let passport = try await passportReader.readPassport( mrzKey: mrzKey, customDisplayMessage:customMessageHandler)
                
                if settings.savePassportOnScan {
                    let dict = passport.dumpPassportData(selectedDataGroups: DataGroupId.allCases, includeActiveAuthenticationData: true)
                    if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
                        
                        let savedPath = FileManager.cachesFolder.appendingPathComponent("\(passport.documentNumber).json")
                        
                        try? data.write(to: savedPath, options: .completeFileProtection)
                    }
                }
                
                DispatchQueue.main.async {
                    self.settings.passport = passport
                    let usDef = UserDefaults.standard
                    let picData = passport.passportImage?.pngData()
                    usDef.set(passport.firstName, forKey: "nombre")
                    usDef.set(passport.lastName, forKey: "apellido")
                    usDef.set(passport.gender, forKey: "sexo")
                    usDef.set(passport.documentNumber, forKey: "numeroPasaporte")
                    usDef.set(passport.dateOfBirth, forKey: "fechaNacimiento")
                    usDef.set(passport.documentExpiryDate, forKey: "fechaExpiracion")
                    usDef.set(passport.issuingAuthority, forKey: "paisEmisor")
                    usDef.set(passport.passportImage?.pngData(), forKey: "foto")
                    let valid = passport.passportDataNotTampered && passport.documentSigningCertificateVerified && passport.passportCorrectlySigned
                    usDef.set(valid, forKey: "pasaporteValido")
                    self.showDetails = true
                    
                    self.compareFaces()
                    
                    if usDef.float(forKey: "score") < 50 {
                        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                        let nextVC = storyboard.instantiateViewController(withIdentifier: "IncorrectFaceMatchViewController")
                        nextVC.modalPresentationStyle = .fullScreen
                        self.present(nextVC, animated: true)
                    } else {
                        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                        let nextVC = storyboard.instantiateViewController(withIdentifier: "ResultsViewController")
                        nextVC.modalPresentationStyle = .fullScreen
                        self.present(nextVC, animated: true)
                    }
                }
            } catch {
                self.alertTitle = "Oops"
                self.alertTitle = error.localizedDescription
                self.showingAlert = true
                
                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                let nextVC = storyboard.instantiateViewController(withIdentifier: "WrongPassportViewController")
                nextVC.modalPresentationStyle = .fullScreen
                self.present(nextVC, animated: true)
            }
        }
    }
    
    func compareFaces() {
        let instance = IdentyFaceFramework.init(with: bundlePath, localizablePath: Singleton.sharedInstance.languagePath(), table: "Main")
        
        var faceMatch : FaceMatcher!
        let instat = FaceLocalMatch()
        faceMatch = FaceLocalMatcher(instat.getLocalMatcher())
        
        instance.matchWithTemplate(viewcontrol: self, faceMatch: faceMatch, probeTemplateType: FaceAppTemplateFormat.png, probeTemplate: usDef.data(forKey: "foto")!, candidateTemplateType: FaceAppTemplateFormat.png, candidateTemplate: usDef.data(forKey: "selfie")!) { responseModel, transactionID, noOfAttempts in
            let dict : Dictionary<String,Any> = (responseModel?.responseDictionary)!
            let datadict :  Dictionary<String,Any> = dict["data"] as! Dictionary<String, Any>
            let aux = datadict["similarity_score"]
            UserDefaults.standard.set(aux, forKey: "score")
        } onFailure: { error, transactionID, noOfAttempts in
            print("Error: \(String(describing: error))")
        } onAttempts: { responseAttempts in
            
        }
    }
}

@available(iOS 15, *)
extension NFCStartViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}

@available(iOS 15, *)
extension NFCStartViewController {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
