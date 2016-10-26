//
//  NewPostViewController.swift
//  jre
//
//  Created by Joey Van Gundy on 3/9/16.
//  Copyright © 2016 Joe Van Gundy. All rights reserved.
//

import UIKit
import Firebase
import GoogleMaps
import AWSS3
import AVKit
import AVFoundation

class NewPostViewController: UIViewController,UITextFieldDelegate{
    let ref = Firebase(url: "https://jrecse.firebaseio.com")
    var placePicker: GMSPlacePicker!
    var uploadCompletionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
    var uploadFileURL: URL?
    var postPreviewImageURL: URL?
    var postPreviewImageName: String?
    var myImage = UIImage.init()
    var myVideo = URL.init()
    var isVideo = false
    let S3BucketName: String = "jrecse"
    var imageExt = ".png"
    var videoExt = ".mov"
    var S3UploadKeyName: String = (ProcessInfo.processInfo.globallyUniqueString)
    var postPlaceName = ""
    var postPlaceID = ""
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    @IBOutlet weak var myImageView: UIImageView!
    
    @IBOutlet weak var userDescriptionTextField: UITextField!
    @IBOutlet weak var placeTitleLabel: UILabel!
    @IBOutlet weak var userCoordinatesLabel: UILabel!
    @IBOutlet weak var placeNameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var myVideoView: UIView!
    
    @IBOutlet weak var userSubmitButton: UIButton!
    @IBOutlet weak var mediaContainerView: UIView!
    @IBOutlet weak var containerView: UIView!
    
    
    
    
    
