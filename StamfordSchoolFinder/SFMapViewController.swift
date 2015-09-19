//
//  SFMapViewController.swift
//  StamfordSchoolFinder
//
//  Created by Michael Ramos on 9/18/15.
//  Copyright © 2015 Michael Ramos. All rights reserved.
//

import UIKit
import MapKit

class SFMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate {
    
    let locationManager = CLLocationManager()

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var searchBar: UISearchBar!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
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
            geoCoder.geocodeAddressString(searchedAddress, completionHandler: { (placemarks:[CLPlacemark]?, error:NSError?) -> Void in
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
                    }
                    else {
                        print("Unable to find address")
                    }
                }
            })
        }
    }

}
