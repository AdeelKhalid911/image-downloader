//
//  HelperMethods.swift
//  ImageDownloader
//
//  Created by Adeel Khalid on 10/27/18.
//  Copyright © 2018 Adeel Khalid. All rights reserved.
//

import UIKit

class HelperMethods: NSObject
{
    static func setImageView(imageView:UIImageView, image:UIImage? = nil, duration:Float = 0.2)
    {
        
        DispatchQueue.main.async
            {
                imageView.layer.removeAllAnimations()
                UIView.transition(with: imageView,
                                  duration:TimeInterval(duration),
                                  options: .transitionCrossDissolve,
                                  animations: { imageView.image = image },
                                  completion: nil)
        }
    }
}
