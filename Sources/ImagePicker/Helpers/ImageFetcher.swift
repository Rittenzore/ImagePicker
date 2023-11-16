import UIKit
import Photos

public protocol ImageFetcherProtocol: AnyObject {
    func getImages(completion: @escaping ([UIImage]) -> Void)
}

public final class ImageFetcher: ImageFetcherProtocol {
    
    public var onSignal: ((Signal) -> Void)?
    
    private let imageCache = NSCache<NSString, UIImage>()
    
    public static func getPermissionIfNecessary(completionHandler: @escaping (Bool) -> Void) {
        guard PHPhotoLibrary.authorizationStatus() != .authorized else {
            completionHandler(true)
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            completionHandler(status == .authorized ? true : false)
        }
    }
    
    public static func resolveAsset(_ asset: PHAsset, size: CGSize = CGSize(width: 720, height: 1280), completion: @escaping (_ image: UIImage?) -> Void) {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        
        imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, info in
            if let info = info,
                info["PHImageFileUTIKey"] == nil {
                DispatchQueue.main.async {
                    completion(image)
                }
            }
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
    
    public static func resolveAssets(_ assets: [PHAsset], size: CGSize = CGSize(width: 720, height: 1280)) -> [UIImage] {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        var images = [UIImage]()
        for asset in assets {
            imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, _ in
                if let image = image {
                    images.append(image)
                }
            }
        }
        return images
    }
    
    public func getImages(completion: @escaping ([UIImage]) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            switch status {
            case .notDetermined:
                break
                
            case .restricted:
                DispatchQueue.main.async {
                    self?.onSignal?(.onRestrictedPermission)
                }
                
            case .denied:
                DispatchQueue.main.async {
                    self?.onSignal?(.onDeniedPersmission)
                }
                
            case .authorized, .limited:
                DispatchQueue.global(qos: .userInitiated).async {
                    let imageManager = PHCachingImageManager()
                    imageManager.allowsCachingHighQualityImages = false
                    
                    let requestOptions = PHImageRequestOptions()
                    requestOptions.deliveryMode = .highQualityFormat
                    requestOptions.isNetworkAccessAllowed = true
                    
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [.init(key: "creationDate", ascending: false)]
                    
                    let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                    
                    if fetchResult.count > 0 {
                        self?.fetchPhotos(
                            imageManager: imageManager,
                            fetchResult: fetchResult,
                            requestOptions: requestOptions
                        ) { images in
                            DispatchQueue.main.async {
                                completion(images)
                            }
                        }
                    } else {
                        return
                    }
                }
                
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Private methods
private extension ImageFetcher {
    func fetchPhotos(
        imageManager: PHImageManager,
        fetchResult: PHFetchResult<PHAsset>,
        requestOptions: PHImageRequestOptions,
        completion: @escaping ([UIImage]) -> Void
    ) {
        let group = DispatchGroup()
        var imageWithAssets: [ImageWithAsset] = []
        
        for index in 0..<fetchResult.count {
            group.enter()
            
            let asset = fetchResult.object(at: index)
            let size = CGSize(width: 200 * UIScreen.main.scale, height: 200 * UIScreen.main.scale)
            
            imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, _ in
                if let image {
                    let imageWithAsset = ImageWithAsset(image: image, asset: asset)
                    imageWithAssets.append(imageWithAsset)
                }
                
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
            let sortedImages = imageWithAssets.sorted(by: { $0.asset.creationDate ?? Date() > $1.asset.creationDate ?? Date() })
            let sortedImagesOnly: [UIImage] = sortedImages.map { $0.image }
            
            DispatchQueue.main.async {
                completion(sortedImagesOnly)
            }
        }
    }
}

// MARK: - Signal
public extension ImageFetcher {
    enum Signal {
        case onRestrictedPermission
        case onDeniedPersmission
    }
}

struct ImageWithAsset {
    let image: UIImage
    let asset: PHAsset
}
