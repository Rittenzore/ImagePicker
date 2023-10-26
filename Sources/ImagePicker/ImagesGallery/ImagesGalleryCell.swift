import UIKit

public protocol ImagesGalleryCellDelegate: AnyObject {
    func selectButtonDidTap(uiImage: UIImage)
}

public final class ImagesGalleryCell: UICollectionViewCell {
    
    private weak var delegate: ImagesGalleryCellDelegate?
    private var uiImage: UIImage?
    
    private lazy var darkView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.4)
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private lazy var selectButton: UIButton = {
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
    
    private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // MARK: - Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupCell()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(
        _ uiImage: UIImage,
        isSelected: Bool,
        isSelectable: Bool,
        isReachedLimit: Bool,
        delegate: ImagesGalleryCellDelegate? = nil
    ) {
        self.delegate = delegate
        self.uiImage = uiImage
        
        imageView.image = uiImage
        
        selectButton.isHidden = !isSelectable
        selectButton.setImage(
            UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle"),
            for: .normal
        )
        
        darkView.isHidden = isReachedLimit
    }
}

// MARK: - Private methods
private extension ImagesGalleryCell {
    func setupCell() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            contentView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            contentView.rightAnchor.constraint(equalTo: imageView.rightAnchor)
        ])
                
        darkView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(darkView)
        NSLayoutConstraint.activate([
            darkView.topAnchor.constraint(equalTo: contentView.topAnchor),
            darkView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            contentView.bottomAnchor.constraint(equalTo: darkView.bottomAnchor),
            contentView.rightAnchor.constraint(equalTo: darkView.rightAnchor)
        ])
        
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(selectButton)
        NSLayoutConstraint.activate([
            selectButton.heightAnchor.constraint(equalToConstant: 24),
            selectButton.widthAnchor.constraint(equalToConstant: 24),
            
            contentView.bottomAnchor.constraint(equalTo: selectButton.bottomAnchor, constant: 2),
            contentView.rightAnchor.constraint(equalTo: selectButton.rightAnchor, constant: 2)
        ])
    }
}

// MARK: - Objc methods
@objc private extension ImagesGalleryCell {
    func selectButtonDidTap() {
        guard let uiImage else { return }
        delegate?.selectButtonDidTap(uiImage: uiImage)
    }
}
