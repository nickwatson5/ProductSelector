import UIKit
import Combine

class ViewController: UIViewController {
    
    enum Section {
        case main
    }
    
    struct OutlineItem: Hashable {
        
        // MARK: - Properties
        
        let title: String
        let indentLevel: Int
        let subitems: [OutlineItem]
        let outlineViewController: UIViewController.Type?
        let configuration: ((UIViewController) -> Void)?
        
        var isExpanded = CurrentValueSubject<Bool, Never>(false)
        
        var isGroup: Bool {
            return self.outlineViewController == nil
        }
        private let identifier = UUID()

        // MARK: - Initializers
        
        init(title: String,
             indentLevel: Int = 0,
             viewController: UIViewController.Type? = nil,
             configuration: ((UIViewController) -> Void)? = nil,
             subitems: [OutlineItem] = []) {
            self.title = title
            self.indentLevel = indentLevel
            self.subitems = subitems
            self.outlineViewController = viewController
            self.configuration = configuration
        }

        // MARK: - Methods
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }
        
        static func == (lhs: OutlineItem, rhs: OutlineItem) -> Bool {
            return lhs.identifier == rhs.identifier
        }
    }
    
    var dataSource: UICollectionViewDiffableDataSource<Section, OutlineItem>! = nil
    var outlineCollectionView: UICollectionView! = nil
    fileprivate lazy var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Demo"
        configureCollectionView()
        configureDataSource()
    }
    
    private lazy var vcDefaultConfiguration: (_ vc: UIViewController) -> Void = {
        return { (vc: UIViewController) in
            vc.view.backgroundColor = .systemBackground
        }
    }()
    
    private lazy var menuItems: [OutlineItem] = {
        return [
            OutlineItem(title: "HSBC", indentLevel: 0, subitems: [
                OutlineItem(title: "Product Selection", indentLevel: 1, viewController: ProductSelector.self, configuration: vcDefaultConfiguration)
                ])
        ]
    }()
}

extension ViewController {
    
    func configureCollectionView() {
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: generateLayout())
        view.addSubview(collectionView)
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.register(OutlineItemCell.self, forCellWithReuseIdentifier: OutlineItemCell.reuseIdentifier)
        self.outlineCollectionView = collectionView
    }
    
    func configureDataSource() {
        self.dataSource = UICollectionViewDiffableDataSource
            <Section, OutlineItem>(collectionView: outlineCollectionView) {
                (collectionView: UICollectionView, indexPath: IndexPath, menuItem: OutlineItem) -> UICollectionViewCell? in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: OutlineItemCell.reuseIdentifier,
                    for: indexPath) as? OutlineItemCell else { fatalError("Could not create new cell") }
                cell.label.text = menuItem.title
                
                cell.indentLevel = menuItem.indentLevel
                cell.isGroup = menuItem.isGroup
                cell.subitems = menuItem.subitems.count
                cell.isExpanded = menuItem.isExpanded.value
                
                return cell
        }
        
        // load our initial data
        let snapshot = snapshotForCurrentState()
        self.dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func generateLayout() -> UICollectionViewLayout {
        let itemHeightDimension = NSCollectionLayoutDimension.absolute(44)
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: itemHeightDimension)
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: itemHeightDimension)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    func snapshotForCurrentState() -> NSDiffableDataSourceSnapshot<Section, OutlineItem> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, OutlineItem>()
        snapshot.appendSections([Section.main])
        func addItems(_ menuItem: OutlineItem) {
            snapshot.appendItems([menuItem])
            
            if menuItem.isExpanded.value {
                menuItem.subitems.forEach { addItems($0) }
            }
        }
        menuItems.forEach { addItems($0) }
        return snapshot
    }
    
    func updateUI() {
        let snapshot = snapshotForCurrentState()
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let menuItem = self.dataSource.itemIdentifier(for: indexPath) else { return }
        
        collectionView.deselectItem(at: indexPath, animated: true)
        if menuItem.isGroup {
            menuItem.isExpanded.value.toggle()

            if let cell = collectionView.cellForItem(at: indexPath) as? OutlineItemCell {
                cell.isExpanded = menuItem.isExpanded.value
                self.updateUI()
            }
        } else {
            if let viewController = menuItem.outlineViewController {
                // Instantiate and apply optional configuration closure to the destination view controller
                let destinationViewController = viewController.init()
                menuItem.configuration?(destinationViewController)
                
                let navController = UINavigationController(rootViewController: destinationViewController)
                present(navController, animated: true)
            }
        }
    }
}
