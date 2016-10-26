//
//  MediaPlayerViewController.swift
//  jre
//
//  Created by Edillower Wang on 3/29/16.
//  Copyright © 2016 Joe Van Gundy. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import AWSS3
import GoogleMaps

class MediaPlayerViewController: UIViewController {
    
    var placeID = ""
    var placeName = ""
    var isVideo = false
    var mediaURL = ""
    var mediaFileName = ""
    var markerCoordinates = CLLocationCoordinate2D.init()
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    @IBOutlet weak var mediaView: UIView!
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var myVideoView: UIView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mediaView.isHidden = true
        myVideoView.isHidden = true
        myImageView.isHidden = true
        
        if(URL(string: mediaURL)!.pathExtension == "png"){
            
            isVideo = false
            mediaFileName = mediaFileName+".png"
            displayImage()
            
        }
        else{
            isVideo = true
            mediaFileName = mediaFileName + ".mov"
            downloadVideo()
        }
        
        // Do any additional setup after loading the view.
    }
    
    func displayImage(){
        self.mediaView.isHidden = false
        self.myImageView.isHidden = false
        self.isVideo = false
        
        let url = URL(string: self.mediaURL)
        let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check
        
        
        self.myImageView.image = UIImage(data: data!)
        //        downloadImage()
        
    }
    func playVideo(_ videoURL: URL){
        
        
        self.mediaView.isHidden = false
        self.myVideoView.isHidden = false
        self.isVideo = true
        
        
        self.player = AVPlayer(url: videoURL)
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLayer!.frame = self.myVideoView.bounds
        self.playerLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.myVideoView.layer.addSublayer(playerLayer!)
        self.player!.play()
        
        
        // Add notification block
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player!.currentItem, queue: nil)
        { notification in
            let t1 = CMTimeMake(0, 100);
            self.player!.seek(to: t1)
            self.player!.play()
        }
    }
    
    
    func downloadVideo(){
        
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
            
            let S3BucketName: String = "jrecse"
            print(self.mediaFileName)
            let S3DownloadKeyName: String = self.mediaFileName
            print("1")
            let expression = AWSS3TransferUtilityDownloadExpression()
            expression.downloadProgress = {(task: AWSS3TransferUtilityTask, bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) in
                dispatch_async(dispatch_get_main_queue(), {
                    let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                    //   self.statusLabel.text = "Downloading..."
                    NSLog("Progress is: %f",progress)
                })
            }
            print("2")
            completionHandler = { (task, location, data, error) -> Void in
                DispatchQueue.main.async(execute: {
                    if ((error) != nil){
                        NSLog("Failed with error")
                        NSLog("Error: %@",error!);
                        //   self.statusLabel.text = "Failed"
                    }
                    else{
                        //    self.statusLabel.text = "Success"
                        NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                        let identifier = NSProcessInfo.processInfo().globallyUniqueString
                        let fileName = String(format: "%@_%@", NSProcessInfo.processInfo().globallyUniqueString, "testOne.mov")
                        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(fileName)
                        let videoData: NSData = data!
                        do {
                            try data!.writeToURL(fileURL, options: .AtomicWrite)
                        } catch {
                            print("Errrrror")
                        }
                        self.playVideo(fileURL)
                        
                        
                    }
                })
            }
            print("3")
            let transferUtility = AWSS3TransferUtility.defaultS3TransferUtility()
            
            print("5")
            transferUtility?.downloadToURL(nil, bucket: S3BucketName, key: S3DownloadKeyName, expression: expression, completionHander: completionHandler).continueWithBlock { (task) -> AnyObject! in
                print("6")
                if let error = task.error {
                    NSLog("Error: %@",error.localizedDescription);
                    //  self.statusLabel.text = "Failed"
                }
                if let exception = task.exception {
                    NSLog("Exception: %@",exception.description);
                    //  self.statusLabel.text = "Failed"
                }
                if let _ = task.result {
                    //    self.statusLabel.text = "Starting Download"
                    NSLog("Download Starting!")
                    // Do something with uploadTask.
                }
                return nil;
            }
        }
        
    }
    
    
    func downloadImage(){
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
            
            let S3BucketName: String = "jrecse"
            let S3DownloadKeyName: String = self.mediaFileName
            print("1")
            let expression = AWSS3TransferUtilityDownloadExpression()
            expression.downloadProgress = {(task: AWSS3TransferUtilityTask, bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) in
                dispatch_async(dispatch_get_main_queue(), {
                    let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                    //   self.statusLabel.text = "Downloading..."
                    NSLog("Progress is: %f",progress)
                })
            }
            print("2")
            completionHandler = { (task, location, data, error) -> Void in
                DispatchQueue.main.async(execute: {
                    if ((error) != nil){
                        NSLog("Failed with error")
                        NSLog("Error: %@",error!);
                        //   self.statusLabel.text = "Failed"
                    }
                    else{
                        //    self.statusLabel.text = "Success"
                        self.myImageView.image = UIImage(data: data!)
                    }
                })
            }
            print("3")
            let transferUtility = AWSS3TransferUtility.defaultS3TransferUtility()
            
            print("5")
            transferUtility?.downloadToURL(nil, bucket: S3BucketName, key: S3DownloadKeyName, expression: expression, completionHander: completionHandler).continueWithBlock { (task) -> AnyObject! in
                print("6")
                if let error = task.error {
                    NSLog("Error: %@",error.localizedDescription);
                    //  self.statusLabel.text = "Failed"
                }
                if let exception = task.exception {
                    NSLog("Exception: %@",exception.description);
                    //  self.statusLabel.text = "Failed"
                }
                if let _ = task.result {
                    //    self.statusLabel.text = "Starting Download"
                    NSLog("Download Starting!")
                    // Do something with uploadTask.
                }
                return nil;
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mediaPlayerToTableView" {
            if let destination = segue.destination as? PlaceTableViewController {
                
                destination.placeID = self.placeID
                destination.placeTitile = self.placeName
                destination.markerCoordinates = self.markerCoordinates
                
                
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    
    @IBAction func goBackButton(_ sender: AnyObject) {
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            self.performSegue(withIdentifier: "mediaPlayerToTableView", sender: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField!) -> Bool {   //delegate method
        textField.resignFirstResponder()
        return true
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        self.player?.pause()
        self.playerLayer?.removeFromSuperlayer()
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
