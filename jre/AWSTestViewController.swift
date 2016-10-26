//
//  AWSTestViewController.swift
//  jre
//
//  Created by Joey Van Gundy on 3/28/16.
//  Copyright © 2016 Joe Van Gundy. All rights reserved.
//

import UIKit
import AWSS3
import AWSCore


class AWSTestViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    //handles upload
    var uploadCompletionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
    var uploadFileURL: URL?
    override func viewDidLoad() {
        super.viewDidLoad()
        //setting progress bar to 0
        self.progressView.progress = 0.0

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func uploadImage(){
        //defining bucket and upload file name
        let imageName = "YouWin.png"
        
        
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
        
        // getting local path
        let localPath = (documentDirectory as NSString).appendingPathComponent(imageName)
        
        
        //getting actual image
        var image = UIImage(named: imageName)
        let data = UIImagePNGRepresentation(image!)
        try? data!.write(to: URL(fileURLWithPath: localPath), options: [.atomic])
        
        let imageData = try! Data(contentsOf: URL(fileURLWithPath: localPath))
        let photoURL = URL(fileURLWithPath: localPath)
        
        let S3BucketName: String = "jrecse"
        let S3UploadKeyName: String = "test_libarayUpload.jpg"
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.uploadProgress = {(task: AWSS3TransferUtilityTask, bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) in
            dispatch_async(dispatch_get_main_queue(), {
                let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                self.progressView.progress = progress
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
                else if(self.progressView.progress != 1.0) {
                    //    self.statusLabel.text = "Failed"
                    NSLog("Error: Failed - Likely due to invalid region / filename")
                }
                else{
                    //    self.statusLabel.text = "Success"
                    NSLog("Sucess")
                }
            })
        }
        
        let transferUtility = AWSS3TransferUtility.defaultS3TransferUtility()
        
        transferUtility?.uploadFile(photoURL, bucket: S3BucketName, key: S3UploadKeyName, contentType: "image/png", expression: expression, completionHander: uploadCompletionHandler).continueWithBlock { (task) -> AnyObject! in
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
        
        //end if photo library upload
        self.dismiss(animated: true, completion: nil);
    
    }

    func downloadImage(){
        
        var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
        
        let S3BucketName: String = "jrecse"
        let S3DownloadKeyName: String = "camera-icon.png"
        print("1")
        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.downloadProgress = {(task: AWSS3TransferUtilityTask, bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) in
            dispatch_async(dispatch_get_main_queue(), {
                let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                self.progressView.progress = progress
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
                else if(self.progressView.progress != 1.0) {
                    //    self.statusLabel.text = "Failed"
                    NSLog("Error: Failed - Likely due to invalid region / filename")
                }
                else{
                    //    self.statusLabel.text = "Success"
                    self.imageView.image = UIImage(data: data!)
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

    @IBAction func downloadButton(_ sender: AnyObject) {
        uploadImage()
    }
}
    


