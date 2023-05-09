//
//  ScanMRZViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 01/11/22.
//

import UIKit
import DocumentReader

class ScanMRZViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var loaderContainer: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var vcTitle: UILabel!
    @IBOutlet weak var passportLabel: UILabel!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var recomendationsLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    var isCustomUILayerEnabled: Bool = false
    
    override func viewDidLoad() {
        setTexts()
        DocumentReaderService.shared.initializeDatabaseAndAPI(progress: { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .downloadingDatabase(progress: let progress):
                let progressValue = String(format: "%.1f", progress * 100)
                self.statusLabel.text = "Downloading database: \(progressValue)%"
            case .initializingAPI:
                self.statusLabel.text = "Initializing..."
                self.activityIndicator.stopAnimating()
                print("")
            case .completed:
                self.enableUserInterfaceOnSuccess()
            case .error(let text):
                self.statusLabel.text = text
                self.enableUserInterfaceOnSuccess()
                print(text)
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if UserDefaults.standard.bool(forKey: "otraFoto") {
            showCamera()
            UserDefaults.standard.set(false, forKey: "otraFoto")
        }
    }
    
    @IBAction func startScan(_ sender: Any) {
        showCamera()
    }
    
    func setTexts() {
        vcTitle.text = NSLocalizedString("passport_vc_title", comment: "")
        passportLabel.text = NSLocalizedString("passport_title", comment: "")
        instructionsLabel.text = NSLocalizedString("take_picture", comment: "")
        recomendationsLabel.text = NSLocalizedString("avoid_light_shadow", comment: "")
        continueButton.setTitle(NSLocalizedString("continue_button", comment: ""), for: .normal)
    }
    
    private func enableUserInterfaceOnSuccess() {
        loaderContainer.isHidden = true
        for scenario in DocReader.shared.availableScenarios {
            print(scenario)
        }
        DocReader.shared.processParams.checkHologram = false
        DocReader.shared.processParams.scenario = RGL_SCENARIO_MRZ_AND_LOCATE
    }
    
    private func showCamera() {
        DocReader.shared.processParams.checkHologram = false
        DocReader.shared.showScanner(self) { [weak self] (action, result, error) in
            guard let self = self else { return }
            
            switch action {
            case .complete, .processTimeout:
                self.stopCustomUIChanges()
                guard let opticalResults = result else { return }
                self.showResultScreen(opticalResults)
            case .process:
                guard let result = result else { return }
                print("Scanning not finished. Result: \(result)")
            case .morePagesAvailable:
                print("This status couldn't be here, it uses for -recognizeImage function")
            case .cancel:
                self.stopCustomUIChanges()
                print("Canceled by user")
            case .error:
                self.stopCustomUIChanges()
                print("Error")
                guard let error = error else { return }
                print("Error string: \(error)")
            default:
                break
            }
        }
    }
    
    private func stopCustomUIChanges() {
        isCustomUILayerEnabled = false
        DocReader.shared.customization.customUILayerJSON = nil
    }
    
    private func showResultScreen(_ results: DocumentReaderResults) {
        if ApplicationSettings.shared.isDataEncryptionEnabled {
            statusLabel.text = "Decrypting data..."
            activityIndicator.startAnimating()
            loaderContainer.isHidden = false
            processEncryptedResults(results) { decryptedResult in
                DispatchQueue.main.async {
                    self.loaderContainer.isHidden = true
                    
                    guard let results = decryptedResult else {
                        print("Can't decrypt result")
                        return
                    }
                    self.presentResults(results)
                }
            }
        } else {
            parseResults(results)
            presentResults(results)
        }
    }
    
    private func presentResults(_ results: DocumentReaderResults) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let passCapVC = storyboard.instantiateViewController(withIdentifier: "PassportCapturedViewController")
        passCapVC.modalPresentationStyle = .fullScreen
        present(passCapVC, animated: true)
    }
    
    private func processEncryptedResults(_ encrypted: DocumentReaderResults, completion: ((DocumentReaderResults?) -> (Void))?) {
        let json = encrypted.rawResult
        
        let data = Data(json.utf8)
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                guard let containers = json["ContainerList"] as? [String: Any] else {
                    completion?(nil)
                    return
                }
                guard let list = containers["List"] as? [[String: Any]] else {
                    completion?(nil)
                    return
                }
                
                let processParam:[String: Any] = [
                    "scenario": RGL_SCENARIO_FULL_PROCESS,
                    "alreadyCropped": true
                ]
                let params:[String: Any] = [
                    "List": list,
                    "processParam": processParam
                ]
                
                guard let jsonData = try? JSONSerialization.data(withJSONObject: params, options: []) else {
                    completion?(nil)
                    return
                }
                sendDecryptionRequest(jsonData) { result in
                    completion?(result)
                }
            }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
    }
    
    private func sendDecryptionRequest(_ jsonData: Data, _ completion: ((DocumentReaderResults?) -> (Void))? ) {
        guard let url = URL(string: "https://api.regulaforensics.com/api/process") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            guard let jsonData = data else {
                completion?(nil)
                return
            }
            
            let decryptedResult = String(data: jsonData, encoding: .utf8)
                .flatMap { DocumentReaderResults.initWithRawString($0) }
            completion?(decryptedResult)
        })

        task.resume()
    }
    
    private func parseResults(_ results: DocumentReaderResults) {
        let usDef = UserDefaults.standard
        for textField in results.textResult.fields {
            guard let value = results.getTextFieldValueByType(fieldType: textField.fieldType, lcid: textField.lcid) else { continue }
            switch textField.fieldName {
            case NSLocalizedString("res_given_name", comment: ""):
                usDef.setValue(value, forKey: "nombresOCR")
            case NSLocalizedString("res_surname", comment: ""):
                usDef.setValue(value, forKey: "apellidosOCR")
            case NSLocalizedString("res_date_of_birth", comment: ""):
                usDef.setValue(value, forKey: "dobOCR")
            case NSLocalizedString("res_date_of_expiry", comment: ""):
                usDef.setValue(value, forKey: "doeOCR")
            case NSLocalizedString("res_document_number", comment: ""):
                usDef.setValue(value, forKey: "pasaporteOCR")
            default:
                continue
            }
        }
        
        for graphicField in results.graphicResult.fields {
            guard let value = results.getGraphicFieldByType(fieldType: graphicField.fieldType, source: .images) else { continue }
                    print("fieldName: \(graphicField.fieldName), value: \(value)")
        }
        
        let docImage = results.getGraphicFieldImageByType(fieldType: .gf_DocumentImage, source: .rawImage, pageIndex: 0, light: .white)
        usDef.set(docImage?.pngData(), forKey: "imagenDoc")
    }
}