    @IBAction func userSubmitButton(_ sender: AnyObject) {
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            var mediaExtension = ""
            if(isVideo){
                uploadVideo()
                self.postPreviewImageName = (ProcessInfo.processInfo.globallyUniqueString)
                self.postPreviewImageURL = URL(string: "http://s3.amazonaws.com/\(self.S3BucketName)/\(self.S3UploadKeyName)")!
                
                uploadImageWithVideo()
                mediaExtension = videoExt
                
                
                let postRef = ref.childByAppendingPath("posts")
                print(uploadFileURL?.path)
                let newPost = [
                    "username": ref.authData.uid,
                    "post_place_name": self.postPlaceName,
                    "post_placeID": self.postPlaceID,
                    "post_longitude": locationManager.location!.coordinate.longitude,
                    "post_latitude": locationManager.location!.coordinate.latitude,
                    "post_description": self.userDescriptionTextField.text! as String,
                    "post_up_votes": 0,
                    "post_down_votes": 0,
                    "post_flag_count": 0,
                    "post_creation_date": getCurrentDate(),
                    "post_user_voted": "",
                    "post_user_reported": "",
                    "post_file_name": S3UploadKeyName,
                    "post_preview_file_name": self.postPreviewImageName! as String,
                    "post_preview_url": self.postPreviewImageURL!.absoluteString + imageExt,
                    "post_media_url": self.uploadFileURL!.absoluteString+mediaExtension
                ]
                
                
                
                let newPostRef = postRef.childByAutoId()
                newPostRef.setValue(newPost)
                
            }
            else{
                self.postPreviewImageName = S3UploadKeyName
                uploadImage()
                
                let postRef = ref.childByAppendingPath("posts")
                print(uploadFileURL?.path)
                let newPost = [
                    "username": ref.authData.uid,
                    "post_place_name": self.postPlaceName,
                    "post_placeID": self.postPlaceID,
                    "post_longitude": locationManager.location!.coordinate.longitude,
                    "post_latitude": locationManager.location!.coordinate.latitude,
                    "post_description": self.userDescriptionTextField.text! as String,
                    "post_up_votes": 0,
                    "post_down_votes": 0,
                    "post_flag_count": 0,
                    "post_creation_date": getCurrentDate(),
                    "post_user_voted": "",
                    "post_user_reported": "",
                    "post_file_name": S3UploadKeyName,
                    "post_preview_file_name": S3UploadKeyName,
                    "post_preview_url": self.uploadFileURL!.absoluteString+".png",
                    "post_media_url": self.uploadFileURL!.absoluteString+".png"
                ]
                
                
                
                let newPostRef = postRef.childByAutoId()
                newPostRef.setValue(newPost)
            }
            self.performSegue(withIdentifier: "newPostToMap", sender: nil)
        }}
    
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.userDescriptionTextField.delegate = self;
        
        self.userSubmitButton.isHidden = true
        if CLLocationManager.locationServicesEnabled() == false {
            let alertController = UIAlertController(title: "GPS Failure", message:
                "Please check your GPS connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
        
        
        
        if(isVideo){
            self.myImageView.isHidden = true
            playVideo()
        }else{
            self.myImageView.isHidden = false

            }
            
        
        self.userDescriptionTextField.text = ""
        
        self.uploadFileURL = URL(string: "http://s3.amazonaws.com/\(self.S3BucketName)/\(self.S3UploadKeyName)")!
        
        myImageView.image = myImage
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        // 2
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = self.view.bounds
        // 3
        mediaContainerView.addSubview(blurView)
        
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func getCurrentDate() ->Double{
        let timestamp = Date().timeIntervalSince1970
        return timestamp
        
    }
    
    func uploadVideo(){
        let videoName = URL(fileURLWithPath: NSTemporaryDirectory() + S3UploadKeyName + videoExt).lastPathComponent
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
        
        // getting local path
        let localPath = (documentDirectory as NSString).appendingPathComponent(videoName)
        
        
        //getting actual image
        var videoData = try? Data(contentsOf: myVideo)
        
        //let videoData = NSData(contentsOfFile: localPath)!
        let videoURL = URL(fileURLWithPath: localPath)
        
        
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.uploadProgress = {(task: AWSS3TransferUtilityTask, bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) in
            dispatch_async(dispatch_get_main_queue(), {
                let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                // self.statusLabel.text = "Uploading..."
                NSLog("Progress is: %f",progress)
            })
        }
        
        uploadCompletionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if ((error) != nil){
                    NSLog("Failed with error")
                    NSLog("Error: %@",error!);
                    //    self.statusLabel.text = "Failed"
                }
                else{
                    //    self.statusLabel.text = "Success"
                    NSLog("Sucess")
                }
            })
        }
        
        let transferUtility = AWSS3TransferUtility.defaultS3TransferUtility()
        
        transferUtility?.uploadFile(myVideo, bucket: S3BucketName, key: S3UploadKeyName+videoExt, contentType: "video/mov", expression: expression, completionHander: uploadCompletionHandler).continueWithBlock { (task) -> AnyObject! in
            if let error = task.error {
                NSLog("Error: %@",error.localizedDescription);
                //  self.statusLabel.text = "Failed"
            }
            if let exception = task.exception {
                NSLog("Exception: %@",exception.description);
                //   self.statusLabel.text = "Failed"
            }
            if let _ = task.result {
                // self.statusLabel.text = "Generating Upload File"
                NSLog("Upload Starting!")
                // Do something with uploadTask.
            }
            
            return nil;
        }
        
    }
    
    func uploadImage(){
        
        let imageName = URL(fileURLWithPath: NSTemporaryDirectory() + S3UploadKeyName + imageExt).lastPathComponent
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
        
        
        // getting local path
        let localPath = (documentDirectory as NSString).appendingPathComponent(imageName)
        
        //getting actual image
        var image = myImageView.image
        let data = UIImageJPEGRepresentation(image!, 0.5)
        try? data!.write(to: URL(fileURLWithPath: localPath), options: [.atomic])
        
        let imageData = try! Data(contentsOf: URL(fileURLWithPath: localPath))
        let photoURL = URL(fileURLWithPath: localPath)
        
        
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.uploadProgress = {(task: AWSS3TransferUtilityTask, bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) in
            dispatch_async(dispatch_get_main_queue(), {
                let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                // self.statusLabel.text = "Uploading..."
                NSLog("Progress is: %f",progress)
            })
        }
        
        uploadCompletionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if ((error) != nil){
                    NSLog("Failed with error")
                    NSLog("Error: %@",error!);
                    //    self.statusLabel.text = "Failed"
                }
                else{
                    //    self.statusLabel.text = "Success"
                    NSLog("Sucess")
                }
            })
        }
        
        let transferUtility = AWSS3TransferUtility.defaultS3TransferUtility()
        
        transferUtility?.uploadFile(photoURL, bucket: S3BucketName, key: S3UploadKeyName+imageExt, contentType: "image/png", expression: expression, completionHander: uploadCompletionHandler).continueWithBlock { (task) -> AnyObject! in
            if let error = task.error {
                NSLog("Error: %@",error.localizedDescription);
                //  self.statusLabel.text = "Failed"
            }
            if let exception = task.exception {
                NSLog("Exception: %@",exception.description);
                //   self.statusLabel.text = "Failed"
            }
            if let _ = task.result {
                // self.statusLabel.text = "Generating Upload File"
                NSLog("Upload Starting!")
                // Do something with uploadTask.
                print(photoURL)
            }
            
            return nil;
        }
        
    }
    
    
    
    func uploadImageWithVideo(){
        
        let imageName = URL(fileURLWithPath: NSTemporaryDirectory() + postPreviewImageName! + imageExt).lastPathComponent
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
        
        
        // getting local path
        let localPath = (documentDirectory as NSString).appendingPathComponent(imageName)
        
        //getting actual image
        var image = myImageView.image
        let data = UIImageJPEGRepresentation(image!, 0.5)
        try? data!.write(to: URL(fileURLWithPath: localPath), options: [.atomic])
        
        let imageData = try! Data(contentsOf: URL(fileURLWithPath: localPath))
        let photoURL = URL(fileURLWithPath: localPath)
        
        
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.uploadProgress = {(task: AWSS3TransferUtilityTask, bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) in
            dispatch_async(dispatch_get_main_queue(), {
                let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                // self.statusLabel.text = "Uploading..."
                NSLog("Progress is: %f",progress)
            })
        }
        
        uploadCompletionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if ((error) != nil){
                    NSLog("Failed with error")
                    NSLog("Error: %@",error!);
                    //    self.statusLabel.text = "Failed"
                }
                else{
                    //    self.statusLabel.text = "Success"
                    NSLog("Sucess")
                }
            })
        }
        
        let transferUtility = AWSS3TransferUtility.defaultS3TransferUtility()
        
        transferUtility?.uploadFile(photoURL, bucket: S3BucketName, key: S3UploadKeyName+imageExt, contentType: "image/png", expression: expression, completionHander: uploadCompletionHandler).continueWithBlock { (task) -> AnyObject! in
            if let error = task.error {
                NSLog("Error: %@",error.localizedDescription);
                //  self.statusLabel.text = "Failed"
            }
            if let exception = task.exception {
                NSLog("Exception: %@",exception.description);
                //   self.statusLabel.text = "Failed"
            }
            if let _ = task.result {
                // self.statusLabel.text = "Generating Upload File"
                NSLog("Upload Starting!")
                // Do something with uploadTask.
                print(photoURL)
            }
            
            return nil;
        }
        
    }
    
    
    
    
    
    
    
    
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    func playVideo(){
        
        self.myVideoView.isHidden = false
        
        self.player = AVPlayer(url: myVideo)
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLayer!.frame = self.view.bounds
        self.playerLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.myVideoView.layer.addSublayer(self.playerLayer!)
        self.player!.play()
        // Add notification block
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player!.currentItem, queue: nil)
        { notification in
            let t1 = CMTimeMake(0, 100);
            self.player!.seek(to: t1)
            self.player!.play()
        }
    }
    
    @IBAction func cancelPostButton(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "newPostToCamera", sender: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.player?.pause()
        self.playerLayer?.removeFromSuperlayer()
    }
    
    
    
    
}

