//
//  ReviewViewController.swift
//  basic-camera
//
//  Created by Yash Gupta on 01/03/24.
//

import Foundation
import UIKit

class ReviewViewController: UIViewController {
    var capturedImage: UIImage!
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.backgroundColor = UIColor.orange
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.barTintColor = UIColor.lightGray
    }
    
    func setupView() {
        view.backgroundColor = .black
        view.addSubview(imageView)
        if let capturedImage {
            imageView.image = capturedImage
        }
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
}
