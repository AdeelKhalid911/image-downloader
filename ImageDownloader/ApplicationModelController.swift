//
//  ApplicationModelController.swift
//  ImageDownloader
//
//  Created by Adeel Khalid on 10/27/18.
//  Copyright © 2018 Adeel Khalid. All rights reserved.
//

import UIKit

class ApplicationModelController: NSObject
{
    static let sharedInstance : ApplicationModelController = ApplicationModelController()
    
    var userProfileList = [UserProfileModel]()
}