extension NewPostViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    // 6
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationManager.stopUpdatingLocation()
        }
    }
    
    @IBAction func googleNearbyButton(_ sender: AnyObject) {
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            let center = CLLocationCoordinate2DMake((locationManager.location?.coordinate.latitude)!
                ,(locationManager.location?.coordinate.longitude)!
            )
            let northEast = CLLocationCoordinate2DMake(center.latitude + 0.001, center.longitude + 0.001)
            let southWest = CLLocationCoordinate2DMake(center.latitude - 0.001, center.longitude - 0.001)
            let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
            let config = GMSPlacePickerConfig(viewport: viewport)
            placePicker = GMSPlacePicker(config: config)
            
            
            placePicker?.pickPlace(callback: { (place: GMSPlace?, error: NSError?) -> Void in
                if let error = error {
                    print("Pick Place error: \(error.localizedDescription)")
                    return
                }
                
                if let place = place {
                    
                    if(place.placeID != nil){
                        self.postPlaceName = place.name
                        self.postPlaceID = place.placeID
                        self.placeTitleLabel.text = self.postPlaceName
                        //                    self.restaurant = Restaurant(
                        //                        name: place.name,
                        //                        phone: place.phoneNumber,
                        //                        longitude: (self.locationManager.location?.coordinate.longitude)!,
                        //                        latitude: (self.locationManager.location?.coordinate.latitude)!
                        //                    )
                        
                        self.userSubmitButton.isHidden = false
                    }
                } else {
                    print("No place selected")
                }
            })
        }
    }
}
