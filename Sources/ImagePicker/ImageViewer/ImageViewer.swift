import UIKit
import Photos

public protocol ImageViewerDelegate: AnyObject {
    func containerViewController(_ containerViewController: ImageViewer, indexDidUpdate currentIndex: Int)
    func phAssetDidSelect(_ phAsset: PHAsset)
}

public final class ImageViewer: UIViewController {
    
    public weak var delegate: ImageViewerDelegate?
    
    public var isRightBarButtonItemSelected: Bool = false {
        didSet {
            rightBarButton.setImage(
                UIImage(
                    systemName: isRightBarButtonItemSelected ? "checkmark.circle.fill" : "circle"
                ),
                for: .normal
            )
        }
    }
    
    public var selectionLimit: Int = 3
    
    private lazy var pageViewController: UIPageViewController = {
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        pageViewController.delegate = self
        pageViewController.dataSource = self
        return pageViewController
    }()
    
    private lazy var rightBarButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "circle"), for: .normal)
        button.addTarget(self, action: #selector(selectButtonDidTap), for: .touchUpInside)
        button.tintColor = .white
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.5
        button.layer.shadowRadius = 5
        button.layer.shadowOffset = .zero
        return button
    }()

    private lazy var rightBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem(customView: rightBarButton)
        return barButtonItem
    }()
    
    public lazy var singleTapGesture = UITapGestureRecognizer(
        target: self,
        action: #selector(didSingleTapWith(gestureRecognizer:))
    )

    public enum ScreenMode {
        case full, normal
    }
    
    public var currentMode: ScreenMode = .normal
            
    public var currentViewController: PhotoZoomViewController? {
        return pageViewController.viewControllers?[0] as? PhotoZoomViewController
    }
    
    public var phAssets: [PHAsset]?
//    public var uiImages: [UIImage]?
    public var selectedPhAssets = [PHAsset]()
    public var currentIndex = 0
    public var nextIndex: Int?
    
    public var transitionController = ZoomTransitionController()
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAppearance()
        setupView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.standardAppearance = .init()
        navigationController?.navigationBar.scrollEdgeAppearance = nil
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

// MARK: - Private methods
private extension ImageViewer {
    func setupAppearance() {
        let leftBarButton = UIButton()
        leftBarButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        leftBarButton.tintColor = .white
        leftBarButton.layer.shadowColor = UIColor.black.cgColor
        leftBarButton.layer.shadowOpacity = 0.5
        leftBarButton.layer.shadowRadius = 5
        leftBarButton.layer.shadowOffset = .zero
        leftBarButton.addTarget(self, action: #selector(xmarkButtonDidTap), for: .touchUpInside)

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftBarButton)
        
        navigationItem.rightBarButtonItem = rightBarButtonItem
        view.backgroundColor = .black
    }
    
    func setupView() {
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageViewController.view)
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            view.bottomAnchor.constraint(equalTo: pageViewController.view.bottomAnchor),
            view.rightAnchor.constraint(equalTo: pageViewController.view.rightAnchor)
        ])
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPanWith(gestureRecognizer:)))
        panGestureRecognizer.delegate = self
        pageViewController.view.addGestureRecognizer(panGestureRecognizer)
        pageViewController.view.addGestureRecognizer(singleTapGesture)

        let vc = PhotoZoomViewController()
        vc.delegate = self
        vc.index = currentIndex
        vc.phAsset = phAssets?[currentIndex]
        singleTapGesture.require(toFail: vc.doubleTapGestureRecognizer)
        
        let viewControllers = [vc]
        
        pageViewController.setViewControllers(viewControllers, direction: .forward, animated: true)
        
        updateRightBarButtonItemImage()
    }
    
    func changeScreenMode(to: ScreenMode) {
        if to == .full {
            navigationController?.setNavigationBarHidden(true, animated: false)
            UIView.animate(
                withDuration: 0.25,
                animations: {
                    self.view.backgroundColor = .black
                }
            )
        } else {
            navigationController?.setNavigationBarHidden(false, animated: false)
            UIView.animate(
                withDuration: 0.25,
                animations: {
                    self.view.backgroundColor = .systemBackground
                }
            )
        }
    }
    
    func updateRightBarButtonItemImage() {
        let isSelected = selectedPhAssets.contains { $0 == phAssets?[currentIndex] }
        isRightBarButtonItemSelected = isSelected
        
        let isReachedSelectionLimit = selectedPhAssets.count < selectionLimit
        let isCurrentIndexImageSelected = selectedPhAssets.contains { $0 == phAssets?[currentIndex] }
        rightBarButtonItem.isEnabled = isReachedSelectionLimit || isCurrentIndexImageSelected
    }
}

