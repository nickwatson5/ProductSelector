import UIKit

class ProductSelector: UIViewController {
    
    var dataSource: UICollectionViewDiffableDataSource<Int, ImageModel>! = nil
    var collectionView: UICollectionView! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Product Selection"
        configureHierarchy()
        configureDataSource()
    }
}

extension ProductSelector {
    private func createLayout() -> UICollectionViewLayout {
        
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnv) -> NSCollectionLayoutSection? in
            
            let galleryItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                        heightDimension: .fractionalHeight(1.0)))
            galleryItem.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)

            //if sectionIndex % 2 == 0 {
                let galleryGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.85),
                                                                                                         heightDimension: .fractionalHeight(0.75)),
                                                                  subitem: galleryItem, count: 1)
                
                let gallerySection = NSCollectionLayoutSection(group: galleryGroup)
                gallerySection.orthogonalScrollingBehavior = .groupPagingCentered
                return gallerySection
            //}
        }
        return layout
    }
}

extension ProductSelector {
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
        view.addSubview(collectionView)
    }
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, ImageModel>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, model: ImageModel) -> UICollectionViewCell? in
            
            // Get a cell of the desired kind.
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ImageCell.reuseIdentifier,
                for: indexPath) as? ImageCell else { fatalError("Could not create new cell") }
            cell.image = model.image
            cell.imageContentMode = .scaleAspectFill
            cell.clipsToBounds = true
            cell.layer.cornerRadius = 10
            cell.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
            
            return cell
        }
        
        func produceImage() -> UIImage {
            guard let image = ImageFactory.produce(using: .next) else {
                fatalError("Could not generate an UIImage instance by using the ImageFactory struct")
            }
            return image
        }
        
        // initial data
        var snapshot = NSDiffableDataSourceSnapshot<Int, ImageModel>()
        var identifierOffset = 0
        let itemsPerSection = 8
        for section in 0..<1 {
            snapshot.appendSections([section])
            let maxIdentifier = identifierOffset + itemsPerSection
            let models = (0..<maxIdentifier).map { _ in ImageModel(image: produceImage()) }
            snapshot.appendItems(models)
            identifierOffset += itemsPerSection
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

