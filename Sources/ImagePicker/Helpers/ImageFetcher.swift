import UIKit
import Photos

public protocol ImageFetcherProtocol: AnyObject {
    func getImages(completion: @escaping ([UIImage]) -> Void)
}

public final class ImageFetcher: ImageFetcherProtocol {
    
    public var onSignal: ((Signal) -> Void)?
    
    public func getImages(completion: @escaping ([UIImage]) -> Void) {
        requestAuthorization { [weak self] status in
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
                let imageManager = PHImageManager.default()
                
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
                        completion(images)
                    }
                } else {
                    return
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
            var output = [UIImage?](repeating: nil, count: fetchResult.count)
            let dispatchGroup = DispatchGroup()

            for index in 0..<fetchResult.count {
                let asset = fetchResult.object(at: index)
                let size = CGSize(
                    width: 200 * UIScreen.main.scale,
                    height: 200 * UIScreen.main.scale
                )
                
                dispatchGroup.enter()
                
                imageManager.requestImage(
                    for: asset,
                    targetSize: size,
                    contentMode: .aspectFill,
                    options: requestOptions
                ) { image, _ in
                    if let image {
                        output[index] = image
                    }
                    
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                let sortedImages = output.compactMap { $0 }
                completion(sortedImages)
            }
        }
    
    func requestAuthorization(completion: @escaping (_ status: PHAuthorizationStatus) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            completion(status)
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
