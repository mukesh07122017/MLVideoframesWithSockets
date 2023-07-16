//
//  ViewController.swift
//  T2DML
//
//  Created by Mahi Sharma on 30/11/21.
//

import UIKit

import CoreVideo
import AVFoundation
import Starscream
import MLSocketSDK

let KBodyskeletonOn = true
class ViewController: UIViewController {
    
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    
    @IBOutlet private weak var cameraView: UIView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var repetitionCountLabel: UILabel!
    @IBOutlet weak var StatusLbl: UILabel!
    @IBOutlet weak var lbl_error: UILabel!
    @IBOutlet weak var lbl_error2: UILabel!
    @IBOutlet weak var lbl_error3: UILabel!
    @IBOutlet weak var lbl_stage: UILabel!
    @IBOutlet weak var lbl_angle: UILabel!
    @IBOutlet weak var lbl_velocity: UILabel!
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    let session = AVCaptureSession()
    private var target: Int = 90
    private var targetCount: Int = 0
    private var prevAngle:Int? = 0
    private var stage:String? = "None"
    var exerciseID:String? = ""
    var userImage: UIImage!
    var client: SocketClient!
    var pTimeFromResponse: Double = 0.0
    @IBOutlet weak var overlay: VisualizerView!
    var isConnected = false
    var cameraPossition = "front"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        UIApplication.shared.isIdleTimerDisabled = true
        userImage = UIImage(named: "scaledImage_2")
        StatusLbl.text = "Not Connected"
        lbl_error.backgroundColor =  UIColor.black.withAlphaComponent(0.5)
        lbl_error2.backgroundColor =  UIColor.black.withAlphaComponent(0.5)
        lbl_error3.backgroundColor =  UIColor.black.withAlphaComponent(0.5)
        lbl_stage.backgroundColor =  UIColor.black.withAlphaComponent(0.5)
        lbl_velocity.backgroundColor =  UIColor.black.withAlphaComponent(0.5)
        
        if(KBodyskeletonOn == true){
            self.overlay.isHidden = false
        }else{
            self.overlay.isHidden = true
        }
        cameraButton.isHidden = false
        //ws://3.18.131.173/ws/getimage/
        
        
   

        let ulrString = "ws://2d.localhost.com/ws/getimage/" + exerciseID! + "/?api_key=cdb3781977281e9e516b215dd410e319962caf8b"
        
