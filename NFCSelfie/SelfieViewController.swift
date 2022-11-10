//
//  SelfieViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 11/10/22.
//

import UIKit
import IdentyFace
import IdentyFaceLocal

@available(iOS 13.0, *)
class SelfieViewController: UIViewController {
        
    var bundlePath = ""
    var selectedType : selectedType = .face
    
    private var plainSolidColor:UIColor! = nil
    private var textbackgroundColor:UIColor! = nil
    private var startColor:UIColor! = nil
    private var middleColor:UIColor! = nil
    private var endColor:UIColor! = nil
    
    var identyFaceUser: IdentyFaceFramework.Identy_User?
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        
        bundlePath = Bundle.main.path(forResource: "1448-com.fad.bio-31-10-2022", ofType: "lic") ?? ""
        startColor = .systemBackground
        middleColor = .systemBackground
        endColor = .systemBackground
    }
    
    @IBAction func startSelfie(_ sender: Any) {
        enrollFaceWithPath(bundlePath)
    }
    
    func enrollFaceWithPath(_ bundlePath: String) {
        let instance = IdentyFaceFramework.init(with: bundlePath, localizablePath: Singleton.sharedInstance.languagePath(), table: "Main")
        instance.isNeedShowTraining = false
        instance.isAntiSpoofCheck = UserDefaults.standard.bool(forKey: FaceKeys.isAntiSpoof)
        instance.displayResult = false
        instance.isDemo = true
        instance.isAssistedMode = UserDefaults.standard.bool(forKey: FaceKeys.isAssistedMode)
        
        instance.templates.removeAll()
        instance.templates.append(.png)
        
        instance.isCustomResultScreen = false
        instance.isCustomIntroScreen = false
        instance.isLogEnabled = true
        instance.isInitialize = true
        
        var faceMatch : FaceMatcher!
        let instat = FaceLocalMatch()
        faceMatch = FaceLocalMatcher(instat.getLocalMatcher())
        
        instance.enroll(viewcontrol: self, faceMatcher: faceMatch) { responseModel, transactionID, noOfAttempts in
            let dict : Dictionary<String,Any> = (responseModel?.responseDictionary)!
            let datadict :  Dictionary<String,Any> = dict["data"] as! Dictionary<String, Any>
            var keysArray : [String] = [String]()
            
            let aux = datadict["face"] as! [String : Any]
            let aux1 = aux["similarity_score"]
            UserDefaults.standard.set(aux1, forKey: "score")
            
            for (key,_) in datadict{
                keysArray.append(key)
            }
            
            for i in 0 ..< keysArray.count
            {
                let key = keysArray[i]
                if key != "background"{
                    if key != "message"{
                        let middledict : Dictionary<String,Any> = datadict[key] as! Dictionary<String, Any>
                        self.appDelegate.nistImgWidthDict.updateValue(middledict["width"] as! CGFloat, forKey: key)
                        self.appDelegate.nistImgHeightDict.updateValue(middledict["height"] as! CGFloat, forKey: key)
                        
                        let templatedict : Dictionary<String,Any>  = middledict["templates"] as! Dictionary<String, Any>
                        if templatedict["PNG"] != nil{
                            let pngvalue = templatedict["PNG"] as! String
                            let pngData = pngvalue.data(using: .utf8)
                            let data = Data(base64Encoded: pngData!)
                            UserDefaults.standard.set(data, forKey: "selfie")
                            self.appDelegate.nistFaceDict.updateValue(data!, forKey: key)
                            self.generateTemplates(filename: key, data: data, type: "Enroll", fileExtension: "png")
                        }
                    }else {
                        DLog("Moved back", "")
                    }
                }else {
                    DLog("Moved back", "")
                }
            }
            UserDefaults.standard.set(false, forKey: "matchFailed")
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let nextvc = storyboard.instantiateViewController(withIdentifier: "SelfieCapturedViewController")
            nextvc.modalPresentationStyle = .fullScreen
            self.present(nextvc, animated: true)
        } onFailure: { response, error, transactionID, noOfAttempts in
            let dict : Dictionary<String,Any> = (response?.responseDictionary)!
            let datadict :  Dictionary<String,Any> = dict["data"] as! Dictionary<String, Any>
            var keysArray : [String] = [String]()
            
            for (key,_) in datadict{
                keysArray.append(key)
            }
            
            for i in 0 ..< keysArray.count
            {
                let key = keysArray[i]
                print(key)
                if key != "background"{
                    if key != "message"{
                        let middledict : Dictionary<String,Any> = datadict[key] as! Dictionary<String, Any>
                        self.appDelegate.nistImgWidthDict.updateValue(middledict["width"] as! CGFloat, forKey: key)
                        self.appDelegate.nistImgHeightDict.updateValue(middledict["height"] as! CGFloat, forKey: key)
                        
                        let templatedict : Dictionary<String,Any>  = middledict["templates"] as! Dictionary<String, Any>
                        if templatedict["PNG"] != nil{
                            let pngvalue = templatedict["PNG"] as! String
                            let pngData = pngvalue.data(using: .utf8)
                            let data = Data(base64Encoded: pngData!)
                            UserDefaults.standard.set(data, forKey: "selfie")
                            self.appDelegate.nistFaceDict.updateValue(data!, forKey: key)
                            self.generateTemplates(filename: key, data: data, type: "Enroll", fileExtension: "png")
                        }
                    }else {
                        DLog("Moved back", "")
                    }
                }else {
                    DLog("Moved back", "")
                }
            }
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let nextvc = storyboard.instantiateViewController(withIdentifier: "SelfieCapturedViewController")
            nextvc.modalPresentationStyle = .fullScreen
            self.present(nextvc, animated: true)
        } onAttempts: { responseAttempts in
            
        }
    }
    
    func generateTemplates(filename:String, data:Data?, type:String, fileExtension:String){
        var name:String! = ""
        name = "Face"
        let defaults = UserDefaults.standard
        let token = defaults.integer(forKey: "FileCount")
        let path = "Template/\(type)_\(token.description)"
        let doumentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        self.createFolder(foldername: path)
        if let data = data {
            let filename = doumentDirectoryPath.appendingPathComponent("/\(self.selectedType.selectedPathString)/\(path.description)/\(name.description).\(fileExtension.description)")
            let fileurl = URL.init(fileURLWithPath: filename)
            try? data.write(to: fileurl)
            
        }
    }
    
    func createFolder(foldername:String){
        let fileManager = FileManager.default
        if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dirPath =  tDocumentDirectory.appendingPathComponent("/IdentyFace")
            
            let filePath =  dirPath.appendingPathComponent("\(foldername)")
            if !fileManager.fileExists(atPath: filePath.path) {
                do {
                    try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    NSLog("Couldn't create document directory")
                }
            }
            NSLog("Document directory is \(filePath)")
        }
    }
}
