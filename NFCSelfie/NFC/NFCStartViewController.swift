//
//  NFCStartViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 12/10/22.
//

import UIKit

@available(iOS 15, *)
class NFCStartViewController: UIViewController {
    
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
        
        let dobForNFC = dateForNFC(usDef.string(forKey: "dobOCR") ?? "")
        let doeForNFC = dateForNFC(usDef.string(forKey: "doeOCR") ?? "")
        numPasaporte = usDef.string(forKey: "pasaporteOCR") ?? ""
        fechaExpiracion = doeForNFC
        fechaNacimiento = dobForNFC
    }
    
    override func viewWillAppear(_ animated: Bool) {
        scanPassport()
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

        // Set the masterListURL on the Passport Reader to allow auto passport verification
        let masterListURL = Bundle.main.url(forResource: "masterList", withExtension: ".pem")!
        passportReader.setMasterListURL( masterListURL )
        
        // Set whether to use the new Passive Authentication verification method (default true) or the old OpenSSL CMS verifiction
        passportReader.passiveAuthenticationUsesOpenSSL = !settings.useNewVerificationMethod

        // If we want to read only specific data groups we can using:
//        let dataGroups : [DataGroupId] = [.COM, .SOD, .DG1, .DG2, .DG7, .DG11, .DG12, .DG14, .DG15]
//        passportReader.readPassport(mrzKey: mrzKey, tags:dataGroups, completed: { (passport, error) in
        
        Log.logLevel = settings.logLevel
        Log.storeLogs = settings.shouldCaptureLogs
        Log.clearStoredLogs()
        
        Log.error( "Using version \(UIApplication.version)" )
        
        Task {
            let customMessageHandler : (NFCViewDisplayMessage)->String? = { (displayMessage) in
                switch displayMessage {
                    case .requestPresentPassport:
                        return "Hold your iPhone near an NFC enabled passport."
                    default:
                        // Return nil for all other messages so we use the provided default
                        return nil
                }
            }

            do {
                let passport = try await passportReader.readPassport( mrzKey: mrzKey, customDisplayMessage:customMessageHandler)
                
                if settings.savePassportOnScan {
                    // Save passport
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
                    
                    let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                    let nextVC = storyboard.instantiateViewController(withIdentifier: "SelfieViewController")
                    nextVC.modalPresentationStyle = .fullScreen
                    self.present(nextVC, animated: true)
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