// MARK: - Objc methods
@objc private extension ImageViewer {
    func crossButtonDidTap() {
        dismiss(animated: true)
    }
}

// MARK: - UIPageViewControllerDelegate
extension ImageViewer: UIPageViewControllerDelegate {
    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let nextVC = pendingViewControllers.first as? PhotoZoomViewController else {
            return
        }
        
        nextIndex = nextVC.index
    }
    
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        if (completed && nextIndex != nil) {
            previousViewControllers.forEach { vc in
                if let zoomVC = vc as? PhotoZoomViewController {
                    zoomVC.scrollView.zoomScale = zoomVC.scrollView.minimumZoomScale
                }
            }
            
            if let nextIndex { currentIndex = nextIndex }
                        
            updateRightBarButtonItemImage()
            delegate?.containerViewController(self, indexDidUpdate: currentIndex)
        }
        
        nextIndex = nil
    }
}

// MARK: - UIPageViewControllerDataSource
extension ImageViewer: UIPageViewControllerDataSource {
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard currentIndex != 0 else { return nil }
        
        let vc = PhotoZoomViewController()
        vc.delegate = self
        vc.phAsset = phAssets?[currentIndex - 1]
        vc.index = currentIndex - 1
        singleTapGesture.require(toFail: vc.doubleTapGestureRecognizer)
        return vc
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let phAssets else { return nil }
        guard currentIndex != phAssets.count - 1 else { return nil }
        
        let vc = PhotoZoomViewController()
        singleTapGesture.require(toFail: vc.doubleTapGestureRecognizer)
        vc.delegate = self
        vc.phAsset = phAssets[currentIndex + 1]
        vc.index = currentIndex + 1
        return vc
    }
}

// MARK: - Objc methods
@objc private extension ImageViewer {
    func didPanWith(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            currentViewController?.scrollView.isScrollEnabled = false
            transitionController.isInteractive = true
            dismiss(animated: true)
            
        case .ended:
            if transitionController.isInteractive {
                currentViewController?.scrollView.isScrollEnabled = true
                transitionController.isInteractive = false
                transitionController.didPanWith(gestureRecognizer: gestureRecognizer)
            }
            
        default:
            if transitionController.isInteractive {
                transitionController.didPanWith(gestureRecognizer: gestureRecognizer)
            }
        }
    }
    
    func didSingleTapWith(gestureRecognizer: UITapGestureRecognizer) {
        if currentMode == .full {
            changeScreenMode(to: .normal)
            currentMode = .normal
        } else {
            changeScreenMode(to: .full)
            currentMode = .full
        }
    }
    
    func selectButtonDidTap() {
        guard let selectedPhAsset = phAssets?[currentIndex] else { return }
//
        if selectedPhAssets.contains(where: { $0 == selectedPhAsset }) {
            selectedPhAssets.removeAll(where: { $0 == selectedPhAsset })
        } else {
            selectedPhAssets.append(selectedPhAsset)
        }
        
        delegate?.phAssetDidSelect(selectedPhAsset)
        isRightBarButtonItemSelected.toggle()
    }
    
    func xmarkButtonDidTap() {
        dismiss(animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ImageViewer: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = gestureRecognizer.velocity(in: view)
            var velocityCheck: Bool
            
            if UIDevice.current.orientation.isLandscape {
                velocityCheck = velocity.x < 0
            } else {
                velocityCheck = velocity.y < 0
            }
            
            if velocityCheck {
                return false
            }
        }
        
        return true
    }
    
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if otherGestureRecognizer == currentViewController?.scrollView.panGestureRecognizer {
            if currentViewController?.scrollView.contentOffset.y == 0 {
                return true
            }
        }
        
        return false
    }
}

// MARK: - PhotoZoomViewControllerDelegate
extension ImageViewer: PhotoZoomViewControllerDelegate {
    public func photoZoomViewController(_ photoZoomViewController: PhotoZoomViewController, scrollViewDidScroll scrollView: UIScrollView) {
        if scrollView.zoomScale > scrollView.minimumZoomScale && currentMode != .full {
            changeScreenMode(to: .full)
            currentMode = .full
        }
    }
}

// MARK: - ZoomAnimatorDelegate
extension ImageViewer: ZoomAnimatorDelegate {
    public func transitionWillStartWith(zoomAnimator: ZoomAnimator) { }
    
    public func transitionDidEndWith(zoomAnimator: ZoomAnimator) { }
    
    public func referenceImageView(for zoomAnimator: ZoomAnimator) -> UIImageView? {
        return currentViewController?.imageView
    }
    
    public func referenceImageViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect? {
        guard let imageViewFrame = currentViewController?.imageView.frame else { return nil }
        return currentViewController?.scrollView.convert(imageViewFrame, to: currentViewController?.view)
    }
}
