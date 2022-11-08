//
//  StartViewModel.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 11/10/22.
//

import UIKit

class StartViewModel {
    
    let userDefault = UserDefaults.standard
    
    let selfieTomada = "Selfie capturada"
    let selfieNoTomada = "Selfie pendiente"
    let NFCNoEscaneado = "NFC pendiente"
    let NFCEscaneado = "NFC escaneado"
    let noResultado = "Capturar selfie y NFC"
    let resultado = "Ver resultados"
    
    var selfieLabel: String
    var NFCLabel: String
    var resultLabel: String
    
    init() {
        
        selfieLabel = userDefault.bool(forKey: "selfieCapturada") ? selfieTomada : selfieNoTomada
        NFCLabel = userDefault.bool(forKey: "NFCEscaneado") ? NFCEscaneado : NFCNoEscaneado
        resultLabel = (userDefault.bool(forKey: "selfieCapturada") && userDefault.bool(forKey: "NFCEscaneado")) ? resultado : noResultado
    }
    
    func setSelfieLabel() -> String {
        return userDefault.bool(forKey: "selfieCapturada") ? selfieTomada : selfieNoTomada
    }
    
    func setNFCLabel() -> String {
        return userDefault.bool(forKey: "NFCEscaneado") ? NFCEscaneado : NFCNoEscaneado
    }
    
    func setResultsLabel() -> String {
        return (userDefault.bool(forKey: "selfieCapturada") && userDefault.bool(forKey: "NFCEscaneado")) ? resultado : noResultado
    }
    
    func setSelfieTextColor() -> UIColor {
        return userDefault.bool(forKey: "selfieCapturada") ? UIColor.black : UIColor.lightGray
    }
    
    func setNFCTextColor() -> UIColor {
        return userDefault.bool(forKey: "NFCEscaneado") ? UIColor.black : UIColor.lightGray
    }
    
    func setResultTextColor() -> UIColor {
        return (userDefault.bool(forKey: "selfieCapturada") && userDefault.bool(forKey: "NFCEscaneado")) ? UIColor.black : UIColor.lightGray
    }
    
    func enableResults() -> Bool {
        return userDefault.bool(forKey: "selfieCapturada") && userDefault.bool(forKey: "NFCEscaneado")
    }
}
