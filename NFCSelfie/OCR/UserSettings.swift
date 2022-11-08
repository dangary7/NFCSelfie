//
//  UserSettings.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 01/11/22.
//

import Foundation
import DocumentReader

// Helper class for holding settings
class ApplicationSettings {
    static var shared: ApplicationSettings = ApplicationSettings()
    
    var isDataEncryptionEnabled: Bool = false
    var isRfidEnabled: Bool = false
    var useCustomRfidController: Bool = false
    
    var functionality: Functionality = DocReader.shared.functionality
}
