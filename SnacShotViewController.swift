//
//  SnacShotViewController.swift
//  Fiidup
//
//  Created by Kang Shiang Yap on 2015-07-03.
//  Copyright (c) 2015 Fiidup. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia

var screenSize: CGRect = UIScreen.mainScreen().bounds

class SnacShotViewController: UIViewController {
    var pageIndex : Int = 0
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var cameraUI: UIImagePickerController! = UIImagePickerController()
    var stillImageOutput: AVCaptureStillImageOutput! = AVCaptureStillImageOutput()
    var storingImage : UIImage!
    var outputsettings = NSDictionary(objectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey)
    
    @IBOutlet var ryanyap: UIImageView!
    
    
    @IBOutlet var captureView: UIView!
    @IBOutlet var cameraView: UIView!
    @IBOutlet var capturebackground: UIImageView!
    
    //store a device in this variable if we manage to find the device later
    var captureDevice : AVCaptureDevice?
    
    func load_themes(notification: NSNotification){
        self.captureBG.image = themes.lightcolorsquare
    }
    
    func loadthemes(){
        self.captureBG.image = themes.lightcolorsquare
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "load_themes:", name: "themestoblack", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "load_themes:", name: "themestopurplered", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "load_themes:", name: "themestotoblue", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "load_themes:", name: "themestored", object: nil)
        self.loadthemes()
        //self.captureView.center.y = captureView.frame.height/2 + screenSize.width
        //self.cameraView.frame.size.height = screenSize.width
        //self.cameraView.frame.size.width = screenSize.width
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        let devices = AVCaptureDevice.devices()
        //println(devices) //this will list out all available cameras and microphones
        captureSession.addOutput(stillImageOutput)
        
        self.stillImageOutput.outputSettings = outputsettings as [NSObject : AnyObject]
        //loop through all the captured devices on this phone
        for device in devices{
            //Make sure this particular device supports video
            if(device.hasMediaType(AVMediaTypeVideo)){
                //Check the position of back camera and store it in "capturedevice"
                if(device.position == AVCaptureDevicePosition.Back){
                    captureDevice  = device as? AVCaptureDevice
                    if captureDevice != nil{
                        println("Capture device found")
                        beginSession()
                    }
                }
                
            }
            
        }
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func beginSession(){
        configureDevice()
        var err : NSError? = nil
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        
        if err != nil{
            println("error: \(err?.localizedDescription)")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        // Making the camera screen square
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        // Adding the camera screen to cameraView
        self.cameraView.layer.addSublayer(previewLayer)
        
        //setting the camera screen inside cameraview. Note that camera screen is slightly smaller than the cameraview to get the red border.
        println("WIDTH IS \(cameraView.frame.width)")
        println("HEIGHT IS \(cameraView.frame.height)")
        previewLayer?.frame = CGRect(x: 0 , y: 0, width: screenSize.width, height: screenSize.width)
        captureSession.startRunning()
        
    }
    
    func configureDevice(){
        if let device = captureDevice{
            device.lockForConfiguration(nil)
            device.focusMode = .AutoFocus //locked, continuousAutoFocus
            
            device.unlockForConfiguration()
            
        }
    }
    
    func updateDeviceSettings(touchPer: CGPoint, isoValue : Float){
        if let device = captureDevice{
            if(device.lockForConfiguration(nil)){
                // device.setFocusModeLockedWithLensPosition(Float(touchPer.x), completionHandler: {(time) -> Void in})
                device.focusPointOfInterest = touchPer
                device.focusMode = AVCaptureFocusMode.AutoFocus
                
            }
            //            //Adjust the iso to have a value between minIso and maxIso
            //            let minIso = device.activeFormat.minISO
            //            let maxIso = device.activeFormat.maxISO
            //            let clampedIso = isoValue * (maxIso - minIso) + minIso
            //
            //            //device.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, ISO: clampedIso, completionHandler: { (time) -> Void in})
            
            
            device.unlockForConfiguration()
        }
    }
    
    //let screenWidth = UIScreen.mainScreen().bounds.size.width
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touchPer = touchPercent(touches.first as! UITouch)
        updateDeviceSettings(touchPer, isoValue: Float(touchPer.y))
        
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touchPer = touchPercent(touches.first as! UITouch)
        updateDeviceSettings(touchPer, isoValue: Float(touchPer.y))
    }
    
    //controlling ISO
    
    func touchPercent(touch : UITouch) -> CGPoint{
        
        let screenSize = UIScreen.mainScreen().bounds.size
        var touchPer = CGPointZero
        
        touchPer.x = touch.locationInView(self.cameraView).x / screenSize.width
        touchPer.y = touch.locationInView(self.cameraView).y / screenSize.height
        
        return touchPer
        
    }
    
    @IBAction func btnCaptureImage(sender: AnyObject) {
        
        var videoConnection : AVCaptureConnection?
        //var visibleLayerFrame : CGRect = cameraView.frame
        var metaRect:CGRect?
        //var metaData: AVCaptureOutput! = AVCaptureOutput()
        //metaRect = metadataOutputRectOfInterestForRect(visibleLayerFrame);
        var cropRect: CGRect = CGRect()
        var originalSize: CGSize
        var beforeCroppingImage: UIImage! = UIImage()
        var cgimg: CGImage?
        var cgimgTemp:CGImage?
        //var objectSession: AVCaptureSession = AVCaptureSession()
        
        println("btnCaptureImage")
        
        for connection in stillImageOutput.connections{
            
            for port in connection.inputPorts!{
                if(port.mediaType == AVMediaTypeVideo){
                    videoConnection = connection as? AVCaptureConnection
                    break
                }
            }
            
            
            if(videoConnection != nil){
                break
            }
        }
        
        
        
        if videoConnection != nil {
            
            
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection){
                (imageSampleBuffer: CMSampleBuffer!, error)in
                
                if(error != nil){
                    println(error)
                }
                println("Hello")
                let imageDataJpeg : NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                beforeCroppingImage = UIImage(data: imageDataJpeg)!
                println("testing")
                //NSNotificationCenter.defaultCenter().postNotificationName("imageCaptured", object: nil)
            }
            
            self.captureSession.stopRunning()
        }
        
        metaRect = self.previewLayer!.metadataOutputRectOfInterestForRect(self.previewLayer!.frame)
        //CGRect metaRect = [self.previewLayer.layer metadataOutputRectOfInterestForRect:self.cameraView.layer];
        
        
        originalSize = beforeCroppingImage!.size
        
        if(UIInterfaceOrientationIsPortrait(UIInterfaceOrientation.Portrait)){
            println("seomthing")
            let temp: CGFloat = originalSize.width
            originalSize.width = originalSize.height
            originalSize.height = temp
        }
        
        println(beforeCroppingImage.size)
        
        cropRect.origin.x = metaRect!.origin.x * originalSize.width
        cropRect.origin.y = metaRect!.origin.y * originalSize.height
        cropRect.size.width = metaRect!.size.width * originalSize.width
        cropRect.size.height = metaRect!.size.height * originalSize.height
        
        cropRect = CGRectIntegral(cropRect);
        println(cropRect)
        
        var cgimg2 = CGImageCreateWithImageInRect(beforeCroppingImage.CGImage!, cropRect)
        captureImage = UIImage(CGImage: cgimg2, scale: 1.0, orientation: UIImageOrientation.Right)
        println("testing")
        NSNotificationCenter.defaultCenter().postNotificationName("imageCaptured", object: nil)
        
        
        self.captureSession.stopRunning()
        
        
        
    }
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override   prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
