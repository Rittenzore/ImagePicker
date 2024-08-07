import UIKit
import Photos

public protocol ImagesGalleryViewControllerDelegate: AnyObject {
    func phAssetsDidSelect(selectedPhAssets: [PHAsset])
}

public final class ImagesGalleryViewController: UIViewController {
    
    public weak var delegate: ImagesGalleryViewControllerDelegate?
    
    public var selectionLimit = 3
    
    private var selectedIndexPath: IndexPath?
    
    private var selectedPhAssets = [PHAsset]()
    private lazy var allPhotosAssets = [PHAsset]()
    
    private let cellSize = CGSize(width: 200, height: 200)
    
    private lazy var rightBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneDidTap)
        )
        barButtonItem.isEnabled = false
        return barButtonItem
    }()
        
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = .init(
            width: UIScreen.main.bounds.width / 3 - 2 / 2,
            height: UIScreen.main.bounds.width / 3 - 2 / 2
        )
        layout.sectionInset = .zero
        layout.minimumLineSpacing = 2
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = .zero
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    private lazy var loaderView = UIActivityIndicatorView(style: .medium)
        
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAppearance()
        setupView()
        fetchData()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.standardAppearance = .init()
        navigationController?.navigationBar.scrollEdgeAppearance = nil
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

// MARK: - Private methods
private extension ImagesGalleryViewController {
    func setupAppearance() {
        navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .cancel, target: self, action: #selector(cancelDidTap))
        navigationItem.rightBarButtonItem = rightBarButtonItem
        view.backgroundColor = .systemBackground
    }
    
    func setupView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            view.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor),
            view.rightAnchor.constraint(equalTo: collectionView.rightAnchor)
        ])
        
        loaderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loaderView)
        NSLayoutConstraint.activate([
            loaderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loaderView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        loaderView.startAnimating()
    }
    
    func fetchData() {
        ImageFetcher.getPermissionIfNecessary { granted in
            guard granted else { return }
            ImageFetcher.fetch { assets in
                self.allPhotosAssets.removeAll()
                self.allPhotosAssets.append(contentsOf: assets)
                self.loaderView.stopAnimating()
                self.collectionView.reloadData()
            }
        }
    }
    
    func getImgeViewFromCollectionViewCell(for selectedIndexPath: IndexPath) -> UIImageView {
        let visibleCellsIndexPaths = collectionView.indexPathsForVisibleItems
        
        if !visibleCellsIndexPaths.contains(selectedIndexPath) {
            collectionView.scrollToItem(at: selectedIndexPath, at: .centeredVertically, animated: false)
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
            collectionView.layoutIfNeeded()
        }
        
        guard let cell = (collectionView.cellForItem(at: selectedIndexPath) as? ImagesGalleryCell) else {
            return UIImageView(frame: .init(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 100, height: 100))
        }
        
        return cell.imageView
    }
    
    func getFrameFromCollectionViewCell(for selectedIndexPath: IndexPath) -> CGRect {
        let visibleCellsIndexPaths = collectionView.indexPathsForVisibleItems
        
        if !visibleCellsIndexPaths.contains(selectedIndexPath) {
            collectionView.scrollToItem(at: selectedIndexPath, at: .centeredVertically, animated: false)
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
            collectionView.layoutIfNeeded()
        }
        
        guard let cell = (collectionView.cellForItem(at: selectedIndexPath) as? ImagesGalleryCell) else {
            return .init(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 100, height: 100)
        }
        
        return cell.frame
    }
}

