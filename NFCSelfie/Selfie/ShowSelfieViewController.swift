//
//  ShowSelfieViewController.swift
//  NFCSelfie
//
//  Created by Daniel Garibay on 04/11/22.
//

import UIKit

class ShowSelfieViewController: UIViewController {
    
    @IBOutlet weak var selfieImage: UIImageView!
    
    override func viewDidLoad() {
        selfieImage.image = UIImage(data: UserDefaults.standard.data(forKey: "selfie")!)
    }
}
