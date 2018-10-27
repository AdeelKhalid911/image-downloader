//
//  TableViewCell.swift
//  ImageDownloader
//
//  Created by Adeel Khalid on 10/27/18.
//  Copyright © 2018 Adeel Khalid. All rights reserved.
//

import UIKit

class CatalogTableViewCell: UITableViewCell {

    // MARK: - Outlet Variables
    @IBOutlet weak var mainImageView: UIImageView!
    
    // MARK: - Private Variables
    let info = "Catalog_MainImage:"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func initialize(model: UserProfileModel)
    {
        let request = ServerRequestModel.create(type: .image, requestUrl: String(model.urls_raw), successCallbackFunc: OnImageDownloadSuccess,cacheFailureCallbackFunc:OnImageCacheFailure,  failureCallbackFunc: OnImageDownloadFailure,info:info, queue:.images)
        ServerController.sharedInstance.sendRequest(request: request)
    }
    
    // MARK: - image callbacks
    func OnImageDownloadSuccess(request:ServerRequestModel,data:Any)
    {
        HelperMethods.setImageView(imageView:self.mainImageView, image:(data as! UIImage))
    }
    
    func OnImageCacheFailure(request:ServerRequestModel)
    {
        HelperMethods.setImageView(imageView:self.mainImageView)
    }
    
    func OnImageDownloadFailure(request:ServerRequestModel,error:String)
    {
        HelperMethods.setImageView(imageView:self.mainImageView)
    }

}