        let uri = URL(string: ulrString)
        client = try! SocketClient(uri: uri!)
        client.onReady = { client in
            print("client is ready")
            self.StatusLbl.text = "Connected"
        }
        client.onClose = { client in
            print("client is close")
            self.client.connect()
        }
        client.onMetadataResponse = { [self] client, _ in
            let image: UIImage = self.userImage
            // Scale the image down.
            let scaledImage: UIImage = self.scaleToHeight(image: image, newHeight: 192)
            // Convert it to a bytearray.
            let frameSize = self.cameraView.frame.size
            let scaledSize = scaledImage.size
            self.scaleX = frameSize.width / scaledSize.width
            self.scaleY = frameSize.height / scaledSize.height
            let byteArray:[UInt8] = self.convertUIImage(image: scaledImage)
            // Send the image data.
            do {
                try client.sendImage(image: byteArray, height: Int(scaledSize.height), width: Int(scaledSize.width), prevAngle: prevAngle ?? 0, exerciseID: exerciseID!, stage: stage!, reps: targetCount,pTime: 0)

            } catch {
                print("Image data larger than 15kB!")
            }
        }
        client.onImageResponse = { [self]client, imageMessageResponse in
            //print(">>><<<< \(imageMessageResponse)")
            pTimeFromResponse = imageMessageResponse.pTime ?? 0.0
            let dataArray = imageMessageResponse.PointsArray
            self.prevAngle = imageMessageResponse.prevAngle
            if targetCount <=  imageMessageResponse.reps ?? 0{
                targetCount = imageMessageResponse.reps ?? 0
            }
            repetitionCountLabel.text = "\(targetCount)"
            lbl_angle.text = "\(imageMessageResponse.prevAngle ?? 0)"
            lbl_error.text = imageMessageResponse.errorMsgForcorr_1
            lbl_error2.text = imageMessageResponse.errorMsgForcorr_2
            lbl_error3.text = imageMessageResponse.errorMsgForcorr_3
            lbl_stage.text = "Stage: \(imageMessageResponse.stage ?? "")"
            lbl_velocity.text = "Velocity: \(imageMessageResponse.aVelocity ?? 0.0)"
            stage = imageMessageResponse.stage
            if(KBodyskeletonOn == true){
            self.overlay.setPoints(pointsArray: dataArray, xScale: self.scaleX, yScale: self.scaleY, imgWidth: self.cameraView.frame.size.width)
            self.overlay.setNeedsDisplay()
            }
        
        }
        client.onError = {client, errordic in
            print("\(errordic)")
            self.lbl_error.text = errordic["error"] as? String
            let otherAlert = UIAlertController(title: "Error", message: errordic["error"] as? String, preferredStyle: UIAlertController.Style.alert)
            let printSomething = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { _ in
                }
                otherAlert.addAction(printSomething)
            self.present(otherAlert, animated: true, completion: nil)
        }
        self.client.connect()
        

        
    }
    
    func doSomething(action: UIAlertAction) {
        //Use action.title
    }

    
    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
        setupAVCapture()
    }

    override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)

        stopCamera()
        self.client.Disconnect()
    
    }

    
    
    private func captureDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
      if #available(iOS 10.0, *) {
        let discoverySession = AVCaptureDevice.DiscoverySession(
          deviceTypes: [.builtInWideAngleCamera],
          mediaType: .video,
          position: .unspecified
        )
        return discoverySession.devices.first { $0.position == position }
      }
      return nil
    }
    
    
    func scaleToHeight(image: UIImage, newHeight: CGFloat) -> UIImage {
       // let ratio = newHeight / image.size.height
      // let newWidth = image.size.width * 1
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newHeight, height: newHeight), true, 1)
        
        image.draw(in: CGRect(origin: .zero, size: CGSize(width: newHeight, height: newHeight)))
        
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    func convertUIImage(image: UIImage) -> [UInt8] {
        guard let data = image.jpegData(compressionQuality: 0.1) else { return [] }
        return Array(data)
    }
    

}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBAction func switchCameraTapped(sender: Any) {
       // fatalError()
        //Change camera source
        let sessionNew = session
        //Remove existing input
        guard let currentCameraInput: AVCaptureInput = sessionNew.inputs.first else {
            return
        }
        
        //Indicate that some changes will be made to the session
        sessionNew.beginConfiguration()
        sessionNew.removeInput(currentCameraInput)
        
        //Get new input
        var newCamera: AVCaptureDevice! = nil
        if let input = currentCameraInput as? AVCaptureDeviceInput {
            if (input.device.position == .back) {
                cameraPossition = "front"
                newCamera = cameraWithPosition(position: .front)
            } else {
                cameraPossition = "back"
                newCamera = cameraWithPosition(position: .back)
            }
        }
        
        //Add input to session
        var err: NSError?
        var newVideoInput: AVCaptureDeviceInput!
        do {
            newVideoInput = try AVCaptureDeviceInput(device: newCamera)
        } catch let err1 as NSError {
            err = err1
            newVideoInput = nil
        }
        
        if newVideoInput == nil || err != nil {
            print("Error creating capture device input: \(err?.localizedDescription)")
        } else {
            sessionNew.addInput(newVideoInput)
        }
        
      
        //Commit all the configuration changes at once
        sessionNew.commitConfiguration()
        
    }
    
    // Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        for device in discoverySession.devices {
            if device.position == position {
                return device
            }
        }
        
        return nil
    }
    
    
    
    func setupAVCapture(){
        session.sessionPreset = AVCaptureSession.Preset.medium
        guard let device = AVCaptureDevice
                .default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                         for: .video,
                         position: cameraPossition == "front" ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back) else {
            return
        }
        captureDevice = device
        beginSession()
    }
    
    func beginSession(){
        var deviceInput: AVCaptureDeviceInput!
        
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            guard deviceInput != nil else {
                print("error: cant get deviceInput")
                return
            }
            
            if self.session.canAddInput(deviceInput){
                self.session.addInput(deviceInput)
            }
            
            videoDataOutput = AVCaptureVideoDataOutput()
            // videoDataOutput.alwaysDiscardsLateVideoFrames=true
            videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
            videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)
            
            if session.canAddOutput(self.videoDataOutput){
                session.addOutput(self.videoDataOutput)
            }
            
            videoDataOutput.connection(with: .video)?.isEnabled = true
            
            previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            let rootLayer :CALayer = self.cameraView.layer
            rootLayer.masksToBounds=true
            previewLayer.frame.size = self.cameraView.frame.size
            previewLayer.cornerRadius = 5
            rootLayer.addSublayer(self.previewLayer)
            session.startRunning()
        } catch let error as NSError {
            deviceInput = nil
            print("error: \(error.localizedDescription)")
        }
    }
    
    

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        
       if(self.client.isConnected == true){
            // print(">>>>>>>>>>>>>>>>>>>>>>>>>---<<<<")
            if let currentCameraInput: AVCaptureInput = self.session.inputs.first  {
                
                if let input = currentCameraInput as? AVCaptureDeviceInput {
                    if (input.device.position == .back) {
                        userImage = sampleBuffer.image(orientation: .right, scale: 0.1)!
                       // print("orientation222")
                        
                    } else {
                        //Front
                        let orientation = UIDevice.current.orientation
                        
                        switch (orientation) {
                        case .portrait:
                            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
                             let ciimage = CIImage(cvPixelBuffer: imageBuffer)
                             userImage = self.convert(cmage: ciimage.oriented(forExifOrientation: 6))
                           
                           // print("orientation")
                            break
                        case .landscapeRight:
                           // print("orientation right")
                            
                            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
                            let ciimage = CIImage(cvPixelBuffer: imageBuffer)
                            userImage = self.convert(cmage: ciimage.oriented(forExifOrientation: 1))
                           
                            break
                        case .landscapeLeft:
                            
                            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
                            let ciimage = CIImage(cvPixelBuffer: imageBuffer)
                            userImage = self.convert(cmage: ciimage.oriented(forExifOrientation: 3))
                          
                            break
                        default:
                            // print(orientation)
                            //print("portrait Defult")
                           let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
                            let ciimage = CIImage(cvPixelBuffer: imageBuffer)
                            userImage = self.convert(cmage: ciimage.oriented(forExifOrientation: 6))
                           // print("orientation111")
                            
                            if client.isConnected == true && client.isAuthenticate == true  {
                                DispatchQueue.main.async { [self] in
                              
                                    
                                    
                                    if(self.userImage != nil){
                                       // print("orientation111 >>>>")
                                        do {
                                        let scaledImage: UIImage = self.scaleToHeight(image: userImage, newHeight: 192)
                                        // Convert it to a bytearray.
                                        let frameSize = self.cameraView.frame.size
                                        let scaledSize = scaledImage.size
                                        self.scaleX = frameSize.width / scaledSize.width
                                        self.scaleY = frameSize.height / scaledSize.height

                                        let byteArray:[UInt8] = self.convertUIImage(image: scaledImage)

                                          //  try client.sendImage(image: byteArray, height: Int(scaledSize.height), width: Int(scaledSize.width), prevAngle: prevAngle ?? 0, exerciseID: exerciseID!, stage: stage!, reps: targetCount)
                                            
                                            try client.sendImage(image: byteArray, height: Int(scaledSize.height), width: Int(scaledSize.width), prevAngle: prevAngle ?? 0, exerciseID: exerciseID!, stage: stage!, reps: targetCount,pTime: pTimeFromResponse)

                                    } catch {
                                        print("Image data larger than 15kB!")
                                    }
                                    }
                                }
                            }
                            break
                            
                        }
                        //newCamera = cameraWithPosition(position: .back)
                    }
                }
            }
        }
        
    }
    
    
    func imageFromSampleBuffer(
            sampleBuffer: CMSampleBuffer,
            videoOrientation: AVCaptureVideoOrientation) -> UIImage? {
   //     print(videoOrientation)
        
            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let context = CIContext()
                var ciImage = CIImage(cvPixelBuffer: imageBuffer)

                // FIXME: - change to Switch
                if videoOrientation == .landscapeLeft {
                    ciImage = ciImage.oriented(forExifOrientation: 3)
                } else if videoOrientation == .landscapeRight {
                    ciImage = ciImage.oriented(forExifOrientation: 1)
                } else if videoOrientation == .portrait {
                    ciImage = ciImage.oriented(forExifOrientation: 6)
                } else if videoOrientation == .portraitUpsideDown {
                    ciImage = ciImage.oriented(forExifOrientation: 8)
                }

                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }

            return nil
        }
    
    func convert(cmage: CIImage) -> UIImage {
         let context = CIContext(options: nil)
         let cgImage = context.createCGImage(cmage, from: cmage.extent)!
         let image = UIImage(cgImage: cgImage)
        
        return image.resized(withPercentage: 1.0)!
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            // showAlertWith(title: "Save error", message: error.localizedDescription)
            print("Save error")
        } else {
            print("Saved!")
            // showAlertWith(title: "Saved!", message: "Your image has been saved to your photos.")
        }
    }
    
    
    // clean up AVCapture
    func stopCamera(){
        session.stopRunning()
    }
    
    
}


