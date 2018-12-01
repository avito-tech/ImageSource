import Foundation
import ImageIO
import MobileCoreServices
import CoreLocation

/// Operation for requesting images stored in a local file.
final class LocalImageRequestOperation<T: InitializableWithCGImage>: Operation, ImageRequestIdentifiable {
    
    let id: ImageRequestId
    
    private let path: String
    private let options: ImageRequestOptions
    private let callbackQueue: DispatchQueue
    private let location: CLLocation?
    private let resultHandler: (ImageRequestResult<T>) -> ()
    
    // Можно сделать failable/throwing init, который будет возвращать nil/кидать исключение, если url не файловый,
    // но пока не вижу в этом особой необходимости
    init(id: ImageRequestId,
         path: String,
         options: ImageRequestOptions,
         callbackQueue: DispatchQueue = .main,
         location: CLLocation? = nil,
         resultHandler: @escaping (ImageRequestResult<T>) -> ()
        )
    {
        self.id = id
        self.path = path
        self.options = options
        self.callbackQueue = callbackQueue
        self.location = location
        self.resultHandler = resultHandler
    }
    
    override func main() {
        switch options.size {
        case .fullResolution:
            getFullResolutionImage()
        case .fillSize(let size):
            getImage(resizedTo: size)
        case .fitSize(let size):
            getImage(resizedTo: size)
        }
    }
    
    // MARK: - Private
    
    private func getFullResolutionImage() {
        
        guard !isCancelled else { return }
        let url = NSURL(fileURLWithPath: path)
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        let source = CGImageSourceCreateWithURL(url, sourceOptions)
        
        let cfProperties = source.flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) }
        var imageMetadata = cfProperties as [NSObject: AnyObject]? ?? [:]
        
        let orientation = imageMetadata[kCGImagePropertyOrientation] as? Int
        let gpsMeta = GPSMetadataExtractor.gpsMetaFromLocation(location)
        imageMetadata.merge(gpsMeta) { current, _ in current }
        
        let imageCreationOptions = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
        
        guard !isCancelled else { return }
        var cgImage = source.flatMap { CGImageSourceCreateImageAtIndex($0, 0, imageCreationOptions) }
        
        if let exifOrientation = orientation.flatMap({ ExifOrientation(rawValue: $0) }) {
            guard !isCancelled else { return }
            cgImage = cgImage?.imageFixedForOrientation(exifOrientation)
        }
        
        guard !isCancelled else { return }
        callbackQueue.async { [resultHandler, id] in
            resultHandler(ImageRequestResult(
                image: cgImage.flatMap { T(cgImage: $0) },
                degraded: false,
                requestId: id,
                metadata: ImageMetadata(self.options.needsMetadata ? imageMetadata : nil)
            ))
        }
    }
    
    private func getImage(resizedTo size: CGSize) {
        guard !isCancelled else { return }
        
        let url = NSURL(fileURLWithPath: path)
        
        // WWDC 2018 Session 219, 11:00
        // We're just creating an object to represent the information stored in the file at this URL.
        // Don't go ahead and decode this image immediately.
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        
        let source = CGImageSourceCreateWithURL(url, sourceOptions)
        var imageMetadata = [NSObject: AnyObject]()
        
        if self.options.needsMetadata {
            let cfProperties = source.flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) }
            imageMetadata = cfProperties as [NSObject: AnyObject]? ?? [:]
            let gpsMeta = GPSMetadataExtractor.gpsMetaFromLocation(location)
            imageMetadata.merge(gpsMeta) { current, _ in current }
        }
        
        let options: [NSString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height),
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            
            // WWDC 2018 Session 219, 11:30
            // Decoded image buffer will be created at the moment CGImageSourceCreateThumbnailAtIndex is called
            kCGImageSourceShouldCacheImmediately: true
        ]
        
        guard !isCancelled else { return }
        let cgImage = source.flatMap { CGImageSourceCreateThumbnailAtIndex($0, 0, options as CFDictionary) }
        
        guard !isCancelled else { return }
        callbackQueue.async { [resultHandler, id] in
            resultHandler(ImageRequestResult(
                image: cgImage.flatMap { T(cgImage: $0) },
                degraded: false,
                requestId: id,
                metadata: ImageMetadata(imageMetadata)
            ))
        }
    }
}

private final class GPSMetadataExtractor {
    
    static func gpsMetaFromLocation(_ location: CLLocation?) -> [NSString: AnyObject] {
        guard let coordinate = location?.coordinate else {
            return [:]
        }
        let latitudeRef = coordinate.latitude < 0.0 ? "S" : "N"
        let longitudeRef = coordinate.longitude < 0.0 ? "W" : "E";
        
        let dict: [NSString: AnyObject] = ["GPSLatitude": coordinate.latitude as AnyObject,
                                           "GPSLatitudeRef": latitudeRef as AnyObject,
                                           "GPSLongitude": coordinate.longitude as AnyObject,
                                           "GPSLongitudeRef": longitudeRef as AnyObject]
        return ["GPS": dict as AnyObject]
    }
}
