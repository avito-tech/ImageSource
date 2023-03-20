/// Options for requesting an image asset with or without adjustments. 
/// important: Can be applied to `PHAssetImageSource` only.
public enum ImageRequestOptionsVersion {

    /// Request the most recent version of the image asset (the one that reflects all edits).
    case current

    /// Request a version of the image asset without adjustments.
    case unadjusted

    /// Request the original, highest-fidelity version of the image asset.
    case original
}
