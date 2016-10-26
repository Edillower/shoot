
import UIKit
import AVKit
import AVFoundation
import AssetsLibrary
import Firebase
import AWSS3



var SessionRunningAndDeviceAuthorizedContext = "SessionRunningAndDeviceAuthorizedContext"
var CapturingStillImageContext = "CapturingStillImageContext"
var RecordingContext = "RecordingContext"
let ref = Firebase(url: "https://jrecse.firebaseio.com/images")

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    var sessionQueue: DispatchQueue!
    var session: AVCaptureSession?
    var videoDeviceInput: AVCaptureDeviceInput?
    var movieFileOutput: AVCaptureMovieFileOutput?
    var stillImageOutput: AVCaptureStillImageOutput?
    var isVideo: Bool?
    var videoFileURL: URL?
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    
    @IBOutlet weak var mediaPreviewView: UIView!
    
    var deviceAuthorized: Bool  = false
    var backgroundRecordId: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var sessionRunningAndDeviceAuthorized: Bool {
        get {
            return (self.session?.isRunning != nil && self.deviceAuthorized )
        }
    }
    
    var runtimeErrorHandlingObserver: AnyObject?
    var lockInterfaceRotation: Bool = false
    
    @IBOutlet weak var myVideoView: UIView!
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var previewView: AVCamPreviewView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var snapButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    
    
    
    // MARK: Override methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mediaPreviewView.isHidden = true
        myVideoView.isHidden = true
        myImageView.isHidden = true
        self.isVideo = false
        
        let session: AVCaptureSession = AVCaptureSession()
        self.session = session
        self.session?.sessionPreset = AVCaptureSessionPresetMedium
        
        self.previewView.session = session
        
        self.checkDeviceAuthorizationStatus()
        
        let sessionQueue: DispatchQueue = DispatchQueue(label: "session queue",attributes: [])
        
        self.sessionQueue = sessionQueue
        sessionQueue.async(execute: {
            self.backgroundRecordId = UIBackgroundTaskInvalid
            
            let videoDevice: AVCaptureDevice! = CameraViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: AVCaptureDevicePosition.back)
            var error: NSError? = nil
            
            
            
            var videoDeviceInput: AVCaptureDeviceInput?
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            } catch let error1 as NSError {
                error = error1
                videoDeviceInput = nil
            } catch {
                fatalError()
            }
            
            if (error != nil) {
                print(error)
                let alert = UIAlertController(title: "Error", message: error!.localizedDescription
                    , preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            
            if session.canAddInput(videoDeviceInput){
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async(execute: {
                    // Why are we dispatching this to the main queue?
                    // Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView can only be manipulated on main thread.
                    // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                    
                    let orientation: AVCaptureVideoOrientation =  AVCaptureVideoOrientation(rawValue: self.interfaceOrientation.rawValue)!
                    
                    
                    (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = orientation
                    
                })
                
            }
            
            
            let audioDevice: AVCaptureDevice = AVCaptureDevice.devices(withMediaType: AVMediaTypeAudio).first as! AVCaptureDevice
            
            var audioDeviceInput: AVCaptureDeviceInput?
            
            do {
                audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            } catch let error2 as NSError {
                error = error2
                audioDeviceInput = nil
            } catch {
                fatalError()
            }
            
            if error != nil{
                print(error)
                let alert = UIAlertController(title: "Error", message: error!.localizedDescription
                    , preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            if session.canAddInput(audioDeviceInput){
                session.addInput(audioDeviceInput)
            }
            
            
            
            let movieFileOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
            if session.canAddOutput(movieFileOutput){
                session.addOutput(movieFileOutput)
                
                
                let connection: AVCaptureConnection? = movieFileOutput.connection(withMediaType: AVMediaTypeVideo)
                let stab = connection?.isVideoStabilizationSupported
                if (stab != nil) {
                    connection!.enablesVideoStabilizationWhenAvailable = true
                }
                
                self.movieFileOutput = movieFileOutput
                
            }
            
            let stillImageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
            if session.canAddOutput(stillImageOutput){
                stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG,
                    //                    AVVideoScalingModeFit: AVLayerVideoGravityResize,
                    AVVideoCompressionPropertiesKey: [AVVideoQualityKey: 1.0]
                ]
                
                session.addOutput(stillImageOutput)
                
                self.stillImageOutput = stillImageOutput
            }
            
            
        })
        
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.sessionQueue.async(execute: {
            
            
            
            self.addObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", options: [.old , .new] , context: &SessionRunningAndDeviceAuthorizedContext)
            self.addObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", options:[.old , .new], context: &CapturingStillImageContext)
            self.addObserver(self, forKeyPath: "movieFileOutput.recording", options: [.old , .new], context: &RecordingContext)
            
            NotificationCenter.default.addObserver(self, selector: #selector(CameraViewController.subjectAreaDidChange(_:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.videoDeviceInput?.device)
            
            
            weak var weakSelf = self
            
            self.runtimeErrorHandlingObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureSessionRuntimeError, object: self.session, queue: nil, using: {
                (note: Notification?) in
                let strongSelf: CameraViewController = weakSelf!
                strongSelf.sessionQueue.async(execute: {
                    //                    strongSelf.session?.startRunning()
                    if let sess = strongSelf.session{
                        sess.startRunning()
                    }
                    //                    strongSelf.recordButton.title  = NSLocalizedString("Record", "Recording button record title")
                })
                
            })
            
            self.session?.startRunning()
            
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        self.sessionQueue.async(execute: {
            
            if let sess = self.session{
                sess.stopRunning()
                
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.videoDeviceInput?.device)
                NotificationCenter.default.removeObserver(self.runtimeErrorHandlingObserver!)
                
                self.removeObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", context: &SessionRunningAndDeviceAuthorizedContext)
                
                self.removeObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", context: &CapturingStillImageContext)
                self.removeObserver(self, forKeyPath: "movieFileOutput.recording", context: &RecordingContext)
                
                
            }
            
            
            
        })
        
        self.player?.pause()
        self.playerLayer?.removeFromSuperlayer()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        
        (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = AVCaptureVideoOrientation(rawValue: toInterfaceOrientation.rawValue)!
        
        
    }
    
    override var shouldAutorotate : Bool {
        return !self.lockInterfaceRotation
    }
    //    observeValueForKeyPath:ofObject:change:context:
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        
        
        if context == &CapturingStillImageContext{
            let isCapturingStillImage: Bool = (change![NSKeyValueChangeKey.newKey]! as AnyObject).boolValue
            if isCapturingStillImage {
                //                self.runStillImageCaptureAnimation()
            }
            
        }else if context  == &RecordingContext{
            let isRecording: Bool = (change![NSKeyValueChangeKey.newKey]! as AnyObject).boolValue
            
            DispatchQueue.main.async(execute: {
                
                if isRecording {
                    self.recordButton.titleLabel!.text = "Stop"
                    self.recordButton.isEnabled = true
                    //                    self.snapButton.enabled = false
                    self.cameraButton.isEnabled = false
                    
                }else{
                    //                    self.snapButton.enabled = true
                    
                    self.recordButton.titleLabel!.text = "Record"
                    self.recordButton.isEnabled = true
                    self.cameraButton.isEnabled = true
                    
                }
                
                
            })
            
            
        }
            
        else{
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        
    }
    
    
    // MARK: Selector
    func subjectAreaDidChange(_ notification: Notification){
        let devicePoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
        self.focusWithMode(AVCaptureFocusMode.continuousAutoFocus, exposureMode: AVCaptureExposureMode.continuousAutoExposure, point: devicePoint, monitorSubjectAreaChange: false)
    }
    
    // MARK:  Custom Function
    
    func focusWithMode(_ focusMode:AVCaptureFocusMode, exposureMode:AVCaptureExposureMode, point:CGPoint, monitorSubjectAreaChange:Bool){
        
        self.sessionQueue.async(execute: {
            let device: AVCaptureDevice! = self.videoDeviceInput!.device
            
            do {
                try device.lockForConfiguration()
                
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode){
                    device.focusMode = focusMode
                    device.focusPointOfInterest = point
                }
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode){
                    device.exposurePointOfInterest = point
                    device.exposureMode = exposureMode
                }
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
                
            }catch{
                print(error)
            }
            
            
            
            
        })
        
    }
    
    
    
    class func setFlashMode(_ flashMode: AVCaptureFlashMode, device: AVCaptureDevice){
        
        if device.hasFlash && device.isFlashModeSupported(flashMode) {
            var error: NSError? = nil
            do {
                try device.lockForConfiguration()
                device.flashMode = flashMode
                device.unlockForConfiguration()
                
            } catch let error1 as NSError {
                error = error1
                print(error)
            }
        }
        
    }
    
    func runStillImageCaptureAnimation(){
        DispatchQueue.main.async(execute: {
            self.previewView.layer.opacity = 0.0
            print("opacity 0")
            UIView.animate(withDuration: 0.25, animations: {
                self.previewView.layer.opacity = 1.0
                print("opacity 1")
            })
        })
    }
    
    class func deviceWithMediaType(_ mediaType: String, preferringPosition:AVCaptureDevicePosition)->AVCaptureDevice{
        
        var devices = AVCaptureDevice.devices(withMediaType: mediaType);
        var captureDevice: AVCaptureDevice = devices![0] as! AVCaptureDevice;
        
        for device in devices!{
            if (device as AnyObject).position == preferringPosition{
                captureDevice = device as! AVCaptureDevice
                break
            }
        }
        
        return captureDevice
        
        
    }
    
    func checkDeviceAuthorizationStatus(){
        let mediaType:String = AVMediaTypeVideo;
        
        AVCaptureDevice.requestAccess(forMediaType: mediaType, completionHandler: { (granted: Bool) in
            if granted{
                self.deviceAuthorized = true;
            }else{
                
                DispatchQueue.main.async(execute: {
                    let alert: UIAlertController = UIAlertController(
                        title: "AVCam",
                        message: "AVCam does not have permission to access camera",
                        preferredStyle: UIAlertControllerStyle.alert);
                    
                    let action: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {
                        (action2: UIAlertAction) in
                        exit(0);
                    } );
                    
                    alert.addAction(action);
                    
                    self.present(alert, animated: true, completion: nil);
                })
                
                self.deviceAuthorized = false;
            }
        })
        
    }
    
    
    // MARK: File Output Delegate
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        if(error != nil){
            print(error)
        }
        
        self.lockInterfaceRotation = false
        
        // Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
        
        //        let backgroundRecordId: UIBackgroundTaskIdentifier = self.backgroundRecordId
        //        self.backgroundRecordId = UIBackgroundTaskInvalid
        
        //        ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(outputFileURL, completionBlock: {
        //            (assetURL:NSURL!, error:NSError!) in
        //            if error != nil{
        //                print(error)
        //
        //            }
        //
        //            do {
        //                try NSFileManager.defaultManager().removeItemAtURL(outputFileURL)
        //            } catch _ {
        //            }
        //
        //            if backgroundRecordId != UIBackgroundTaskInvalid {
        //                UIApplication.sharedApplication().endBackgroundTask(backgroundRecordId)
        //            }
        //
        //        })
        
        self.playVideo(outputFileURL)
        
        
    }
    
    // MARK: Actions
    
    @IBAction func toggleMovieRecord(_ sender: AnyObject) {
        self.isVideo = true
        self.recordButton.isEnabled = true
        self.snapButton.isEnabled = false
        
        
        //takeScreenShot()
        
        self.sessionQueue.async(execute: {
            if !self.movieFileOutput!.isRecording{
                self.lockInterfaceRotation = true
                
                if UIDevice.current.isMultitaskingSupported {
                    self.backgroundRecordId = UIApplication.shared.beginBackgroundTask(expirationHandler: {})
                    
                }
                
                
                self.movieFileOutput!.connection(withMediaType: AVMediaTypeVideo).videoOrientation =
                    AVCaptureVideoOrientation(rawValue: (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation.rawValue )!
                
                // Turning OFF flash for video recording
                CameraViewController.setFlashMode(AVCaptureFlashMode.off, device: self.videoDeviceInput!.device)
                
                let outputFilePath  =
                    URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("movie.mov")
                
                if(self.videoDeviceInput!.device.position == AVCaptureDevicePosition.front){
                    self.movieFileOutput!.connection(withMediaType: AVMediaTypeVideo).isVideoMirrored = true
                }
                else{
                    self.movieFileOutput!.connection(withMediaType: AVMediaTypeVideo).isVideoMirrored = false
                }
                //NSTemporaryDirectory().stringByAppendingPathComponent( "movie".stringByAppendingPathExtension("mov")!)
                self.movieFileOutput!.maxRecordedDuration = CMTime(seconds: 10.0, preferredTimescale: 60)
                //Max file size is 100mb
                self.movieFileOutput!.maxRecordedFileSize = 104857600
                self.movieFileOutput!.startRecording( toOutputFileURL: outputFilePath, recordingDelegate: self)
                self.takeScreenShot()
                
            }else{
                self.movieFileOutput!.stopRecording()
                
            }
        })
        
    }
    
    func playVideo(_ outputFileURL: URL){
        
        self.mediaPreviewView.isHidden = false
        self.myVideoView.isHidden = false
        self.myImageView.isHidden = true
        self.isVideo = true
        self.videoFileURL = outputFileURL
        self.player = AVPlayer(url: outputFileURL)
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.myVideoView.layer.addSublayer(self.playerLayer!)
        
        self.playerLayer!.frame = self.view.bounds
        
        self.player!.play()
        // Add notification block
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player!.currentItem, queue: nil)
        { notification in
            let t1 = CMTimeMake(0, 100);
            self.player!.seek(to: t1)
            self.player!.play()
        }
        
    }
    
    
    
    func takeScreenShot(){
        self.sessionQueue.async(execute: {
            // Update the orientation on the still image output video connection before capturing.
            
            let videoOrientation =  (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation
            
            
            self.stillImageOutput!.connection(withMediaType: AVMediaTypeVideo).videoOrientation = videoOrientation
            // Flash set to Auto for Still Capture
            CameraViewController.setFlashMode(AVCaptureFlashMode.auto, device: self.videoDeviceInput!.device)
            
            
            
            self.stillImageOutput!.captureStillImageAsynchronously(from: self.stillImageOutput!.connection(withMediaType: AVMediaTypeVideo), completionHandler: {
                (imageDataSampleBuffer: CMSampleBuffer!, error: NSError!) in
                
                if error == nil {
                    let data:Data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    var image:UIImage = UIImage( data: data)!
                    
                    //Flip the picture if device is facing front
                    if(self.videoDeviceInput!.device.position == AVCaptureDevicePosition.front){
                        let flippedImage = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation:.leftMirrored)
                        image = flippedImage
                    }
                    self.myImageView.image = image
                    
                    
                    
                }else{
                    //print("Did not capture still image")
                    print(error)
                }
                
                
            })
            
            
        })
        
    }
    
    
    @IBAction func snapStillImage(_ sender: AnyObject) {
        
        
        isVideo = false
        self.myVideoView.isHidden = true
        self.mediaPreviewView.isHidden = false
        self.myImageView.isHidden = false
        self.sessionQueue.async(execute: {
            // Update the orientation on the still image output video connection before capturing.
            
            let videoOrientation =  (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation
            
            
            self.stillImageOutput!.connection(withMediaType: AVMediaTypeVideo).videoOrientation = videoOrientation
            // Flash set to Auto for Still Capture
            CameraViewController.setFlashMode(AVCaptureFlashMode.auto, device: self.videoDeviceInput!.device)
            
            
            
            self.stillImageOutput!.captureStillImageAsynchronously(from: self.stillImageOutput!.connection(withMediaType: AVMediaTypeVideo), completionHandler: {
                (imageDataSampleBuffer: CMSampleBuffer!, error: NSError!) in
                
                if error == nil {
                    let data:Data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    var image:UIImage = UIImage( data: data)!
                    
                    //print("save to album")
                    
                    //Flip the picture if device is facing front
                    if(self.videoDeviceInput!.device.position == AVCaptureDevicePosition.front){
                        let flippedImage = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation:.leftMirrored)
                        image = flippedImage
                    }
                    self.myImageView.image = image
                    
                    
                    
                }else{
                    //print("Did not capture still image")
                    print(error)
                }
                
                
            })
            
            
        })
    }
    @IBAction func changeCamera(_ sender: AnyObject) {
        
        
        
        print("change camera")
        
        self.cameraButton.isEnabled = false
        self.recordButton.isEnabled = false
        self.snapButton.isEnabled = false
        
        self.sessionQueue.async(execute: {
            
            let currentVideoDevice:AVCaptureDevice = self.videoDeviceInput!.device
            let currentPosition: AVCaptureDevicePosition = currentVideoDevice.position
            var preferredPosition: AVCaptureDevicePosition = AVCaptureDevicePosition.unspecified
            
            
            
            switch currentPosition{
            case AVCaptureDevicePosition.front:
                preferredPosition = AVCaptureDevicePosition.back
            case AVCaptureDevicePosition.back:
                preferredPosition = AVCaptureDevicePosition.front
            case AVCaptureDevicePosition.unspecified:
                preferredPosition = AVCaptureDevicePosition.back
                
            }
            
            
            
            let device:AVCaptureDevice = CameraViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: preferredPosition)
            
            var videoDeviceInput: AVCaptureDeviceInput?
            
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: device)
            } catch _ as NSError {
                videoDeviceInput = nil
            } catch {
                fatalError()
            }
            
            self.session!.beginConfiguration()
            
            self.session!.removeInput(self.videoDeviceInput)
            
            if self.session!.canAddInput(videoDeviceInput){
                
                NotificationCenter.default.removeObserver(self, name:NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object:currentVideoDevice)
                
                CameraViewController.setFlashMode(AVCaptureFlashMode.auto, device: device)
                
                NotificationCenter.default.addObserver(self, selector: #selector(CameraViewController.subjectAreaDidChange(_:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: device)
                
                self.session!.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
            }else{
                self.session!.addInput(self.videoDeviceInput)
            }
            
            self.session!.commitConfiguration()
            
            
            
            DispatchQueue.main.async(execute: {
                self.recordButton.isEnabled = true
                self.snapButton.isEnabled = true
                self.cameraButton.isEnabled = true
            })
            
        })
        
    }
    
    
    @IBAction func closeMediaPreviewView(_ sender: AnyObject) {
        self.mediaPreviewView.isHidden = true
        self.myImageView.image = UIImage.init()
        self.snapButton.isEnabled = true
        self.recordButton.isEnabled = true
        self.player?.pause()
    }
    
    @IBAction func submitMedia(_ sender: AnyObject) {
        
        self.mediaPreviewView.isHidden = true
        self.previewView.isHidden = true
        self.myImageView.isHidden = true
        self.performSegue(withIdentifier: "cameraToNewPost", sender: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "cameraToNewPost" {
            if let destination = segue.destination as? NewPostViewController {
                if(self.isVideo == false){
                    destination.myImage = myImageView.image!
                    destination.isVideo = false
                }
                else{
                    destination.myImage = myImageView.image!
                    destination.myVideo = videoFileURL!
                    destination.isVideo = true
                    
                }
            }
        }
    }
    
    
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    
    
    
    
}



