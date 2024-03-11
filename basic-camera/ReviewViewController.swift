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
    
    var player: AVPlayer!
    
    enum MediaType {
        case photo
        case video
    }
    
    var isMute = false
    var isPlaying = true
    
    lazy var videoControlButton: UIButton = {
        let image = isPlaying ? UIImage(named: "pause") : UIImage(named: "play")
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        button.layer.cornerRadius = 24
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        
        let padding: CGFloat = 13
        button.contentEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        
        button.addTarget(self, action: #selector(onVideoControlClick), for: .touchUpInside)
        return button
    }()
    
    lazy var muteControlButton: UIButton = {
        let image = isMute ? UIImage(named: "mute") : UIImage(named: "volume")
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        button.layer.cornerRadius = 24
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        
        let padding: CGFloat = 13
        button.contentEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        
        button.addTarget(self, action: #selector(onMuteControlClick), for: .touchUpInside)
        return button
    }()
    
    lazy var saveLabel: CustomUILabel = {
        let label = CustomUILabel()
        label.layer.cornerRadius = 20
        label.textColor = .black
        label.backgroundColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        label.text = "Save"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.clipsToBounds = true
        label.font = UIFont.systemFont(ofSize: 17)

        label.paddingTop = 12
        label.paddingBottom = 12
        label.paddingLeft = 12
        label.paddingRight = 12
        
        label.isUserInteractionEnabled = true // Enable user interaction for the label
        
        // Add a tap gesture recognizer to the label
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(saveMedia))
        label.addGestureRecognizer(tapGesture)
        
        return label
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.backgroundColor = UIColor.orange
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        
        // background event
        NotificationCenter.default.addObserver(self, selector: #selector(stopPlayer), name: UIApplication.didEnterBackgroundNotification, object: nil)

        // foreground event
        NotificationCenter.default.addObserver(self, selector: #selector(restartPlayer), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.barTintColor = UIColor.lightGray
    }
    
    @objc func saveMedia() {
        if mediaType == .photo {
            saveImageToGallery()
        } else {
            saveVideoToGallery()
        }
        
        saveLabel.isUserInteractionEnabled = false
        saveLabel.text = "Saved!!"
        saveLabel.textColor = .purple
    }
    
    @objc func onVideoControlClick() {
        isPlaying = !isPlaying
        if isPlaying {
            restartPlayer()
        } else {
            stopPlayer()
        }
        
        let image = isPlaying ? UIImage(named: "pause") : UIImage(named: "play")
        videoControlButton.setImage(image, for: .normal)
    }
    
    @objc func onMuteControlClick() {
        isMute = !isMute
        player.isMuted = isMute
        
        let image = isMute ? UIImage(named: "mute") : UIImage(named: "volume")
        muteControlButton.setImage(image, for: .normal)
    }
    
    func setupView() {
        view.backgroundColor = .black
        if self.mediaType == .photo {
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
        } else {
            view.addSubview(videoControlButton)
            view.addSubview(muteControlButton)
            
            NSLayoutConstraint.activate([
                videoControlButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
                videoControlButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
                videoControlButton.heightAnchor.constraint(equalToConstant: 48),
                videoControlButton.widthAnchor.constraint(equalToConstant: 48),
                
                muteControlButton.topAnchor.constraint(equalTo: videoControlButton.bottomAnchor, constant: 12),
                muteControlButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
                muteControlButton.heightAnchor.constraint(equalToConstant: 48),
                muteControlButton.widthAnchor.constraint(equalToConstant: 48),
            ])
            
            handleVideo()
        }
        
        view.addSubview(saveLabel)
        
        let bottomMargin = self.mediaType == .photo ? -15 : -35
        NSLayoutConstraint.activate([
            saveLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: CGFloat(bottomMargin)),
            saveLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            saveLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 75)
        ])
    }
    
    func handleVideo() {
        player = AVPlayer(url: captureVideoPath!)
        let playerLayer = AVPlayerLayer(player: player)
        let topMargin: CGFloat = 25
        playerLayer.frame = CGRect(x: 0, y: topMargin, width: self.view.bounds.width, height: self.view.bounds.height - topMargin)
        self.view.layer.insertSublayer(playerLayer, below: videoControlButton.layer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        player.play()
    }
    
    @objc func playerDidFinishPlaying() {
        player.seek(to: .zero)
        onVideoControlClick()
    }
    
    @objc func stopPlayer() {
        player?.pause()
    }
    
    @objc func restartPlayer() {
        if player != nil {
            player.play()
        }
    }
    
    func saveImageToGallery() {
        UIImageWriteToSavedPhotosAlbum(capturedImage!, self, #selector(postImageSave(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func saveVideoToGallery() {
        print("Video url: \(captureVideoPath.relativePath)")
        UISaveVideoAtPathToSavedPhotosAlbum(captureVideoPath.relativePath, nil, #selector(postVideoSave(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc func postImageSave(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            fatalError(error.localizedDescription)
        } else {
            print("Successfully saved image!")
        }
    }
    
    @objc func postVideoSave(_ videoPath: String?, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer?) {
        if let error = error {
            fatalError(error.localizedDescription)
        } else {
            print("Successfully saved video!")
        }
    }
}
