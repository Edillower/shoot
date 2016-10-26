//
//  PlaceTableViewController.swift
//  jre
//
//  Created by Edillower Wang on 3/26/16.
//  Copyright © 2016 Joe Van Gundy. All rights reserved.
//

import UIKit
import Firebase
import AWSS3
import GoogleMaps

class PlaceTableViewController: UITableViewController {
    
    
    
    let ref = Firebase(url: "https://jrecse.firebaseio.com/posts")
    let userRef = Firebase(url: "https://jrecse.firebaseio.com/users")
    
    var placeID = ""
    var postFileName = ""
    var placeTitile = ""
    var markerCoordinates = CLLocationCoordinate2D.init()
    
    var mediaURL = ""
    var imageData: Data?
    var posts=[FDataSnapshot]()
    var likeCountLocalRecord=[Int]()
    var unlikeCountLocalRecord=[Int]()
    var buttonEnabled=[Bool]()
    var reportEnabled=[Bool]()
    var flag=true
    
    
    
    @IBOutlet var naviBar: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.naviBar.title=self.placeTitile
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            ref.queryOrderedByChild("post_placeID").queryEqualToValue(placeID)  //TODO: Add place key and target value
                .observeSingleEventOfType(.Value, withBlock: { snapshot in
                    for child in snapshot.children.allObjects as! [FDataSnapshot]{
                        if((child.value["post_flag_count"] as! Int)<3){
                            self.posts.append(child)
                            self.likeCountLocalRecord.append(child.value["post_up_votes"] as! Int)
                            self.unlikeCountLocalRecord.append(child.value["post_down_votes"] as! Int)
                            if(self.userRef.authData != nil){
                                let userID = String(self.userRef.authData)
                                let voteRecord = child.value["post_user_voted"] as! String
                                if (voteRecord.rangeOfString(userID) != nil){
                                    self.buttonEnabled.append(false)
                                }else{
                                    self.buttonEnabled.append(true)
                                }
                            }else{
                                self.buttonEnabled.append(true)
                            }
                            
                            if(self.userRef.authData != nil){
                                let userID = String(self.userRef.authData)
                                let reportRecord = child.value["post_user_reported"] as! String
                                if (reportRecord.rangeOfString(userID) != nil){
                                    self.reportEnabled.append(false)
                                }else{
                                    self.reportEnabled.append(true)
                                }
                            }else{
                                self.reportEnabled.append(true)
                            }
                        }
                    }
                    self.tableView.reloadData()
                })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.posts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let myCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! cell
        
        
        let post_description = self.posts[indexPath.row].value["post_description"] as! String
        let post_creation_date = self.posts[indexPath.row].value["post_creation_date"] as! Double
        let likeCount=self.likeCountLocalRecord[(indexPath as NSIndexPath).row]
        let unlikeCount=self.unlikeCountLocalRecord[(indexPath as NSIndexPath).row]
        let post_preview_url = self.posts[indexPath.row].value["post_preview_url"] as! String
        
        
        
        //        downloadImage(post_preview_file_name)
        
        
        let url = URL(string: post_preview_url)
        let data = Data(contentsOfURL: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check
        
        
        myCell.VideoPreview.image = UIImage(data: data!)
        
        
        myCell.VideoDescription.text = post_description
        
        let date = Date(timeIntervalSince1970: post_creation_date)
        
        myCell.VideoInfo.text = "Posted at: " + String(date)
        
        myCell.VideoUpVotes.text = String(likeCount)
        
        myCell.VideoDownVotes.text = String(unlikeCount)
        
        myCell.upVoteButton.isEnabled=self.buttonEnabled[(indexPath as NSIndexPath).row]
        
        myCell.upVoteButton.tag=(indexPath as NSIndexPath).row
        
        myCell.upVoteButton.addTarget(self, action: #selector(PlaceTableViewController.upVoteAction(_:)), for: .touchUpInside)
        
        myCell.downVoteButton.isEnabled=self.buttonEnabled[(indexPath as NSIndexPath).row]
        
        myCell.downVoteButton.tag=(indexPath as NSIndexPath).row
        
        myCell.downVoteButton.addTarget(self, action: #selector(PlaceTableViewController.downVoteAction(_:)), for: .touchUpInside)
        
        return myCell
    }
    
    
    
    func downloadImage(_ previewFileName: String){
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            
            var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
            let S3BucketName: String = "jrecse"
            let S3DownloadKeyName: String = previewFileName
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
                        NSLog("Error: %@",error!)
                        //   self.statusLabel.text = "Failed"
                    }
                    else{
                        //    self.statusLabel.text = "Success"
                        print("Here is the data!")
                        print(data!)
                        self.imageData = data!
                        print(self.imageData)
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
            }}
    }
    
    
    
