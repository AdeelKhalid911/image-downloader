//
//  CatalogJsonParser.swift
//  ImageDownloader
//
//  Created by Adeel Khalid on 10/27/18.
//  Copyright © 2018 Adeel Khalid. All rights reserved.
//

import UIKit

class ServerController: NSObject
{
    let MAX_RETRY_COUNT = 3;
    let MAX_CONCURRENT_REQUESTS = 4;
    let catalogParser = CatalogJsonParser()
    
    static let sharedInstance : ServerController = ServerController()
    var countdownTimer:Timer!
    var pendingRequestQueue       = [Constants.QUEUE_TYPE:[ServerRequestModel]]()
    var inprogressRequestQueue    = [Constants.QUEUE_TYPE:[ServerRequestModel]]()
    var statusQueue               = [Constants.QUEUE_TYPE:Constants.QUEUE_STATUS]()
    
    var cacheData                = [String:Data]()
    var cacheImages              = [String:UIImage]()
    
    let config = URLSessionConfiguration.default
    var urlSession:URLSession? = nil
    
    // MARK: private methods
    override init()
    {
        super.init()
        self.initialize()
    }
    
    func initialize()
    {
        startTicker()
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        urlSession = URLSession.init(configuration: config)
        self.setQueueStatus(status: .playing, queue: .main)
        self.setQueueStatus(status: .playing, queue: .images)
    }
    
    public func ResetServerData()
    {
        cacheData.removeAll()
        cacheImages.removeAll()
    }
    
    @objc private func dispatchPendingRequests() -> Void
    {
        for type in pendingRequestQueue.keys
        {
            if(statusQueue[type] == .playing)
            {
                if(pendingRequestQueue[type]!.count > 0)
                {
                    let inprogressRequestCount = self.queueSize(queueType:type,queue: &inprogressRequestQueue)
                    while(inprogressRequestCount < MAX_CONCURRENT_REQUESTS && pendingRequestQueue[type]!.count > 0)
                    {
                        let index = self.selectPendingRequest(pendingRequestList:pendingRequestQueue[type]!)
                        if(index != nil){
                            let request = pendingRequestQueue[type]![index!]
                            pendingRequestQueue[type]!.remove(at: index!)
                            self.insertInProgressQueue(request: request)
                            dispatchRequest(request : request)
                        }
                    }
                }
            }
        }
    }
    
    private func selectPendingRequest( pendingRequestList:[ServerRequestModel])->Int?
    {
        let index   = pendingRequestList.index{$0.requestType == .catalog || $0.requestType == .image }
        if(index != nil)
        {
            return index
        }
        return nil
    }
    
    private func createUrlRequest(request:ServerRequestModel) -> URLRequest?
    {
        let url : URL? =  URL(string: request.url)
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = getRequestType(requestModel: request)
        urlRequest.httpBody   = request.requestData
        return urlRequest
    }
    
    private func dispatchRequest(request:ServerRequestModel)
    {
        print("REQUEST ERROR : " + String(describing: request.requestType))
        let url : URL? =  URL(string: request.url)
        if(url == nil)
        {
            request.dispatchFailureCallback(error:"request url is nil")
            self.removeRequestFromInprogressQueue(request:request)
            return
        }
        
        let urlRequest = createUrlRequest(request:request)
        if urlRequest == nil { return}
        
        urlSession?.dataTask(with:urlRequest!, completionHandler: {(data, response, error) -> Void in
            if let err = error as NSError!//, err.domain == NSURLErrorDomain && err.code == NSURLErrorNotConnectedToInternet
            {
                request.retryCount+=1
                if(request.retryCount >= self.MAX_RETRY_COUNT)
                {
                    //remove request
                    request.dispatchFailureCallback(error:err.domain)
                    self.removeRequestFromInprogressQueue(request:request)
                }
                else
                {
                    //retry till max retry count
                    self.dispatchRequest(request : request)
                    //HelperMethod.Logs(message: "retrying request")
                }
            }
            else
            {
                if(data == nil)
                {
                    // if response data is currupt or nil
                    request.dispatchFailureCallback(error:"url reponse is nil:" + request.url + " at " + request.info)
                    self.removeRequestFromInprogressQueue(request:request)
                    return
                }
                
                var reponseData:Any?
                reponseData = self.updateCache(request: request,data: data!)
                //let chatMetaModel:ChatMetaModel? = (reponseData as! ChatDataModel).ChatMetaDataModel
                
                if(reponseData == nil)
                {
                    // if response data is currupt or nil
                    request.dispatchFailureCallback(error:"url reponse is nil:" + request.url + " at " + request.info)
                    self.removeRequestFromInprogressQueue(request:request)
                    return
                }
                // request completed successfully
                self.dispatchSucessResponse(request: request,reponse: reponseData!)
                self.removeRequestFromInprogressQueue(request:request)
                // HelperMethod.Logs(message: "downloaded successfull")
            }
        }).resume()
    }
    
    
    private func dispatchSucessResponse(request:ServerRequestModel, reponse:Any)
    {
        //success
        switch(request.requestType!)
        {
        case .catalog:  self.catalogSuccess(request: request,data: reponse)
            break
        case .image:    request.dispatchSuccessCallback(response:reponse)
            break
        }
    }
    
