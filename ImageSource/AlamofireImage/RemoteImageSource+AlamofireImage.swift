import AlamofireImage
import Foundation
import CoreGraphics

public extension RemoteImageSource {
    convenience init(url: URL, previewImage: CGImage? = nil) {
        self.init(url: url, previewImage: previewImage, imageDownloader: AlamofireImage.ImageDownloader.default)
    }
}
