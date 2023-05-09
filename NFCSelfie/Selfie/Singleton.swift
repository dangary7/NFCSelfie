//
//  Siingleton.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 14/10/22.
//

import Foundation
class Singleton {
    var currentLanguage : String? = Locale.preferredLanguages[0]
    static let sharedInstance = Singleton()
    /*func languageSelect(key : String) -> String{
        var path : String?
        if(Singleton.sharedInstance.currentLanguage == "es-MX"){
            path = Bundle.main.path(forResource: "es-MX", ofType: "lproj")
        }else if (Singleton.sharedInstance.currentLanguage == "en"){
            path = Bundle.main.path(forResource: "en", ofType: "lproj")
        }else{
            path = Bundle.main.path(forResource: "pt-BR", ofType: "lproj")
        }
        let bundle : Bundle = Bundle.init(path: path!)!
        return bundle.localizedString(forKey: key, value: "", table: "Main")
    }*/
    func languagePath() -> String{
        var path : String?
        if(Singleton.sharedInstance.currentLanguage == "es" || Singleton.sharedInstance.currentLanguage == "es-419" || Singleton.sharedInstance.currentLanguage == "es-MX"){
            path = Bundle.main.path(forResource: "es-419", ofType: "lproj")
        }else if(Singleton.sharedInstance.currentLanguage == "en" || Singleton.sharedInstance.currentLanguage == "en-GB" || Singleton.sharedInstance.currentLanguage == "en-AU" || Singleton.sharedInstance.currentLanguage == "en-CA" || Singleton.sharedInstance.currentLanguage == "en-IN" || Singleton.sharedInstance.currentLanguage == "en-IE" || Singleton.sharedInstance.currentLanguage == "en-NZ" || Singleton.sharedInstance.currentLanguage == "en-SG" || Singleton.sharedInstance.currentLanguage == "en-ZA"){
            path = Bundle.main.path(forResource: "en", ofType: "lproj")
        }else if(Singleton.sharedInstance.currentLanguage == "pt" || Singleton.sharedInstance.currentLanguage == "pt-BR"){
            path = Bundle.main.path(forResource: "pt-BR", ofType: "lproj")
        }else{
            path = ""
        }
        return path!
    }
}