    // MARK: cache methods
    private func updateCache(request:ServerRequestModel,data:Data)-> Any?
    {
        var dataObject : Any!
        switch(request.requestType!)
        {
        case .catalog:
            dataObject = data
            self.cacheData[request.url] = data
            break
        case .image:
            if let image = UIImage (data: data)
            {
                self.cacheImages[request.url] = image
                dataObject = image
            }
            break
        }
        return dataObject;
    }
    
    private func existInCache(request:ServerRequestModel) -> Bool
    {
        switch(request.requestType!)
        {
        case .catalog:    return self.cacheData[request.url] == nil ?  false : true
        case .image:      return self.checkImageInCache(url: request.url)
        }
    }
    
    private func checkImageInCache(url:String) -> Bool
    {
        if(self.cacheImages[url] == nil ?  false : true)
        {
            return self.cacheImages[url] == nil ?  false : true
        }
        return false
    }
    
    
    private func getFromCache(request:ServerRequestModel) -> Any?
    {
        switch(request.requestType!)
        {
        case .catalog:    return self.cacheData[request.url]
        case .image:      return self.getImageFromCache(url: request.url)
        }
    }
    
    private func getImageFromCache(url:String) -> UIImage
    {
//        if(self.cacheImages[url] != nil)
//        {
            return self.cacheImages[url]!
//        }

    }
    
    // MARK: helper methods
    private func existsInQueue(request:ServerRequestModel, queue:inout [Constants.QUEUE_TYPE:[ServerRequestModel]])->Bool
    {
        if let requests = queue[request.queue!] {
            return requests.contains{ $0.url == request.url}
        }
        else
        {
            return false
        }
    }
    
    private func queueSize(queueType:Constants.QUEUE_TYPE, queue:inout[Constants.QUEUE_TYPE:[ServerRequestModel]])->Int
    {
        if let requests = queue[queueType]{
            return requests.count
        }
        else{
            return 0
        }
    }
    
    private func insertInPendingQueue(request:ServerRequestModel,index:Int = 0)
    {
        if pendingRequestQueue[request.queue!] != nil {
            pendingRequestQueue[request.queue!]!.insert(request, at: index)
        }
        else {
            pendingRequestQueue[request.queue!] = [request]
        }
        printLogs()
    }
    
    private func insertInProgressQueue(request:ServerRequestModel,index:Int = 0)
    {
        if inprogressRequestQueue[request.queue!] != nil {
            inprogressRequestQueue[request.queue!]!.insert(request, at: index)
        }
        else {
            inprogressRequestQueue[request.queue!] = [request]
        }
    }
    
    private func removeRequestFromInprogressQueue(request: ServerRequestModel)
    {
        if inprogressRequestQueue[request.queue!] != nil {
            if let index = inprogressRequestQueue[request.queue!]!.index(where: {$0.url == request.url}) {
                inprogressRequestQueue[request.queue!]!.remove(at:index)
                printLogs()
            }
        }
    }
    
