import Photos

public final class PHAssetImageSource: ImageSource {

    public var asset: PHAsset {
        return loadAsset()
    }
    
    private let loadAsset: () -> PHAsset
    private let imageManager: PHImageManager

    public init(asset: PHAsset, imageManager: PHImageManager = PHImageManager.default()) {
        self.loadAsset = { asset }
        self.imageManager = imageManager
    }
    
    public init(
        fetchResult: PHFetchResult<PHAsset>,
        index: Int,
        imageManager: PHImageManager = PHImageManager.default())
    {
        self.loadAsset = { fetchResult.object(at: index) }
        self.imageManager = imageManager
    }

    // MARK: - AbstractImage
    
    public func fullResolutionImageData(completion: @escaping (Data?) -> ()) {
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        imageManager.requestImageData(for: loadAsset(), options: options) { data, _, _, _ in
            completion(data)
        }
    }
    
    public func imageSize(completion: @escaping (CGSize?) -> ()) {
        dispatch_to_main_queue {
            let asset = self.loadAsset()
            completion(CGSize(width: asset.pixelWidth, height: asset.pixelHeight))
        }
    }
    
    @discardableResult
    public func requestImage<T : InitializableWithCGImage>(
        options: ImageRequestOptions,
        resultHandler: @escaping (ImageRequestResult<T>) -> ())
        -> ImageRequestId
    {
        let (phOptions, size, contentMode) = imageRequestParameters(from: options)
        
        var downloadStarted = false
        var downloadFinished = false
        
        let startDownload = { (imageRequestId: ImageRequestId) in
            downloadStarted = true
            if let onDownloadStart = options.onDownloadStart {
                dispatch_to_main_queue { onDownloadStart(imageRequestId) }
            }
        }
        
        let finishDownload = { (imageRequestId: ImageRequestId) in
            downloadFinished = true
            if let onDownloadFinish = options.onDownloadFinish {
                dispatch_to_main_queue { onDownloadFinish(imageRequestId) }
            }
        }
        
        phOptions.progressHandler = { progress, _, _, info in
            let imageRequestId = (info?[PHImageResultRequestIDKey] as? NSNumber)?.int32Value ?? 0
            
            if !downloadStarted {
                startDownload(imageRequestId.toImageRequestId())
            }
            if progress == 1 /* это не reliable, читай ниже */ && !downloadFinished {
                finishDownload(imageRequestId.toImageRequestId())
            }
        }
        
        let asset = loadAsset()

        let id = imageManager.requestImage(for: asset, targetSize: size, contentMode: contentMode, options: phOptions) {
            image, info in
            
            let requestId = (info?[PHImageResultRequestIDKey] as? NSNumber)?.int32Value ?? 0
            let degraded = (info?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false
            let cancelled = (info?[PHImageCancelledKey] as? NSNumber)?.boolValue ?? false || self.cancelledRequestIds.contains(requestId.toImageRequestId()) == true
            let isLikelyToBeTheLastCallback = (image != nil && !degraded) || cancelled
            
            // progressHandler может никогда не вызваться с progress == 1, поэтому тут пытаемся угадать, завершилась ли загрузка
            if downloadStarted && !downloadFinished && isLikelyToBeTheLastCallback {
                finishDownload(requestId.toImageRequestId())
            }
            
            // resultHandler не должен вызываться после отмены запроса
            if !cancelled {
                let image = (image as? T?).flatMap { $0 } ?? image?.cgImage.flatMap { T(cgImage: $0) }
                let requestId = requestId.toImageRequestId()
                
                if isLikelyToBeTheLastCallback, options.needsMetadata {
                    self.fetchMetadataAndProcessResult(
                        image: image,
                        degraded: degraded,
                        requestId: requestId,
                        resultHandler: resultHandler
                    )
                } else {
                    resultHandler(ImageRequestResult(image: image, degraded: degraded, requestId: requestId))
                }
            }
        }
        
        return id.toImageRequestId()
    }
    
    public func cancelRequest(_ id: ImageRequestId) {
        dispatch_to_main_queue {
            self.cancelledRequestIds.insert(id)
            self.imageManager.cancelImageRequest(id.int32Value)
            if let editingRequestId = self.editingRequestMap.removeValue(forKey: id) {
                self.loadAsset().cancelContentEditingInputRequest(editingRequestId)
            }
        }
    }
    
    public func isEqualTo(_ other: ImageSource) -> Bool {
        if other === self {
            return true
        } else if let other = other as? PHAssetImageSource {
            return other.loadAsset().localIdentifier == loadAsset().localIdentifier
        } else {
            return false
        }
    }
    
    // MARK: - Private
    
    private var cancelledRequestIds = Set<ImageRequestId>()
    private var editingRequestMap = [ImageRequestId: PHContentEditingInputRequestID]()
    
    private func imageRequestParameters(from options: ImageRequestOptions)
        -> (options: PHImageRequestOptions, size: CGSize, contentMode: PHImageContentMode)
    {
        let phOptions = PHImageRequestOptions()
        phOptions.isNetworkAccessAllowed = true
        
        switch options.deliveryMode {
        case .progressive:
            phOptions.deliveryMode = .opportunistic
            phOptions.resizeMode = .fast
        case .best:
            phOptions.deliveryMode = .highQualityFormat
            phOptions.resizeMode = .exact
        }
        
        let size: CGSize
        let contentMode: PHImageContentMode
        
        switch options.size {
        case .fullResolution:
            size = PHImageManagerMaximumSize
            contentMode = .aspectFill
        case .fitSize(let sizeToFit):
            size = sizeToFit
            contentMode = .aspectFit
        case .fillSize(let sizeToFill):
            size = sizeToFill
            contentMode = .aspectFill
        }
        
        return (options: phOptions, size: size, contentMode: contentMode)
    }
    
    private func fetchMetadataAndProcessResult<T: InitializableWithCGImage>(
        image: T?,
        degraded: Bool,
        requestId: ImageRequestId,
        resultHandler: @escaping (ImageRequestResult<T>) -> ())
    {
        let editOptions = PHContentEditingInputRequestOptions()
        editOptions.isNetworkAccessAllowed = true
        
        let editingRequestId = loadAsset().requestContentEditingInput(with: editOptions) {
            contentEditingInput, info in
            
            var imageMetadata = ImageMetadata()
            if let imageUrl = contentEditingInput?.fullSizeImageURL,
                let ciImage = CIImage(contentsOf: imageUrl) {
                imageMetadata = ImageMetadata(ciImage.properties)
            }
            
            dispatch_to_main_queue {
                self.editingRequestMap.removeValue(forKey: requestId)
            }
            
            resultHandler(ImageRequestResult(
                image: image,
                degraded: degraded,
                requestId: requestId,
                metadata: imageMetadata
            ))
        }
        
        dispatch_to_main_queue {
            self.editingRequestMap[requestId] = editingRequestId
        }
    }
}

private extension PHImageContentMode {
    var debugDescription: String {
        switch self {
        case .aspectFit:
            return "AspectFit"
        case .aspectFill:
            return "AspectFill"
        }
    }
}
