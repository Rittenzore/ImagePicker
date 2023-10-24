//
//  ViewController.swift
//  ExampleApp
//
//  Created by Adel Khadiev on 24.10.2023.
//

import UIKit
import ImagePicker

class ViewController: UIViewController {
    
    private lazy var showImagesButton: UIButton = {
        let button = UIButton()
        button.setTitle("Show images", for: .normal)
        button.addTarget(self, action: #selector(showImagesButtonDidTap), for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 50 / 2
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavbarAppearance()
        setupView()
    }
}

// MARK: - Private methods
private extension ViewController {
    func setupView() {
        showImagesButton.frame = .init(
            x: view.center.x - 120 / 2,
            y: view.center.y,
            width: 120,
            height: 50
        )
        view.addSubview(showImagesButton)
    }
    
    func setupNavbarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .bold)
        ]
        
        appearance.titleTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)]
        
        appearance.shadowColor = .clear
        appearance.backgroundImage = UIImage()
        appearance.shadowImage = UIImage()
        appearance.backgroundColor = UIColor.red
        
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Objc private methods
@objc private extension ViewController {
    func showImagesButtonDidTap() {
        let vc = ImagesGalleryViewController()
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true)
    }
}
