//
//  SFMapViewController.swift
//  StamfordSchoolFinder
//
//  Created by Michael Ramos on 9/18/15.
//  Copyright © 2015 Michael Ramos. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import SwiftyJSON

class SFMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    
    let locationManager = CLLocationManager()

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var resultsListTable: UITableView!
    @IBOutlet var mapListSegmentedControl: UISegmentedControl!
    
    @IBOutlet var dismissKeyboardGestureRecognizer: UITapGestureRecognizer!
    var currentLocation: MKUserLocation?
    var foundSchools:[String] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        let region:CLCircularRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 41.07261100, longitude: -73.56452500), radius: 13252, identifier: "Stamford")
        mapView.visibleMapRect = mapView.mapRectThatFits(MKCircle(centerCoordinate: region.center, radius: region.radius).boundingMapRect, edgePadding: UIEdgeInsetsMake(20, 20, 20, 20))
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        if let row = resultsListTable.indexPathForSelectedRow
        {
            resultsListTable.deselectRowAtIndexPath(row, animated: animated)
        }
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        print("test")
        if (segue.identifier == "showSchoolDetails")
        {
            if let index = self.resultsListTable.indexPathForSelectedRow {
                    if foundSchools.count > 0 {
                    let currentSchool = foundSchools[index.row]
                    print("Selected School: \(currentSchool)")
                    let schoolDetailsViewController:SchoolDetailsViewController = segue.destinationViewController as! SchoolDetailsViewController
                    schoolDetailsViewController.currentSchool = currentSchool
                }
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        mapView.showsUserLocation = (status == .AuthorizedWhenInUse)
    }
    @IBAction func dismissKeyboard(sender: AnyObject) {
        self.view.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.view.endEditing(true)
        print("Current search term: \(searchBar.text)")
        
        let geoCoder:CLGeocoder = CLGeocoder()
        if let searchedAddress = searchBar.text {
            let region:CLCircularRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 41.07261100, longitude: -73.56452500), radius: 13252, identifier: "Stamford")
            geoCoder.geocodeAddressString(searchedAddress, inRegion: region, completionHandler: { (placemarks:[CLPlacemark]?, error:NSError?) -> Void in
                if error != nil {
                    print(error)
                }
                else {
                    //CLPlacemark *placemark = [placemarks objectAtIndex:0];
                    if let placemark:CLPlacemark = placemarks?.first {
                        print("Found Address: \(placemark.region?.description)")
                        let mapPlacemark:MKPlacemark = MKPlacemark(placemark: placemark)
                        self.mapView.removeAnnotations(self.mapView.annotations)
                        self.mapView.addAnnotation(mapPlacemark)
                        self.mapView.setCenterCoordinate(mapPlacemark.coordinate, animated: true)
                        self.searchForAddress(searchedAddress)
                    }
                    else {
                        print("Unable to find address")
                    }
                }
            })
        }
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        self.currentLocation = userLocation
        self.mapView.setCenterCoordinate(userLocation.coordinate, animated: true)
        self.askToUseCurrentLocation()
        locationManager.stopUpdatingLocation()
    }
    
    func askToUseCurrentLocation () {
        if let currentLocationCoordinate = self.currentLocation?.location {
            print("User's location: \(currentLocationCoordinate.coordinate)")
            let geoCoder:CLGeocoder = CLGeocoder()
            geoCoder.reverseGeocodeLocation(currentLocationCoordinate, completionHandler: { (placemarks:[CLPlacemark]?, error:NSError?) -> Void in
                //Would you like to search with your current location?
                if let locationName = placemarks?.first?.name,
                let locationCity = placemarks?.first?.locality,
                    let locationState = placemarks?.first?.administrativeArea {
                        let locationString = "\(locationName) \(locationCity), \(locationState)"
                        print(locationString)
                        self.searchBar.text = locationString
                        
                        let alertController = UIAlertController(title: nil, message: "Would you like to search schools for   \n \(locationString)", preferredStyle: .Alert)
                        
                        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                            // ...
                        }
                        alertController.addAction(cancelAction)
                        
                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                            self.searchForAddress(locationName)
                        }
                        alertController.addAction(OKAction)
                        
                        self.presentViewController(alertController, animated: true) {
                            // ...
                        }

                        
                }
            })
        }
        else {
            print("Couldn't find the user's current location")
        }
    }
    
    func searchForAddress (address:String) {
        print("Searching for: \(address.uppercaseString)")
        let parameters = [
            "address":address.uppercaseString
        ]
        Alamofire.request(.GET, "https://stamford-schools-api.mybluemix.net/api/schools/address", parameters: parameters)
            .responseJSON { _, _, result in
                print(result)
                debugPrint(result)
                if result.isSuccess {
                    let jsonResult = JSON(result.value!)
                    if let elementrySchool = jsonResult["elem_sch"].string,
                    let middleSchool = jsonResult["mid_sch"].string,
                        let highSchool = jsonResult["h_sch"].string {
                            self.foundSchools = []
                            self.foundSchools.append(elementrySchool)
                            self.foundSchools.append(middleSchool)
                            self.foundSchools.append(highSchool)
                            self.resultsListTable.reloadData()
                            self.addPlacemarkForString(elementrySchool)
                            self.addPlacemarkForString(middleSchool)
                            self.addPlacemarkForString(highSchool)
                    }
                    else {
                        print("Couldn't read elementry school: ")
                        print(jsonResult["elem_sch"].error)
                        print("Couldn't read middle school: ")
                        print(jsonResult["mid_sch"].error)
                        print("Couldn't read high school: ")
                        print(jsonResult["h_sch"].error)
                    }
                }
                else {
                    print("Error getting schools")
                }
        }
    }
    
    func addPlacemarkForString(location:String) {
        let geoCoder = CLGeocoder()
        let region:CLCircularRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 41.07261100, longitude: -73.56452500), radius: 13252, identifier: "Stamford")
        geoCoder.geocodeAddressString(location, inRegion: region, completionHandler: { (placemarks:[CLPlacemark]?, error:NSError?) -> Void in
            if error != nil {
                print("Error geocoding location: \(location)")
                print(error)
            }
            else {
                //CLPlacemark *placemark = [placemarks objectAtIndex:0];
                if let placemark:CLPlacemark = placemarks?.first {
                    print("Found Address: \(placemark.region?.description)")
                    let mapPlacemark:MKPlacemark = MKPlacemark(placemark: placemark)
                    self.mapView.addAnnotation(mapPlacemark)
                }
                else {
                    print("Unable to find address")
                }
            }
        })
    }
    @IBAction func segmentedControlValueChanged(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            dismissKeyboardGestureRecognizer.enabled = true
            mapView.hidden = false
            resultsListTable.hidden = true
        }
        else if sender.selectedSegmentIndex == 1 {
            dismissKeyboardGestureRecognizer.enabled = false
            mapView.hidden = true
            resultsListTable.hidden = false
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        print("Update cells")
        if foundSchools.count > 0 {
            print("Current cell: \(foundSchools[indexPath.row])")
            cell.textLabel?.text = foundSchools[indexPath.row]
        }
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return foundSchools.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("Selected index: \(indexPath.row)")
        self.performSegueWithIdentifier("showSchoolDetails", sender: self)
    }

}
