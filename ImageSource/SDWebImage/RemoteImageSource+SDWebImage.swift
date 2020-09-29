import SDWebImage

public extension RemoteImageSource {
    convenience init(url: URL, previewImage: CGImage? = nil) {
        self.init(url: url, previewImage: previewImage, imageDownloader: SDWebImageManager.shared())
    }
}
