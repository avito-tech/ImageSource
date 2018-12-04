ImageSource is an image abstraction. It is intended to represent an image that can come from many different sources.

Some examples of the sources are:
* file system (`LocalImageSource`)
* network (`RemoteImageSource`)
* user's photo library (`PHAssetImageSource`)

It allows you to retrieve the actual bitmap in a simple and efficient way using the unified API and supports retrieval cancellation.
It is also designed to be platform-independent, so you can use it both on iOS and macOS.

* [Installation](#installation)
  * [CocoaPods](#installation-cocoapods)
* [Typical use cases](#use-cases)
  * [Displaying in UI](#displaying-in-ui)
  * [Getting image data](#getting-image-data)
  * [Getting image size](#getting-image-size)
* [Implementing custom ImageSource](#custom-imagesource)

## <a name="installation" /> Installation
### <a name="installation-cocoapods" /> CocoaPods

To integrate ImageSource into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
use_frameworks!

target '<Your Target Name>' do
    pod 'ImageSource'
end
```

Then, run the following command:

```bash
$ pod install
```

## <a name="use-cases" />Typical use cases
### <a name="displaying-in-ui" />Displaying in UI
To present `ImageSource` in `UIImageView`, you should use extension method that comes with `ImageSource/UIKit` pod:

```swift
func setImage(
    fromSource: ImageSource?,
    size: CGSize? = nil,
    placeholder: UIImage? = nil,
    placeholderDeferred: Bool = false,
    adjustOptions: ((_ options: inout ImageRequestOptions) -> ())? = nil,
    resultHandler: ((ImageRequestResult<UIImage>) -> ())? = nil)
    -> ImageRequestId?
```

In most cases, however, you would want to just use its simplest version, passing only the first parameter:

`imageView.setImage(fromSource: imageSource)`

### <a name="getting-image-data" />Getting image data
To get image data use `ImageSource.fullResolutionImageData(completion:)`:

```swift
imageSource.fullResolutionImageData { data in
    try? data?.write(to: fileUrl)
}
```

### <a name="getting-image-size" />Getting image size
To get image size use `ImageSource.imageSize(completion:)`:

```swift
imageSource.imageSize { size in
    // do something with size
}
```
