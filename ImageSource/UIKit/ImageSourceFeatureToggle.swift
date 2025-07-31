final public class ImageSourceFeatureToggle {
    public static let shared = ImageSourceFeatureToggle()
    private init() { }
    
    public var isNewImageSettingEnabled: Bool = false
}
