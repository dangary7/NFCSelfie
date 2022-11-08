//
//  Constants.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 14/10/22.
//

import Foundation

enum Menu: Int {
    case setAppMode = 0
    case setAppUI
    case enableAS
    case enableAssistedMode
    case showCaptureTraining
    case templateFormat
    case selectlanguage

    public var menuNameString: String{
        switch self {
        case .setAppMode:
            return "Set App mode"
        case .setAppUI:
            return "Set App UI"
        case .enableAS:
            return "Enable AS"
        case .showCaptureTraining:
            return "Show capture training"
        case .templateFormat:
            return "IDENTY Template Format"
        case .enableAssistedMode:
            return "Enable Assisted Mode"
        case .selectlanguage:
            return "Select Language"
        }
    }
}

enum HTMLPage: Int {
    case terms
    case privacy
    public var urlString: String {
        switch self {
        case .terms:
            return "tc"
        case .privacy:
            return "privacy"
        }
    }
}

enum selectedType: Int {
    case face
    public var selectedTypeString: String {
        switch self {
       
        case .face:
            return "Face"
       
        }
    }
    public var selectedPathString : String {
        switch self {
        
        case .face:
            return "IdentyFace"
       
        }
    }
    public var pathString : String {
        switch self {
       
        case .face:
            return "Face"
       
        }
    }
}
