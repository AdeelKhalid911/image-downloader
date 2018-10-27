//
//  CatalogJsonParser.swift
//  ImageDownloader
//
//  Created by Adeel Khalid on 10/27/18.
//  Copyright © 2018 Adeel Khalid. All rights reserved.
//

import Foundation
import UIKit

public enum REQUEST_TYPE
{
    case catalog
    case image
}

class ServerRequestModel
{
    // MARK: vairables and method declaration
    var info : String = ""
    var useCache = true
    var url = ""
    var retryCount = 0
    var requestType : REQUEST_TYPE?
    var requestData : Data?
    var queue : Constants.QUEUE_TYPE?
    
    var successCallback      : ((_:ServerRequestModel,_:Any)    -> Void)?
    var cacheFailureCallback : ((_:ServerRequestModel)          -> Void)?
    var failureCallback      : ((_:ServerRequestModel,_:String) -> Void)?
    
    var duplicateSuccessCallback        : Array< ((_:ServerRequestModel,_:Any)     -> Void) >?
    var duplicateCacheFailureCallback   : Array< ((_:ServerRequestModel)           -> Void) >?
    var duplicateFailureCallback        : Array< ((_:ServerRequestModel,_:String)  -> Void) >?
    
    // MARK: private methods
    // MARK: public methods
    static func create(type:REQUEST_TYPE, requestUrl:String, successCallbackFunc:((_:ServerRequestModel,_:Any) -> Void)?,cacheFailureCallbackFunc:((_:ServerRequestModel) -> Void)? = nil,failureCallbackFunc:((_:ServerRequestModel,_:String) -> Void)?,useLocalCache:Bool = true,info:String, queue:Constants.QUEUE_TYPE = .main) -> ServerRequestModel
    {
        let request = ServerRequestModel()
        request.info            = info
        request.requestType     = type
        request.retryCount      = 0
        request.url             = requestUrl
        request.useCache        = useLocalCache
        request.queue           = queue
        request.successCallback = successCallbackFunc
        request.cacheFailureCallback = cacheFailureCallbackFunc
        request.failureCallback      = failureCallbackFunc
        
        request.duplicateSuccessCallback        = nil
        request.duplicateCacheFailureCallback   = nil
        request.duplicateFailureCallback        = nil
        return request
    }
    
    func dispatchSuccessCallback(response:Any)
    {
        DispatchQueue.main.async {
            self.successCallback?(self,response);
            if(self.duplicateSuccessCallback != nil && self.duplicateSuccessCallback!.count > 0)
            {
                for callback in self.duplicateSuccessCallback!
                {
                    callback(self,response)
                }
            }
        }
    }
    
    func dispatchNotFoundInCache()
    {
        DispatchQueue.main.async {
            self.cacheFailureCallback?(self);
            if(self.duplicateCacheFailureCallback != nil && self.duplicateCacheFailureCallback!.count > 0)
            {
                for callback in self.duplicateCacheFailureCallback!
                {
                    callback(self)
                }
            }
        }
    }
    
    func dispatchFailureCallback(error:String)
    {
        DispatchQueue.main.async {
            self.failureCallback?(self,error);
            if(self.duplicateFailureCallback != nil && self.duplicateFailureCallback!.count > 0)
            {
                for callback in self.duplicateFailureCallback!
                {
                    callback(self,error)
                }
            }
        }
    }
    
    func AppendCallbacks(newsuccessCallback : ((_:ServerRequestModel,_:Any) -> Void)?, newfailureCallback : ((_:ServerRequestModel,_:String) -> Void)?,cacheFailureCallback : ((_:ServerRequestModel) -> Void)?)
    {
        if(duplicateSuccessCallback == nil)
        {
            duplicateSuccessCallback = Array< ((_:ServerRequestModel,_:Any) -> Void)>()
            duplicateFailureCallback = Array< ((_:ServerRequestModel,_:String) -> Void) >()
            duplicateCacheFailureCallback = Array< ((_:ServerRequestModel) -> Void) >()
            
        }
        
        if(newsuccessCallback != nil)
        {
            duplicateSuccessCallback?.append(newsuccessCallback!)
        }
        if(newfailureCallback != nil)
        {
            duplicateFailureCallback?.append(newfailureCallback!)
        }
        if(cacheFailureCallback != nil)
        {
            duplicateCacheFailureCallback?.append(cacheFailureCallback!)
        }
    }
}