//MARK: -  CMSampleBuffer get image from session 
extension CMSampleBuffer {
    // right and down
    
    func image(orientation: UIImage.Orientation,
               scale: CGFloat) -> UIImage? {
        if let buffer = CMSampleBufferGetImageBuffer(self) {
            let ciImage = CIImage(cvPixelBuffer: buffer)
            
            
            
            return UIImage(ciImage: ciImage,
                           scale: scale,
                           orientation: orientation)
        }
        
        return nil
    }
}


extension UIImage {
    
    func resizeByByte(maxByte: Int, completion: @escaping (Data) -> Void) {
        var compressQuality: CGFloat = 1
        var imageData = Data()
        var imageByte = self.jpegData(compressionQuality: 1)?.count
        
        while imageByte! > maxByte {
            imageData = self.jpegData(compressionQuality: compressQuality)!
            imageByte = self.jpegData(compressionQuality: compressQuality)?.count
            compressQuality -= 0.1
        }
        
        if maxByte > imageByte! {
            completion(imageData)
        } else {
            completion(self.jpegData(compressionQuality: 1)!)
        }
    }
    
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func resizedTo1MB() -> UIImage? {
        guard let imageData = self.pngData() else { return nil }
        
        var resizingImage = self
        var imageSizeKB = Double(imageData.count) / 1000.0 // ! Or devide for 1024 if you need KB but not kB
        
        while imageSizeKB > 1000 { // ! Or use 1024 if you need KB but not kB
            guard let resizedImage = resizingImage.resized(withPercentage: 0.9),
                  let imageData = resizedImage.pngData()
            else { return nil }
            
            resizingImage = resizedImage
            imageSizeKB = Double(imageData.count) / 1000.0 // ! Or devide for 1024 if you need KB but not kB
        }
        
        return resizingImage
    }
    
}

