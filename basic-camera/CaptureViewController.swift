//
//  ViewController.swift
//  basic-camera
//
//  Created by Yash Gupta on 28/02/24.
//

import UIKit
import AVFoundation

class CaptureViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    
    var captureSession: AVCaptureSession!
    var backCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice!
    
    var backInput: AVCaptureInput!
    var frontInput: AVCaptureInput!
    var audioInput: AVCaptureInput!
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var photoOutput: AVCapturePhotoOutput!
    var videoOutput: AVCaptureMovieFileOutput!
    
    var capturedImage: UIImage!
    var capturedVideoPath: URL!
    
    enum CameraState {
        case front
        case back
    }
    
    enum MediaType {
        case photo
        case video
    }
    
    var cameraState: CameraState = .back
    var cameraOutput: MediaType = .photo
    
    var lastCapturedMedia: MediaType!
    
    lazy var captureButton: UIButton = {
        let button = UIButton()
        
        button.layer.cornerRadius = 34
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.black.withAlphaComponent(0.75).cgColor
        button.backgroundColor = UIColor.gray.withAlphaComponent(0.4)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleHoldAndRelease(_:)))
        button.addGestureRecognizer(longPressGestureRecognizer)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTouch(_:)))
        button.addGestureRecognizer(tapGestureRecognizer)
        return button
    }()
    
    
    @objc func handleHoldAndRelease(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            startVideoRecording()
        } else if sender.state == .ended {
            stopVideoRecording()
        }
    }
    
    @objc func handleTouch(_ sender: UITapGestureRecognizer) {
        capturePhoto()
    }
    
    lazy var switchButton: UIButton = {
        let image = UIImage(named: "switch_camera")
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.gray.withAlphaComponent(0.4)
        button.layer.cornerRadius = 26
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        
        let padding: CGFloat = 14
        button.contentEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        
        button.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getPermissions()
        setUpCameraSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    func getPermissions() {
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraAuthStatus {
        case .authorized:
            break
        case .denied:
            abort()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: {
                (authorized) in
                guard authorized else { abort() }
            })
        case .restricted:
            abort()
        default:
            fatalError()
            
        }
        
        let audioAuthStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        switch audioAuthStatus {
        case .authorized:
            break
        case .denied:
            abort()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: {
                (authorized) in
                guard authorized else { abort() }
            })
        case .restricted:
            abort()
        default:
            fatalError()
            
        }
    }
    
    func setupUI() {
        view.backgroundColor = .white
        view.addSubview(captureButton)
        view.addSubview(switchButton)
        
        NSLayoutConstraint.activate([
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            captureButton.heightAnchor.constraint(equalToConstant: 68),
            captureButton.widthAnchor.constraint(equalToConstant: 68),
            
            switchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            switchButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            switchButton.heightAnchor.constraint(equalToConstant: 52),
            switchButton.widthAnchor.constraint(equalToConstant: 52)
        ])
        
    }
    
    func setUpCameraSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession = AVCaptureSession()
            self.captureSession.beginConfiguration()
            
            self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
            
            self.setupCameraInput()
            self.setupCameraPreview()
            self.setupCameraOutput()
            
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
    }
    
    func setupCameraInput() {
        // setting up back camera
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            fatalError("Could not create back camera.")
        }
        
        guard let _backInput = try? AVCaptureDeviceInput(device: backCamera) else {
            fatalError("Could not create back input")
        }
        
        backInput = _backInput
        guard captureSession.canAddInput(backInput) else {
            fatalError("Could not add back input to capture session.")
        }
        
        // setting up front camera
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("Could not create front camera.")
        }
        
        guard let _frontInput = try? AVCaptureDeviceInput(device: frontCamera) else {
            fatalError("Could not create front input")
        }
        
        frontInput = _frontInput
        guard captureSession.canAddInput(frontInput) else {
            fatalError("Could not add front input to capture session.")
        }
        
        // setting up audio
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            fatalError("Could not create audio.")
        }
        
        guard let _audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            fatalError("Could not create front input")
        }
        
        audioInput = _audioInput
        guard captureSession.canAddInput(audioInput) else {
            fatalError("Could not add audio input to capture session.")
        }
        
        captureSession.addInput(audioInput)
        captureSession.addInput(backInput)
    }
    
    func setupCameraOutput() {
        photoOutput = AVCapturePhotoOutput()
        guard captureSession.canAddOutput(photoOutput) else {
            fatalError("Could not add photo output.")
        }
        
        videoOutput = AVCaptureMovieFileOutput()
        guard captureSession.canAddOutput(videoOutput) else {
            fatalError("Could not add video output.")
        }
        
        updateCameraOutput()
    }
    
    func setupCameraPreview() {
        DispatchQueue.main.async {
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.view.layer.insertSublayer(self.previewLayer, below: self.captureButton.layer)
            self.previewLayer.videoGravity = .resizeAspectFill
            self.previewLayer.frame = self.view.bounds
        }
    }
    
    func updateCameraOutput() {
        captureSession.beginConfiguration()
        if !captureSession.outputs.isEmpty {
            let currentOutput = captureSession.outputs.first
            captureSession.removeOutput(currentOutput!)
        }
        
        if cameraOutput == .photo {
            captureSession.addOutput(photoOutput)
        } else {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.commitConfiguration()
    }
    
    @objc func switchCamera() {
        print("DEBUG: \(#function) called")
        if cameraState == .back {
            cameraState = .front
        } else {
            cameraState = .back
        }
        
        updateCameraInput()
    }
    
    func capturePhoto() {
        print("DEBUG: \(#function) called")
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc func startVideoRecording() {
        print("DEBUG: \(#function) called")
        cameraOutput = .video
        updateCameraOutput()
        
        let outputPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("basic-camera-output.mov")
        if FileManager.default.fileExists(atPath: outputPath.path()) {
            try! FileManager.default.removeItem(at: outputPath)
            print("Deleted file from path.")
        } else {
            print("File does not exist at path. Nothing to delete.")
        }
 
        videoOutput.startRecording(to: outputPath, recordingDelegate: self)
    }
    
    @objc func stopVideoRecording() {
        print("DEBUG: \(#function) called")
        videoOutput.stopRecording()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // switching back to photo mode
        cameraOutput = .photo
        updateCameraOutput()
        
        if let error = error {
            print("Error recording video: \(error)")
        } else {
            print("Successfully recorded video at \(outputFileURL)")
            self.capturedVideoPath = outputFileURL
            self.lastCapturedMedia = .video
            moveToReviewVC()
        }
    }
    
    func updateCameraInput() {
        captureSession.beginConfiguration()
        let currentInput = captureSession.inputs.last
        captureSession.removeInput(currentInput!)
        print("Removing current camera input")
        
        if cameraState == .back {
            captureSession.addInput(backInput)
        } else {
            captureSession.addInput(frontInput)
        }
        captureSession.commitConfiguration()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let _photo = photo.fileDataRepresentation() else { fatalError("could not covert image to fileData") }
        let _capturedImage = UIImage(data: _photo)
        
        self.capturedImage = _capturedImage
        self.lastCapturedMedia = .photo
        moveToReviewVC()
    }
    
    @objc func moveToReviewVC() {
        print("DEBUG: \(#function) called")
        
        DispatchQueue.global(qos: .userInitiated).async {
            if self.captureSession != nil {
                // can remove this too for faster camera re-start
                self.captureSession.stopRunning()
            }
        }
        let destinationVC = ReviewViewController()
        
        if lastCapturedMedia == .photo {
            destinationVC.capturedImage = capturedImage
            destinationVC.mediaType = .photo
        } else {
            destinationVC.captureVideoPath = capturedVideoPath
            destinationVC.mediaType = .video
        }

        navigationController?.pushViewController(destinationVC, animated: true)
    }
}

