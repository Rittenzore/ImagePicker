import UIKit
import Photos

private let imageManager: PHCachingImageManager = {
    let imageManager = PHCachingImageManager()
    imageManager.allowsCachingHighQualityImages = false
    return imageManager
}()

public final class ImageFetcher {
    
    public var onSignal: ((Signal) -> Void)?
        
    public static func getPermissionIfNecessary(completionHandler: @escaping (Bool) -> Void) {
        guard PHPhotoLibrary.authorizationStatus() != .authorized else {
            completionHandler(true)
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            completionHandler(status == .authorized ? true : false)
        }
    }
    
    public static func fetch(_ completion: @escaping (_ assets: [PHAsset]) -> Void) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }
        
        DispatchQueue.global(qos: .background).async {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [.init(key: "creationDate", ascending: false)]
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            if fetchResult.count > 0 {
                var assets = [PHAsset]()
                fetchResult.enumerateObjects({ object, _, _ in
                    assets.append(object)
                })
                
                DispatchQueue.main.async {
                    completion(assets)
                }
            }
        }
    }
    
    public static func resolveAsset(
        _ asset: PHAsset,
        size: CGSize = CGSize(width: 720, height: 1280),
        completion: @escaping (_ image: UIImage?) -> Void
    ) {
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        
        imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: requestOptions
        ) { image, info in
            if let info = info,
                info["PHImageFileUTIKey"] == nil {
                DispatchQueue.main.async {
                    completion(image)
                }
            }
        }
    }
    
    public static func resolveAssets(_ assets: [PHAsset], size: CGSize = CGSize(width: 720, height: 1280)) -> [UIImage] {
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        var images = [UIImage]()
        for asset in assets {
            imageManager.requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, _ in
                if let image = image {
                    images.append(image)
                }
            }
        }
        return images
    }
}

// MARK: - Signal
public extension ImageFetcher {
    enum Signal {
        case onRestrictedPermission
        case onDeniedPersmission
    }
}
