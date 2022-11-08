//
//  Siingleton.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 14/10/22.
//

import Foundation
class Singleton {
    var currentLanguage : String?
    static let sharedInstance = Singleton()
    func languageSelect(key : String) -> String{
        var path : String?
        if(Singleton.sharedInstance.currentLanguage == "es-MX"){
            path = Bundle.main.path(forResource: "es-MX", ofType: "lproj")
        }else{
            path = Bundle.main.path(forResource: "en", ofType: "lproj")
        }
        let bundle : Bundle = Bundle.init(path: path!)!
        return bundle.localizedString(forKey: key, value: "", table: "Main")
    }
    func languagePath() -> String{
        var path : String?
        if(Singleton.sharedInstance.currentLanguage == "es-MX"){
            path = Bundle.main.path(forResource: "es-MX", ofType: "lproj")
        }else if(Singleton.sharedInstance.currentLanguage == "en"){
            path = Bundle.main.path(forResource: "en", ofType: "lproj")
        }else{
            path = ""
        }
        return path!
    }
}
