//
//  ViewController.swift
//  ImageDownloader
//
//  Created by Adeel Khalid on 10/27/18.
//  Copyright © 2018 Adeel Khalid. All rights reserved.
//

import UIKit

class SplashViewController : UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.fetchCatalog()
    }

    func fetchCatalog()
    {
        ServerController.sharedInstance.fetchCatalog(onSuccess: onCatalogDownloadSuccess, onFailure: onCatalogDownloadFailure)
    }
    
    // MARK: - Server Callbacks
    func onCatalogDownloadFailure(request:ServerRequestModel,error:String)
    {
        showFailureAlert()
    }
    
    func onCatalogDownloadSuccess(request:ServerRequestModel,data:Any)
    {
        showCatalog()
    }
    
    private func showFailureAlert()
    {
        let alert = UIAlertController(title: "Download Failed", message: "Couldn't download the content, check whether your device is connected to internet or not.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { _ in })
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showCatalog()
    {
        let storyboard : UIStoryboard = UIStoryboard(name: Constants.Main, bundle: nil);
        let vc : UIViewController = storyboard.instantiateViewController(withIdentifier:Constants.CatalogView) as UIViewController
        self.present(vc, animated: true, completion: {})
    }
}

