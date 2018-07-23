import ImageSource
import Photos

final class ImageProvider {
    
    private let dogApiClient = DogApiClient()
    private let fileManager = FileManager.default
    
    /**
     This method is asynchronous because iOS can prompt user to allow access to photo library
     */
    func images(completion: @escaping ([ImageSource]) -> ()) {
        
        var images = [ImageSource]()
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        photosFromCameraRoll { photos in
            images.append(contentsOf: photos)
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        randomRemoteDogImages { remoteImages in
            images.append(contentsOf: remoteImages)
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        localDogImages { localImages in
            images.append(contentsOf: localImages)
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
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
    private func randomRemoteDogImages(completion: @escaping ([ImageSource]) -> ()) {
        dogApiClient.randomDogs { dogs in
            completion(dogs.map { RemoteImageSource(url: $0.url) })
        }
    }
    
    // MARK: - Getting local images
    private func localDogImages(completion: @escaping ([ImageSource]) -> ()) {
        guard let localImagesPath = self.localImagesPath() else {
            return completion([])
        }
        
        let localImagesUrl = URL(fileURLWithPath: localImagesPath)
        
        if let files = try? fileManager.contentsOfDirectory(atPath: localImagesPath), files.count > 0 {
            completion(files.map { LocalImageSource(path: localImagesUrl.appendingPathComponent($0).path) })
        } else { // Directory doesn't exist
            do {
                try fileManager.createDirectory(
                    atPath: localImagesPath,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                
                dogApiClient.randomDogs { [fileManager] dogs in
                    dogs.forEach { dog in
                        dispatchGroup.enter()
                        
                        let downloadTask = URLSession.shared.downloadTask(with: dog.url) { url, _, _ in
                            if let url = url {
                                try? fileManager.moveItem(
                                    at: url,
                                    to: localImagesUrl.appendingPathComponent(url.lastPathComponent)
                                )
                            }
                            
                            dispatchGroup.leave()
                        }
                        
                        downloadTask.resume()
                    }
                    
                    dispatchGroup.leave()
                }
                
                dispatchGroup.notify(queue: .main) { [fileManager] in
                    let files = (try? fileManager.contentsOfDirectory(atPath: localImagesPath)) ?? []
                    completion(files.map { LocalImageSource(path: localImagesUrl.appendingPathComponent($0).path) })
                }
            } catch {
                print(error)
                completion([])
            }
        }
    }
    
    private func localImagesPath() -> String? {
        if let url = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            return url.appendingPathComponent("LocalImages").path
        } else {
            assertionFailure("Can't find user's Downloads directory. That's weird.")
            return nil
        }
    }
}
