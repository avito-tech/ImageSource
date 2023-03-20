public struct ImageRequestOptions {
    
    public var size: ImageSizeOption
    public var deliveryMode: ImageDeliveryMode
    public var version: ImageRequestOptionsVersion
    public let needsMetadata: Bool
    
    /// Called on main thread when image download starts
    public var onDownloadStart: ((ImageRequestId) -> ())?
    /// Called on main thread when image download finishes
    public var onDownloadFinish: ((ImageRequestId) -> ())?
        
    public init(
        size: ImageSizeOption = .fullResolution,
        deliveryMode: ImageDeliveryMode = .best,
        version: ImageRequestOptionsVersion = .original,
        needsMetadata: Bool = false
    ) {
        self.size = size
        self.deliveryMode = deliveryMode
        self.version = version
        self.needsMetadata = needsMetadata
    }
}
