//
//  ViewController.swift
//  basic-camera
//
//  Created by Yash Gupta on 28/02/24.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    var captureSession: AVCaptureSession!
    var backCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice!
    var backInput: AVCaptureInput!
    var frontInput: AVCaptureInput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var cameraOutput: AVCapturePhotoOutput!
    
    enum CameraState {
        case front
        case back
    }
    
    var cameraState: CameraState = .back
    
    let capturedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.backgroundColor = UIColor.orange
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let captureButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .black
        button.tintColor = .white
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        return button
    }()
    
    let switchButton: UIButton = {
        let image = UIImage(named: "switch_camera")
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
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
    
    func getPermissions() {
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraAuthStatus {
        case .authorized:
            return
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
    }
    
    func setupUI() {
        view.backgroundColor = .white
        view.addSubview(capturedImageView)
        view.addSubview(captureButton)
        view.addSubview(switchButton)
        
        NSLayoutConstraint.activate([
            capturedImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            capturedImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            capturedImageView.widthAnchor.constraint(equalToConstant: 55),
            capturedImageView.heightAnchor.constraint(equalToConstant: 55),
            
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            captureButton.heightAnchor.constraint(equalToConstant: 60),
            captureButton.widthAnchor.constraint(equalToConstant: 60),
            
            switchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            switchButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            switchButton.heightAnchor.constraint(equalToConstant: 30),
            switchButton.widthAnchor.constraint(equalToConstant: 30)
        ])
        
    }
    
    func setUpCameraSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession = AVCaptureSession()
            self.captureSession.beginConfiguration()
            
            if self.captureSession.canSetSessionPreset(.photo) {
                self.captureSession.sessionPreset = .photo
            }
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
        
        captureSession.addInput(backInput)
    }
    
    func setupCameraPreview() {
        DispatchQueue.main.async {
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.view.layer.insertSublayer(self.previewLayer, below: self.capturedImageView.layer)
            self.previewLayer.frame = self.view.layer.frame
        }
    }
    
    func setupCameraOutput() {
        cameraOutput = AVCapturePhotoOutput()
        guard captureSession.canAddOutput(cameraOutput) else {
            fatalError("Could not add camera output.")
        }
        
        captureSession.addOutput(cameraOutput)
    }
    
    @objc func switchCamera() {
        if cameraState == .back {
            cameraState = .front
        } else {
            cameraState = .back
        }
        
        updateCameraInput()
    }
    
    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func updateCameraInput() {
        captureSession.beginConfiguration()
        if !captureSession.inputs.isEmpty {
            let currentInput = captureSession.inputs.first
            captureSession.removeInput(currentInput!)
        }
        
        if cameraState == .back {
            captureSession.addInput(backInput)
        } else {
            captureSession.addInput(frontInput)
        }
        captureSession.commitConfiguration()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let _photo = photo.fileDataRepresentation() else { fatalError("could not covert image to fileData") }
        let capturedImage = UIImage(data: _photo)
        
        capturedImageView.image = capturedImage
    }
}

