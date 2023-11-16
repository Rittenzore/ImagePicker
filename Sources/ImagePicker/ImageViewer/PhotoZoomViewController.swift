import UIKit
import Photos

public protocol PhotoZoomViewControllerDelegate: AnyObject {
    func photoZoomViewController(
        _ photoZoomViewController: PhotoZoomViewController,
        scrollViewDidScroll scrollView: UIScrollView
    )
}

public final class PhotoZoomViewController: UIViewController {
    
    public weak var delegate: PhotoZoomViewControllerDelegate?
    
    public var phAsset: PHAsset?
    public var index = 0

    private(set) lazy var doubleTapGestureRecognizer = UITapGestureRecognizer(
        target: self,
        action: #selector(didDoubleTapWith(gestureRecognizer:))
    )
    
    private(set) lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()
    
    private var imageViewTopConstraint = NSLayoutConstraint()
    private var imageViewLeftConstraint = NSLayoutConstraint()
    private var imageViewBottomConstraint = NSLayoutConstraint()
    private var imageViewRightConstraint = NSLayoutConstraint()
    private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        if let phAsset {
            ImageFetcher.resolveAsset(phAsset) { uiImage in
                guard let uiImage else { return }
                self.imageView.image = uiImage
                self.imageView.frame = .init(
                    x: self.imageView.frame.origin.x,
                    y: self.imageView.frame.origin.y,
                    width: uiImage.size.width,
                    height: uiImage.size.height
                )
            }
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateZoomScaleForSize(view.bounds.size)
        updateConstraintsForSize(view.bounds.size)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateZoomScaleForSize(view.bounds.size)
        updateConstraintsForSize(view.bounds.size)
    }
}

// MARK: - Private methods
private extension PhotoZoomViewController {
    func setupView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            view.rightAnchor.constraint(equalTo: scrollView.rightAnchor)
        ])
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        
        imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: scrollView.topAnchor)
        imageViewLeftConstraint = imageView.leftAnchor.constraint(equalTo: scrollView.leftAnchor)
        imageViewBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        imageViewRightConstraint = scrollView.rightAnchor.constraint(equalTo: imageView.rightAnchor)
        
        NSLayoutConstraint.activate([
            imageViewTopConstraint,
            imageViewLeftConstraint,
            imageViewBottomConstraint,
            imageViewRightConstraint
        ])
        
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    func updateZoomScaleForSize(_ size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)
        scrollView.minimumZoomScale = minScale
        
        scrollView.zoomScale = minScale
        scrollView.maximumZoomScale = minScale * 4
    }
    
    func updateConstraintsForSize(_ size: CGSize) {
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset
        
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        imageViewLeftConstraint.constant = xOffset
        imageViewRightConstraint.constant = xOffset

        let contentHeight = yOffset * 2 + imageView.frame.height
        view.layoutIfNeeded()
        scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: contentHeight)
    }
}

// MARK: - UIScrollViewDelegate
extension PhotoZoomViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(view.bounds.size)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.photoZoomViewController(self, scrollViewDidScroll: scrollView)
    }
}

// MARK: - Objc methods
@objc private extension PhotoZoomViewController {
    func didDoubleTapWith(gestureRecognizer: UITapGestureRecognizer) {
        let pointInView = gestureRecognizer.location(in: imageView)
        var newZoomScale = scrollView.maximumZoomScale
        
        if scrollView.zoomScale >= newZoomScale || abs(scrollView.zoomScale - newZoomScale) <= 0.01 {
            newZoomScale = scrollView.minimumZoomScale
        }
        
        let width = scrollView.bounds.width / newZoomScale
        let height = scrollView.bounds.height / newZoomScale
        let originX = pointInView.x - (width / 2.0)
        let originY = pointInView.y - (height / 2.0)
        
        let rectToZoomTo = CGRect(x: originX, y: originY, width: width, height: height)
        scrollView.zoom(to: rectToZoomTo, animated: true)
    }
}
