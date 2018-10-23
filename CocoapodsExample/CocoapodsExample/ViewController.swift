import ImageSource
import UIKit

class ViewController: UICollectionViewController {
    
    private let cellSpacing: CGFloat = 10
    private let cellId = String(describing: UIImageSourceCollectionViewCell.self)
    private var images = [ImageSource]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.register(UIImageSourceCollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.alwaysBounceVertical = true
        collectionView?.contentInset = UIEdgeInsets(
            top: cellSpacing,
            left: cellSpacing,
            bottom: cellSpacing,
            right: cellSpacing
        )
        collectionView?.delegate = self
        
        ImageProvider().images { [weak self] images in
            self?.images = images
            self?.collectionView?.reloadData()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            setUpLayout(layout)
        }
    }
    
    // MARK: - UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath)
        
        if let cell = cell as? UIImageSourceCollectionViewCell {
            cell.imageSource = images[indexPath.item]
        }
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let imageSource = images[indexPath.item]
        imageSource.requestImage(
            options: ImageRequestOptions(
                size: .fitSize(CGSize(width: 1290, height: 960)),
                deliveryMode: .best,
                needsMetadata: true
            ),
            resultHandler: { (result: ImageRequestResult<UIImage>) in
                print(result.metadata)
            }
        )
    }
    
    // MARK: - Private
    private func setUpLayout(_ layout: UICollectionViewFlowLayout) {
        
        let numberOfColumns: CGFloat = 3
        let itemDimension = (view.bounds.width - (numberOfColumns + 1) * cellSpacing) / numberOfColumns
        
        layout.itemSize = CGSize(width: itemDimension, height: itemDimension)
    }
}
