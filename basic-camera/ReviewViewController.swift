//
//  ReviewViewController.swift
//  basic-camera
//
//  Created by Yash Gupta on 01/03/24.
//

import Foundation
import UIKit
import AVFoundation

class ReviewViewController: UIViewController {
    var capturedImage: UIImage!
    var captureVideoPath: URL!
    var mediaType: MediaType!
    
    enum MediaType {
        case photo
        case video
    }
    
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
        if self.mediaType == .photo {
            handlePhoto()
        } else {
            handleVideo()
        }
    }
    
    func handlePhoto() {
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
    
    func handleVideo() {
        let player = AVPlayer(url: captureVideoPath!)
        let playerLayer = AVPlayerLayer(player: player)
        let topMargin: CGFloat = 25
        playerLayer.frame = CGRect(x: 0, y: topMargin, width: self.view.bounds.width, height: self.view.bounds.height - topMargin)
        self.view.layer.addSublayer(playerLayer)
        player.play()
    }
}
