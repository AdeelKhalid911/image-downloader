//
//  CatalogJsonParser.swift
//  ImageDownloader
//
//  Created by Adeel Khalid on 10/27/18.
//  Copyright © 2018 Adeel Khalid. All rights reserved.
//

import UIKit

class CatalogJsonParser: NSObject
{
    let uslsKey:String = "urls"
    let imageTypeKey:String = "regular"
    
    public func ParseCatalogData(request:ServerRequestModel ,data : Data) -> Void
    {
        let listOfObjects = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! Array<Any>
        if(listOfObjects != nil)
        {
            for i in (0..<listOfObjects!.count)
            {
                let urls = (listOfObjects![i] as AnyObject).value(forKey: self.uslsKey)! as! NSDictionary
                let userProfile = UserProfileModel()
                userProfile.urls_raw = urls.value(forKey: self.imageTypeKey) as! String
                ApplicationModelController.sharedInstance.userProfileList.append(userProfile)
            }
            OperationQueue.main.addOperation({
                request.dispatchSuccessCallback(response: data)
            })
        }
        else
        {
            OperationQueue.main.addOperation({
                request.dispatchFailureCallback(error: "Invalid catalog response from server")
            })
        }
    }

}
