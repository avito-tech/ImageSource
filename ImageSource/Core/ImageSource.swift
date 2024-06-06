import Foundation

import CoreGraphics

public protocol ImageSource: AnyObject {
    
    /**
     - Parameter resultHandler: Closure that is called when image is received or when image retreivement fails.
       - called on main thread
       - called at least once if the request is not cancelled
       - not called after request cancellation
       - called at most once if options.deliveryMode == .best
       - may be called more than once if options.deliveryMode == .progressive
       - may be called syncronously before functions returns
     */
    @discardableResult
    func requestImage<T: InitializableWithCGImage>(
        options: ImageRequestOptions,
        resultHandler: @escaping (ImageRequestResult<T>) -> ())
        -> ImageRequestId
    
    func cancelRequest(_: ImageRequestId)
    
    /*
     TODO: change `completion` parameter to enum, one case of which must indicate that there's no intrinsic size.
     Maybe rename it to `fullSize`.
     */
    func imageSize(completion: @escaping (CGSize?) -> ())
    
    /*
     TODO: change `completion` parameter to enum, one case of which must indicate that there's no such notion
     as full resolution for the given image source.
     Maybe rename it to `fullSizeImageData`
     */
    func fullResolutionImageData(completion: @escaping (Data?) -> ())

    func isEqualTo(_ other: ImageSource) -> Bool
}

public func ==(lhs: ImageSource?, rhs: ImageSource?) -> Bool {
    if let lhs = lhs, let rhs = rhs {
        return lhs.isEqualTo(rhs)
    } else if let _ = lhs {
        return false
    } else if let _ = rhs {
        return false
    } else {
        return true
    }
}

public func !=(lhs: ImageSource?, rhs: ImageSource?) -> Bool {
    return !(lhs == rhs)
}
