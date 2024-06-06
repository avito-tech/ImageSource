import Foundation

public struct ImageMetadata {
    
    public let metadata: [String: Any]
    
    public init() {
        metadata = [:]
    }
    
    public init(_ metadata: [String: Any]?) {
        self.metadata = ImageMetadata.filteredAsJSONSerializable(metadata ?? [:])
    }
    
    public init(_ metadata: [NSObject: AnyObject]?) {
        self.metadata = ImageMetadata.convertObjcMetadata(metadata)
    }
    
    // MARK: - Private
    
    private static func convertObjcMetadata(_ objcMetadata: [NSObject: AnyObject]?) -> [String: Any] {
        guard let objcMetadata = objcMetadata else { return [:] }
        
        var result = [String: Any]()
        for (key, value) in objcMetadata {
            guard let key = key as? String else { continue }
            
            if let nested = value as? [NSObject: AnyObject] {
                result[key] = ImageMetadata.convertObjcMetadata(nested) as Any
            } else if JSONSerialization.isValidJSONObject([value]) { // Meta must contain only JSON serializable items
                result[key] = value as Any
            }
        }
        return result
    }
    
    private static func filteredAsJSONSerializable(_ metadata: [String: Any]) -> [String: Any] {
        var result = [String: Any]()
        for (key, value) in metadata {
            if let nested = value as? [String: Any] {
                result[key] = ImageMetadata.filteredAsJSONSerializable(nested) as Any
            } else if JSONSerialization.isValidJSONObject([value]) {
                result[key] = value as Any
            }
        }
        return result
    }
}
