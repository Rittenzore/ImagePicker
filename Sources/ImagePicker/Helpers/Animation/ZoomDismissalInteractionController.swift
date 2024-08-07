import UIKit

public class ZoomDismissalInteractionController: NSObject {
    
    public var transitionContext: UIViewControllerContextTransitioning?
    public var animator: UIViewControllerAnimatedTransitioning?
    
    public var fromReferenceImageViewFrame: CGRect?
    public var toReferenceImageViewFrame: CGRect?
    
    public func didPanWith(gestureRecognizer: UIPanGestureRecognizer) {
        guard let transitionContext,
              let animator = animator as? ZoomAnimator,
              let transitionImageView = animator.transitionImageView,
              let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to),
              let fromReferenceImageView = animator.fromDelegate?.referenceImageView(for: animator),
              let toReferenceImageView = animator.toDelegate?.referenceImageView(for: animator),
              let fromReferenceImageViewFrame = fromReferenceImageViewFrame,
              let toReferenceImageViewFrame = toReferenceImageViewFrame else {
            return
        }
        
        let containerView = transitionContext.containerView

        fromReferenceImageView.isHidden = true
        
        let anchorPoint = CGPoint(x: fromReferenceImageViewFrame.midX, y: fromReferenceImageViewFrame.midY)
        let translatedPoint = gestureRecognizer.translation(in: fromReferenceImageView)
        let verticalDelta : CGFloat = translatedPoint.y < 0 ? 0 : translatedPoint.y

        let backgroundAlpha = backgroundAlphaFor(view: fromVC.view, withPanningVerticalDelta: verticalDelta)
        let scale = scaleFor(view: fromVC.view, withPanningVerticalDelta: verticalDelta)
        
        fromVC.view.alpha = backgroundAlpha
        
        transitionImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        let newCenter = CGPoint(
            x: anchorPoint.x + translatedPoint.x,
            y: anchorPoint.y + translatedPoint.y - transitionImageView.frame.height * (1 - scale) / 2.0
        )
        transitionImageView.center = newCenter
        
        toReferenceImageView.isHidden = true
        
        transitionContext.updateInteractiveTransition(1 - scale)
                
        if gestureRecognizer.state == .ended {
            let velocity = gestureRecognizer.velocity(in: fromVC.view)
            if velocity.y < 0 || newCenter.y < anchorPoint.y {
                // cancel
                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    usingSpringWithDamping: 0.9,
                    initialSpringVelocity: 0,
                    options: [],
                    animations: {
                        transitionImageView.frame = fromReferenceImageViewFrame
                        fromVC.view.alpha = 1.0
                    },
                    completion: { completed in
                        toReferenceImageView.isHidden = !transitionContext.transitionWasCancelled
                        fromReferenceImageView.isHidden = transitionContext.transitionWasCancelled
                        transitionImageView.removeFromSuperview()
                        animator.transitionImageView = nil
                        transitionContext.cancelInteractiveTransition()
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                        animator.toDelegate?.transitionDidEndWith(zoomAnimator: animator)
                        animator.fromDelegate?.transitionDidEndWith(zoomAnimator: animator)
                        self.transitionContext = nil
                    }
                )
                return
            }
            
            // start animation
            let finalTransitionSize = toReferenceImageView.convert(toReferenceImageView.bounds, to: containerView)
            
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [],
                animations: {
                    fromVC.view.alpha = 0
                    transitionImageView.frame = finalTransitionSize
                },
                completion: { completed in
                    transitionImageView.removeFromSuperview()
                    toReferenceImageView.isHidden = false
                    fromReferenceImageView.isHidden = false
                    
                    self.transitionContext?.finishInteractiveTransition()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                    animator.toDelegate?.transitionDidEndWith(zoomAnimator: animator)
                    animator.fromDelegate?.transitionDidEndWith(zoomAnimator: animator)
                    self.transitionContext = nil
                }
            )
        }
    }
    
    public func backgroundAlphaFor(view: UIView, withPanningVerticalDelta verticalDelta: CGFloat) -> CGFloat {
        let startingAlpha:CGFloat = 1.0
        let finalAlpha: CGFloat = 0.0
        let totalAvailableAlpha = startingAlpha - finalAlpha
        
        let maximumDelta = view.bounds.height / 4.0
        let deltaAsPercentageOfMaximun = min(abs(verticalDelta) / maximumDelta, 1.0)
        
        return startingAlpha - (deltaAsPercentageOfMaximun * totalAvailableAlpha)
    }
    
    public func scaleFor(view: UIView, withPanningVerticalDelta verticalDelta: CGFloat) -> CGFloat {
        let startingScale:CGFloat = 1.0
        let finalScale: CGFloat = 0.5
        let totalAvailableScale = startingScale - finalScale
        
        let maximumDelta = view.bounds.height / 2.0
        let deltaAsPercentageOfMaximun = min(abs(verticalDelta) / maximumDelta, 1.0)
        
        return startingScale - (deltaAsPercentageOfMaximun * totalAvailableScale)
    }
}

// MARK: - UIViewControllerInteractiveTransitioning
extension ZoomDismissalInteractionController: UIViewControllerInteractiveTransitioning {
    public func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        let containerView = transitionContext.containerView
        
        guard let animator = self.animator as? ZoomAnimator,
              let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to),
              let fromReferenceImageViewFrame = animator.fromDelegate?.referenceImageViewFrameInTransitioningView(for: animator),
              let toReferenceImageViewFrame = animator.toDelegate?.referenceImageViewFrameInTransitioningView(for: animator),
              let fromReferenceImageView = animator.fromDelegate?.referenceImageView(for: animator) else {
            return
        }
        
        animator.fromDelegate?.transitionWillStartWith(zoomAnimator: animator)
        animator.toDelegate?.transitionWillStartWith(zoomAnimator: animator)
        
        self.fromReferenceImageViewFrame = fromReferenceImageViewFrame
        self.toReferenceImageViewFrame = toReferenceImageViewFrame
        
        let referenceImage = fromReferenceImageView.image!
        
//        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        if animator.transitionImageView == nil {
            let transitionImageView = UIImageView(image: referenceImage)
            transitionImageView.contentMode = .scaleAspectFill
            transitionImageView.clipsToBounds = true
            transitionImageView.frame = fromReferenceImageViewFrame
            animator.transitionImageView = transitionImageView
            containerView.addSubview(transitionImageView)
        }
    }
}