    private func printLogs()
    {
        for queueType in statusQueue.keys {
            if  statusQueue[queueType] == .playing {
                print("Queue Active = " + String(describing: queueType))
                
                var requests = 0
                if pendingRequestQueue[queueType] != nil {
                    requests += pendingRequestQueue[queueType]!.count
                }
                if inprogressRequestQueue[queueType] != nil {
                    requests += inprogressRequestQueue[queueType]!.count
                }
                print("request Count = ",requests)
            }
        }
    }
    
    // MARK: public methods
    public func sendRequest(request:ServerRequestModel) -> Void
    {
        let existInCache           = request.useCache == true ? self.existInCache(request:request) : false
        let existInPendingRequest  = request.useCache == true ? self.existsInQueue(request:request,queue: &pendingRequestQueue) : false
        let existInProgressRequest = request.useCache == true ? self.existsInQueue(request:request,queue: &inprogressRequestQueue) : false
        
        if(existInCache)
        {
            let val = self.getFromCache(request: request)
            if(request.requestType == .image)
            {
                if(!checkImageInCache(url: request.url))
                {
                    request.dispatchSuccessCallback(response:val!)
                }
                else
                {
                    request.dispatchSuccessCallback(response:val!)
                }
            }
            else
            {
                request.dispatchSuccessCallback(response:val!)
            }
        }
        else if(existInPendingRequest == true)
        {
            request.dispatchNotFoundInCache()
            let index   = pendingRequestQueue[request.queue!]!.index{$0.url == request.url}
            let pendingRequest = pendingRequestQueue[request.queue!]![index!]
            pendingRequest.AppendCallbacks(newsuccessCallback: request.successCallback, newfailureCallback: request.failureCallback, cacheFailureCallback: request.cacheFailureCallback)
        }
        else if(existInProgressRequest == true)
        {
            request.dispatchNotFoundInCache()
            let index   = inprogressRequestQueue[request.queue!]!.index{$0.url == request.url}
            let pendingRequest = inprogressRequestQueue[request.queue!]![index!];
            pendingRequest.AppendCallbacks(newsuccessCallback: request.successCallback, newfailureCallback: request.failureCallback,cacheFailureCallback: request.cacheFailureCallback)
        }
        else
        {
            request.dispatchNotFoundInCache()
            self.insertInPendingQueue(request: request)
        }
    }
    
    func startTicker()
    {
        countdownTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(dispatchPendingRequests), userInfo: nil, repeats: true)
    }
    
    // MARK: fetch catalog
    func fetchCatalog(onSuccess:((_:ServerRequestModel, _:Any) -> Void)?, onFailure:((_:ServerRequestModel,_:String) -> Void)?)
    {
        let catalogURL = Constants.catalogURL
        
        let request = ServerRequestModel.create(type:REQUEST_TYPE.catalog, requestUrl: catalogURL, successCallbackFunc: onSuccess, failureCallbackFunc: onFailure,useLocalCache: true,info:"fetch_catalogue")
        self.sendRequest(request: request)
    }
    
    private func catalogSuccess(request:ServerRequestModel, data:Any) -> Void
    {
        catalogParser.ParseCatalogData(request:request ,data: data as! Data)
    }
    
    func queueCompleted(queue:Constants.QUEUE_TYPE)->Bool
    {
        var pendingCompleted    = true
        var inProgressCompleted = true
        
        if pendingRequestQueue[queue] != nil {
            pendingCompleted = pendingRequestQueue[queue]!.count > 0 ? false : true
        }
        
        if inprogressRequestQueue[queue] != nil {
            inProgressCompleted = inprogressRequestQueue[queue]!.count > 0 ? false : true
        }
        return pendingCompleted && inProgressCompleted
    }
    
    func setQueueStatus(status:Constants.QUEUE_STATUS,queue:Constants.QUEUE_TYPE, disableOtherQueues:Bool = false)
    {
        if disableOtherQueues {
            for queueType in statusQueue.keys {
                if queueType != queue && queueType != .main {
                    statusQueue[queueType] = .paused
                }
            }
        }
        statusQueue[queue] = status
    }
    
    func getQueueStatus(queueType:Constants.QUEUE_TYPE)->Constants.QUEUE_STATUS
    {
        if (statusQueue[queueType] != nil) {
            return statusQueue[queueType]!
        }
        return .paused
    }

    private func getRequestType(requestModel:ServerRequestModel) -> String
    {
        return "GET"
    }
}

