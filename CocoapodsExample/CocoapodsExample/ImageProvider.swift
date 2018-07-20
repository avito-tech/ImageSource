import ImageSource
import Photos

final class ImageProvider {
    
    /**
     This method is asynchronous because iOS can prompt user to allow access to photo library
     */
    func images(completion: @escaping ([ImageSource]) -> ()) {
        photosFromCameraRoll(completion: completion)
    }
    
    private func photosFromCameraRoll(completion: @escaping ([ImageSource]) -> ()) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            DispatchQueue.global(qos: .userInitiated).async {
                guard let cameraRoll = self.cameraRoll() else {
                    return DispatchQueue.main.async { completion([]) }
                }
                
                var images = [ImageSource]()
                let imageManager = PHImageManager()
                
                let photosFetchOptions = PHFetchOptions()
                photosFetchOptions.wantsIncrementalChangeDetails = false
                photosFetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
                
                let photosFetchResult = PHAsset.fetchAssets(in: cameraRoll, options: photosFetchOptions)
                photosFetchResult.enumerateObjects { asset, _, _ in
                    images.append(PHAssetImageSource(asset: asset, imageManager: imageManager))
                }
                
                DispatchQueue.main.async {
                    completion(images)
                }
            }
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { _ in
                self.photosFromCameraRoll(completion: completion)
            }
        case .denied, .restricted:
            completion([])
        }
    }
    
    private func cameraRoll() -> PHAssetCollection? {
        
        let cameraRollFetchOptions = PHFetchOptions()
        cameraRollFetchOptions.wantsIncrementalChangeDetails = false
        
        if #available(iOS 9.0, *) {
            cameraRollFetchOptions.fetchLimit = 1
        }
        
        let cameraRollFetchResult = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumUserLibrary,
            options: cameraRollFetchOptions
        )
        
        return cameraRollFetchResult.firstObject
    }
}
