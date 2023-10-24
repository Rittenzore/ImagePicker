import UIKit

extension UICollectionView {
    static func defaultReuseId(for elementType: UIView.Type) -> String {
        String(describing: elementType)
    }
    
    func dequeueReusableCellWithRegistration<T: UICollectionViewCell>(
        type: T.Type,
        indexPath: IndexPath,
        reuseId: String? = nil
    ) -> T {
        let normalizedReuseId = reuseId ?? UICollectionView.defaultReuseId(for: T.self)
        
        register(type, forCellWithReuseIdentifier: normalizedReuseId)
        
        if let cell = dequeueReusableCell(withReuseIdentifier: normalizedReuseId, for: indexPath) as? T {
            return cell
        }
                
        guard let cell = dequeueReusableCell(withReuseIdentifier: normalizedReuseId, for: indexPath) as? T else {
            fatalError("couldnt dequeueReusable cell in dequeueReusableCellWithRegistration<T: UICollectionViewCell>")
        }
        
        return cell
    }
}