    @IBAction func upVoteAction(_ sender: UIButton){
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            if (userRef.authData != nil) {
                // user authenticated
                self.buttonEnabled[sender.tag]=false
                let likeCount=self.likeCountLocalRecord[sender.tag] + 1
                self.likeCountLocalRecord[sender.tag]=likeCount
                self.tableView.reloadData()
                
                let childName = self.posts[sender.tag].key
                let hopperRef = self.ref.childByAppendingPath(childName)
                let update = ["post_up_votes": likeCount]
                hopperRef.updateChildValues(update)
                
                var votedUser = self.posts[sender.tag].value["post_user_voted"] as! String
                votedUser.appendContentsOf(String(userRef.authData))
                let update2 = ["post_user_voted": votedUser]
                hopperRef.updateChildValues(update2)
            } else {
                // No user is signed in
                self.performSegue(withIdentifier: "gotoLoginView", sender: nil)
            }}
        
    }
    
    
    @IBAction func downVoteAction(_ sender: UIButton){
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            if (userRef.authData != nil) {
                // user authenticated
                self.buttonEnabled[sender.tag]=false
                let unlikeCount=self.unlikeCountLocalRecord[sender.tag] + 1
                self.unlikeCountLocalRecord[sender.tag]=unlikeCount
                self.tableView.reloadData()
                
                let childName = self.posts[sender.tag].key
                let hopperRef = self.ref.childByAppendingPath(childName)
                let update = ["post_down_votes": unlikeCount]
                hopperRef.updateChildValues(update)
                
                var votedUser = self.posts[sender.tag].value["post_user_voted"] as! String
                votedUser.appendContentsOf(String(userRef.authData))
                let update2 = ["post_user_voted": votedUser]
                hopperRef.updateChildValues(update2)
            }else{
                self.performSegue(withIdentifier: "gotoLoginView", sender: nil)
            }}
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tableViewToMediaPlayerView" {
            if let destination = segue.destination as? MediaPlayerViewController {
                
                destination.placeID = self.placeID
                destination.placeName = self.placeTitile
                destination.mediaURL = self.mediaURL
                destination.mediaFileName = self.postFileName
                destination.markerCoordinates = self.markerCoordinates
                
            }
        }
        if segue.identifier == "tableViewToMapView" {
            if let destination = segue.destination as? MapViewController {
                destination.markerCoordinates = self.markerCoordinates
                destination.comeback = true
                
            }
        }
    }
    
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            tableView.deselectRow(at: indexPath, animated: true)
            print(self.posts)
            print((indexPath as NSIndexPath).row)
            let mediaFileName = self.posts[indexPath.row].value["post_file_name"] as! String
            let mediaURLString = self.posts[indexPath.row].value["post_media_url"] as! String
            self.mediaURL = mediaURLString
            self.postFileName = mediaFileName
            self.performSegue(withIdentifier: "tableViewToMediaPlayerView", sender: nil)
        }
    }
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let reportAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Report Abuse", handler:{action, indexpath in
            
            if Reachability.isConnectedToNetwork() == false {
                let alertController = UIAlertController(title: "Network Failure", message:
                    "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }else{
                
                if (self.userRef.authData != nil) {
                    
                    
                    self.tableView.setEditing(false, animated: false)
                    
                    
                    if (self.reportEnabled[(indexPath as NSIndexPath).row]){
                        let alertController = UIAlertController(title: "Thanks!", message:
                            "Your report is submitted.", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                        
                        self.present(alertController, animated: true, completion: nil)
                        
                        
                        var reportCount = self.posts[indexPath.row].value["post_flag_count"] as! Int
                        let childName = self.posts[indexPath.row].key
                        
                        let hopperRef = self.ref.childByAppendingPath(childName)
                        reportCount = reportCount + 1
                        let update = ["post_flag_count": reportCount]
                        hopperRef.updateChildValues(update)
                        
                        var reportedUser = self.posts[indexPath.row].value["post_user_voted"] as! String
                        reportedUser.appendContentsOf(String(self.userRef.authData))
                        let update2 = ["post_user_reported": reportedUser]
                        hopperRef.updateChildValues(update2)
                        
                        self.reportEnabled[(indexPath as NSIndexPath).row]=false
                        
                    }else{
                        let alertController = UIAlertController(title: "Thanks!", message:
                            "You have already reported this post.", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                        
                        self.present(alertController, animated: true, completion: nil)
                        
                    }
                    
                    
                }else{
                    
                    self.performSegue(withIdentifier: "gotoLoginView", sender: nil)
                }
                
            }})
        
        reportAction.backgroundColor = UIColor.red
        
        return [reportAction]
        
        
    }
    /*
     // Override to support conditional editing of the table view.
     override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
     if editingStyle == .Delete {
     // Delete the row from the data source
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
     } else if editingStyle == .Insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
