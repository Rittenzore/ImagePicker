import UIKit

public class ZoomTransitionController: NSObject {
    
    public let animator: ZoomAnimator
    public let interactionController: ZoomDismissalInteractionController
    public var isInteractive = false

    public weak var fromDelegate: ZoomAnimatorDelegate?
    public weak var toDelegate: ZoomAnimatorDelegate?
    
    public override init() {
        animator = ZoomAnimator()
        interactionController = ZoomDismissalInteractionController()
        super.init()
    }
    
    public func didPanWith(gestureRecognizer: UIPanGestureRecognizer) {
        interactionController.didPanWith(gestureRecognizer: gestureRecognizer)
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension ZoomTransitionController: UIViewControllerTransitioningDelegate {
    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        animator.isPresenting = true
        animator.fromDelegate = fromDelegate
        animator.toDelegate = toDelegate
        return animator
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.isPresenting = false
        let tmp = fromDelegate
        animator.fromDelegate = toDelegate
        animator.toDelegate = tmp
        return animator
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if !isInteractive {
            return nil
        }
        
        interactionController.animator = animator
        return interactionController
    }
}

// MARK: - UINavigationControllerDelegate
extension ZoomTransitionController: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            animator.isPresenting = true
            animator.fromDelegate = fromDelegate
            animator.toDelegate = toDelegate
        } else {
            animator.isPresenting = false
            let tmp = fromDelegate
            animator.fromDelegate = toDelegate
            animator.toDelegate = tmp
        }
        
        return animator
    }
    
    public func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        if !isInteractive {
            return nil
        }
        
        interactionController.animator = animator
        return interactionController
    }
}
