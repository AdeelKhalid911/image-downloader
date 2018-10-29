import Foundation
import UIKit

class Constants
{
    enum QUEUE_TYPE
    {
        case main       // used for downloading json,
        case images     // used for downloading images
    }
    
    enum QUEUE_STATUS
    {
        case paused
        case playing
    }
    
    static var catalogURL:String = "https://pastebin.com/raw/wgkJgazE"
    static var Main : String = "Main"
    static var CatalogView : String = "CatalogView"
    static var CatalogCell : String = "CatalogCell"
    
    static var cacheImageSize : Int = 10 // Size is in number of images, that can be cached.

}
