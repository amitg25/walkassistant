//
//  ViewController.swift
//  vWalkAssistant
//
//  Created by Amit Gupta on 2/3/20.
//  Copyright © 2020 Amit Gupta. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision
import ImageIO

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate  {

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var prediction: UILabel!
    
    var captureSession : AVCaptureSession!
    var cameraOP : AVCapturePhotoOutput!
    var previewLayer : AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupCamera()
    }

    func setupCamera() {
        captureSession = AVCaptureSession()
        
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        cameraOP = AVCapturePhotoOutput()
        
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        
        if let input = try? AVCaptureDeviceInput(device: device!) {
            if (captureSession.canAddInput(input)) {
                captureSession.addInput(input)
                
                if (captureSession.canAddOutput(cameraOP)) {
                    captureSession.addOutput(cameraOP)
                }
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                
                previewLayer.frame = previewView.bounds
                previewView.layer.addSublayer(previewLayer)
                
                captureSession.startRunning()
            } else {
                print("Unable to add input")
            }
        } else {
            print("Unable to find an input")
        }
        self.launchAI()
    }
    
    
    @objc func launchAI() {
        // Capture an image from Video stream
        
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
            kCVPixelBufferWidthKey as String: 160,
            kCVPixelBufferHeightKey as String: 160
        ]
        
        settings.previewPhotoFormat = previewFormat
        
        cameraOP.capturePhoto(with: settings, delegate: self)
        
        // Feed image as the input into ML Model
        
        // Capture the result, display in the UI Label.
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("error occurred: \(error.localizedDescription)")
        }
        
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            self.predict(image: image)
        }
    }
    
    func predict(image: UIImage) {
        // use captured image as input into signs model, run the model and get prediction
         
        if let data = image.pngData() {
            let fileName = getDocumentsDirectory().appendingPathComponent("image.png")
            try? data.write(to: fileName)
            
            let model = try! VNCoreMLModel(for: signs().model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: predictionCompleted)
            
            let handler = VNImageRequestHandler(url: fileName)
            try! handler.perform([request])
        }
        
        
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func predictionCompleted(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else {
            fatalError("Unable to get prediction output")
        }
        
        var bestPrediction = ""
        var confidence : VNConfidence = 0
        
        for classification in results {
            if classification.confidence > confidence {
                confidence = classification.confidence
                bestPrediction = classification.identifier
            }
            
        }
        
        self.prediction.text = self.prediction.text! + bestPrediction + "\n"
        
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.launchAI), userInfo: nil, repeats: false)
    }
}

