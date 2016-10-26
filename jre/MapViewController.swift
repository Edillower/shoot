//
//  MapViewController.swift
//  jre
//
//  Created by Joey Van Gundy on 2/19/16.
//  Copyright © 2016 Joe Van Gundy. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase
import MapKit

class MapViewController: UIViewController, UISearchBarDelegate {
    var markerPlaceID = ""
    var markerPlaceName = ""
    var markerCoordinates = CLLocationCoordinate2D.init()
    var comeback=false;
    var markerIcon = UIImage (named: "icon.png")
    
    @IBAction func searchButton(_ sender: AnyObject) {
        if searchBar.isHidden {
            searchBar.isHidden = false
            searchButton.setTitle("Cancel", for: UIControlState())
        }else{
            searchBar.isHidden = true
            searchBarCancelButtonClicked(self.searchBar)
            searchButton.setTitle("Search", for: UIControlState())
        }
    }
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: GMSMapView!
    //@IBOutlet weak var mapOverlay: UIView!
    
    let locationManager = CLLocationManager()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if CLLocationManager.locationServicesEnabled() == false {
            let alertController = UIAlertController(title: "GPS Failure", message:
                "Please check your GPS connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
    
        
        
        searchBar.isHidden = true
        searchBar.delegate = self
        
        mapView.delegate = self
        
        print("onCreate: "+NSStringFromClass(type(of: self)))
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
            print("network error")
        }else{
            // Get a reference to our posts
            let postRef = Firebase(url:"https://jrecse.firebaseio.com/posts")
            postRef.queryOrderedByChild("post_place_name").observeEventType(.ChildAdded, withBlock: { snapshot in
                print(snapshot.value["post_place_name"] as! String)
                let marker_place_name = snapshot.value["post_place_name"]
                let marker_place_id = snapshot.value["post_placeID"]
                let marker_longitude = snapshot.value["post_longitude"]
                let marker_latitude = snapshot.value["post_latitude"]
                let marker_description = snapshot.value["post_description"]
                let markerPostition = CLLocationCoordinate2DMake(marker_latitude as! Double, marker_longitude as! Double)
                //            let marker = self.createMarker(markerPostition, markerTitle: marker_place_name as! String)
                let marker = GMSMarker()
                marker.title = marker_place_name as! String
                marker.position = markerPostition
                marker.icon=self.markerIcon
                marker.userData = marker_place_id as! String
                marker.map = self.mapView
                print(marker.userData)
                print("Marker placed!")
                
            })
        }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("onStart/onResume: "+NSStringFromClass(type(of: self)))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("onPause/onStop: "+NSStringFromClass(type(of: self)))
    }
    
    
    func populateMapWithPosts(){
        
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
}

// MARK: - CLLocationManagerDelegate
//1
extension MapViewController: CLLocationManagerDelegate {
    // 2
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // 3
        if status == .authorizedWhenInUse {
            
            // 4
            locationManager.startUpdatingLocation()
            
            //5
            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
        }
    }
    
    // 6
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        
        if(comeback){
            mapView.camera = GMSCameraPosition(target: markerCoordinates, zoom: 15, bearing: 0, viewingAngle: 0)
        } else {
            if let location = locations.first {
                mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
            }
        }
        locationManager.stopUpdatingLocation()
        
    }
    @IBAction func showMapButton(_ sender: AnyObject) {
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            self.performSegue(withIdentifier: "showCamera", sender: nil)
        }
    }
    
    @IBAction func newPostButton(_ sender: AnyObject) {
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            let userRef = Firebase(url: "https://jrecse.firebaseio.com/users")
            if(userRef.authData != nil){
                self.performSegue(withIdentifier: "mapViewToCameraView", sender: nil)
            }else{
                self.performSegue(withIdentifier: "mapViewToLoginView", sender: nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mapViewToTableView" {
            if let destination = segue.destination as? PlaceTableViewController {
                
                destination.placeID = self.markerPlaceID
                destination.placeTitile = self.markerPlaceName
                destination.markerCoordinates = self.markerCoordinates
                
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchbar: UISearchBar) {
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            print("search for \(searchBar.text!)")
            var lat:Double = 0, lon:Double = 0
            //        postRef.queryOrderedByChild("post_place_name").queryEqualToValue("\(searchBar.text!)").observeEventType(.Value, withBlock: { snapshot in
            //            let temp = snapshot.children.nextObject()
            //            lat = temp!.value["post_latitude"] as! Double
            //            lon = temp!.value["post_longitude"] as! Double
            //            print("lat: \(lat), lon: \(lon)")
            //            let camera = GMSCameraPosition.cameraWithLatitude(lat, longitude:lon, zoom: 16)
            //            self.mapView.animateToCameraPosition(camera)
            //        })
            let localSearchRequest = MKLocalSearchRequest()
            localSearchRequest.naturalLanguageQuery = searchBar.text
            let localSearch = MKLocalSearch(request: localSearchRequest)
            localSearch.start { (localSearchResponse, error) -> Void in
                
                if localSearchResponse == nil{
                    let alertController = UIAlertController(title: nil, message: "Place Not Found", preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                    return
                }
                lat = localSearchResponse!.boundingRegion.center.latitude
                lon = localSearchResponse!.boundingRegion.center.longitude
                let camera = GMSCameraPosition.camera(withLatitude: lat, longitude:lon, zoom: 16)
                self.mapView.animate(to: camera)
                self.view.endEditing(true)
                
            }
        }
    }
    
    
    
    
}



extension MapViewController: GMSMapViewDelegate{
    func mapView(_ mapView: GMSMapView!, didTap marker: GMSMarker!) -> Bool {
        print("tap")
        return false
    }
    
    func mapView(_ mapView: GMSMapView!, didTapInfoWindowOf marker: GMSMarker!) {
        print("tap")
        self.markerPlaceName = marker.title
        self.markerPlaceID = marker.userData as! String
        self.markerCoordinates = marker.position
        if Reachability.isConnectedToNetwork() == false {
            let alertController = UIAlertController(title: "Network Failure", message:
                "Please check your network connection", preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }else{
            self.performSegue(withIdentifier: "mapViewToTableView", sender: nil)
        }
    }
}