// MARK: - UICollectionViewDelegate
extension ImagesGalleryViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        
        let vc = ImageViewer()
        let navVC = UINavigationController(rootViewController: vc)
        
        vc.transitionController.fromDelegate = self
        vc.transitionController.toDelegate = vc

        navVC.modalPresentationStyle = .custom
        navVC.transitioningDelegate = vc.transitionController

        vc.delegate = self
        if let selectedIndexPath { vc.currentIndex = selectedIndexPath.item }
        vc.phAssets = allPhotosAssets
        vc.selectedPhAssets = selectedPhAssets
        
        present(navVC, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension ImagesGalleryViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithRegistration(type: ImagesGalleryCell.self, indexPath: indexPath)
        
        let imageAsset = allPhotosAssets[indexPath.row]
        
        let isSelected = self.selectedPhAssets.contains(where: { $0 == imageAsset })
        let isSelectable = self.selectedPhAssets.count < selectionLimit || isSelected
        let isReachedLimit = self.selectedPhAssets.count < selectionLimit
        
        cell.configure(
            imageAsset,
            targetImageSize: cellSize,
            isSelected: isSelected,
            isSelectable: isSelectable,
            isReachedLimit: isReachedLimit,
            delegate: self
        )
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        allPhotosAssets.count
    }
}

// MARK: - Objc methods
@objc private extension ImagesGalleryViewController {
    func cancelDidTap() {
        dismiss(animated: true)
    }
    
    func doneDidTap() {
        delegate?.phAssetsDidSelect(selectedPhAssets: selectedPhAssets)
        dismiss(animated: true)
    }
}

// MARK: - ImagesGalleryCellDelegate
extension ImagesGalleryViewController: ImagesGalleryCellDelegate {
    public func selectButtonDidTap(phAsset: PHAsset) {
        if selectedPhAssets.contains(where: { $0 == phAsset }) {
            selectedPhAssets.removeAll(where: { $0 == phAsset })
        } else {
            selectedPhAssets.append(phAsset)
        }
        
        rightBarButtonItem.isEnabled = !selectedPhAssets.isEmpty
        
        if let index = allPhotosAssets.firstIndex(of: phAsset) {
            let indexPath = IndexPath(item: index, section: 0)
            UIView.performWithoutAnimation {
                collectionView.reloadItems(at: [indexPath])
            }
        }
    }
}

// MARK: - ZoomAnimatorDelegate
extension ImagesGalleryViewController: ZoomAnimatorDelegate {
    public func transitionWillStartWith(zoomAnimator: ZoomAnimator) { }
    
    public func transitionDidEndWith(zoomAnimator: ZoomAnimator) {
        guard let selectedIndexPath,
              let cell = collectionView.cellForItem(at: selectedIndexPath) as? ImagesGalleryCell else { return }
        
        let cellFrame = collectionView.convert(cell.frame, to: view)
        
        if cellFrame.minY < collectionView.contentInset.top {
            collectionView.scrollToItem(at: selectedIndexPath, at: .top, animated: false)
        } else if cellFrame.maxY > view.frame.height - collectionView.contentInset.bottom {
            collectionView.scrollToItem(at: selectedIndexPath, at: .bottom, animated: false)
        }
    }
    
    public func referenceImageView(for zoomAnimator: ZoomAnimator) -> UIImageView? {
        guard let selectedIndexPath else { return nil }
        let referenceImageView = getImgeViewFromCollectionViewCell(for: selectedIndexPath)
        return referenceImageView
    }
    
    public func referenceImageViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect? {
        guard let selectedIndexPath else { return nil }
        
        view.layoutIfNeeded()
        collectionView.layoutIfNeeded()
        
        let unconvertedFrame = getFrameFromCollectionViewCell(for: selectedIndexPath)
        
        let cellFrame = collectionView.convert(unconvertedFrame, to: view)
        if cellFrame.minY < collectionView.contentInset.top {
            return .init(
                x: cellFrame.minX,
                y: collectionView.contentInset.top,
                width: cellFrame.width,
                height: cellFrame.height - (collectionView.contentInset.top - cellFrame.minY)
            )
        }
        
        return cellFrame
    }
}

// MARK: - ImageViewerDelegate
extension ImagesGalleryViewController: ImageViewerDelegate {
    public func containerViewController(_ containerViewController: ImageViewer, indexDidUpdate currentIndex: Int) {
        selectedIndexPath = IndexPath(row: currentIndex, section: .zero)
        guard let selectedIndexPath else { return }
        collectionView.scrollToItem(at: selectedIndexPath, at: .centeredVertically, animated: false)
    }
    
    public func phAssetDidSelect(_ phAsset: PHAsset) {
        selectButtonDidTap(phAsset: phAsset)
    }
}
