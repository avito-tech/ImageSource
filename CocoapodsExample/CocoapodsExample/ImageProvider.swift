import ImageSource
import Photos

final class ImageProvider {
    
    /**
     This method is asynchronous because iOS can prompt user to allow access to photo library
     */
    func images(completion: @escaping ([ImageSource]) -> ()) {
        
        var images = remoteDogImages()
        images.append(contentsOf: localDogImages())
        
        photosFromCameraRoll { photos in
            images.append(contentsOf: photos)
            completion(images)
        }
    }
    
    // MARK: - Getting photos from user's photo library
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
        case .limited:
            assertionFailure("`PHAuthorizationStatus.limited` is not handled in this project")
            completion([])
        @unknown default:
            assertionFailure("Unknown `PHAuthorizationStatus`")
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
    
    // MARK: - Getting remote images
    private func remoteDogImages() -> [ImageSource] {
        let urlStrings = [
            "https://images.dog.ceo/breeds/husky/n02110185_12656.jpg",
            "https://images.dog.ceo/breeds/kelpie/n02105412_3979.jpg",
            "https://images.dog.ceo/breeds/terrier-bedlington/n02093647_1514.jpg",
            "https://images.dog.ceo/breeds/bluetick/n02088632_1145.jpg",
            "https://images.dog.ceo/breeds/papillon/n02086910_5396.jpg",
            "https://images.dog.ceo/breeds/spaniel-cocker/n02102318_10178.jpg",
            "https://images.dog.ceo/breeds/deerhound-scottish/n02092002_6180.jpg",
            "https://images.dog.ceo/breeds/malinois/n02105162_2836.jpg",
            "https://images.dog.ceo/breeds/cairn/n02096177_1766.jpg",
            "https://images.dog.ceo/breeds/shihtzu/n02086240_6992.jpg",
            "https://images.dog.ceo/breeds/redbone/n02090379_4708.jpg",
            "https://images.dog.ceo/breeds/pomeranian/n02112018_12750.jpg",
            "https://images.dog.ceo/breeds/collie-border/n02106166_1842.jpg",
            "https://images.dog.ceo/breeds/cotondetulear/IMAG1063.jpeg",
            "https://images.dog.ceo/breeds/akita/Akita_Inu_dog.jpg",
            "https://images.dog.ceo/breeds/spaniel-irish/n02102973_634.jpg",
            "https://images.dog.ceo/breeds/bullterrier-staffordshire/n02093256_6077.jpg",
            "https://images.dog.ceo/breeds/kuvasz/n02104029_1816.jpg",
            "https://images.dog.ceo/breeds/lhasa/n02098413_2582.jpg",
            "https://images.dog.ceo/breeds/kuvasz/n02104029_3397.jpg",
            "https://images.dog.ceo/breeds/stbernard/n02109525_16284.jpg",
            "https://images.dog.ceo/breeds/eskimo/n02109961_6119.jpg",
            "https://images.dog.ceo/breeds/chow/n02112137_5022.jpg",
            "https://images.dog.ceo/breeds/cotondetulear/IMAG1063.jpeg",
            "https://images.dog.ceo/breeds/kelpie/n02105412_3084.jpg",
            "https://images.dog.ceo/breeds/dane-great/n02109047_21903.jpg",
            "https://images.dog.ceo/breeds/boxer/n02108089_9076.jpg",
            "https://images.dog.ceo/breeds/pointer-german/n02100236_5671.jpg",
            "https://images.dog.ceo/breeds/boxer/n02108089_1571.jpg",
            "https://images.dog.ceo/breeds/airedale/n02096051_1558.jpg",
            "https://images.dog.ceo/breeds/doberman/n02107142_11226.jpg",
            "https://images.dog.ceo/breeds/deerhound-scottish/n02092002_6625.jpg",
            "https://images.dog.ceo/breeds/bulldog-boston/n02096585_1449.jpg",
            "https://images.dog.ceo/breeds/deerhound-scottish/n02092002_14825.jpg",
            "https://images.dog.ceo/breeds/keeshond/n02112350_9717.jpg",
            "https://images.dog.ceo/breeds/pekinese/n02086079_2935.jpg",
            "https://images.dog.ceo/breeds/borzoi/n02090622_7602.jpg",
            "https://images.dog.ceo/breeds/germanshepherd/n02106662_19801.jpg",
            "https://images.dog.ceo/breeds/husky/n02110185_14056.jpg",
            "https://images.dog.ceo/breeds/pointer-german/n02100236_3686.jpg",
            "https://images.dog.ceo/breeds/malamute/n02110063_13541.jpg",
            "https://images.dog.ceo/breeds/keeshond/n02112350_8628.jpg",
            "https://images.dog.ceo/breeds/sheepdog-shetland/n02105855_12801.jpg",
            "https://images.dog.ceo/breeds/papillon/n02086910_5399.jpg",
            "https://images.dog.ceo/breeds/retriever-golden/n02099601_8429.jpg",
            "https://images.dog.ceo/breeds/bullterrier-staffordshire/n02093256_3994.jpg",
            "https://images.dog.ceo/breeds/dingo/n02115641_10021.jpg",
            "https://images.dog.ceo/breeds/papillon/n02086910_7456.jpg",
            "https://images.dog.ceo/breeds/husky/n02110185_1289.jpg"
        ]
        
        return urlStrings
            .compactMap { URL(string: $0) }
            .map { RemoteImageSource(url: $0) }
    }
    
    // MARK: - Getting local images
    private func localDogImages() -> [ImageSource] {
        let imageUrls = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: "Images") ?? []
        return imageUrls.map { LocalImageSource(path: $0.path) }
    }
}
