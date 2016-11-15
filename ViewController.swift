//
//  ViewController.swift
//  gps-test
//
//  Created by Jack on 15 Sep 16.
//  Copyright © 2016 John Morales. All rights reserved.
//

import UIKit
import MapKit
import AVFoundation


class ViewController: UIViewController, CLLocationManagerDelegate {
    var locationNames = ["Alderaan", "Bespin", "Coruscant", "Dagobah", "Endor", "Geonosis", "Hoth", "Jay's House"]
    var locArray: [CLLocationCoordinate2D] = []
    @IBOutlet weak var myMapView: MKMapView!
    @IBOutlet weak var liveLocation: UILabel!
    
    // distance label
    @IBOutlet weak var liveDistance: UILabel!
    
    // are we close enough?
    @IBOutlet weak var distanceMetLabel: UILabel!
    
    // label for timer
    @IBOutlet weak var timerLabel: UILabel!

    // initialize timer (needs fixing)
    var totalDistance = 0.0
    var counter = 0.0
    var timer: Int = 0
    var elapsedTime: Int = 0
    var pausedTime: Int = 0
    var paused: Bool = false
    var distanceMeters = 0.0
    
    let systemSoundID: SystemSoundID = 1016

    @IBAction func resetStatusButton(sender: UIButton) {
        reset()
    }
    
    func reset(){
        // remove annotations
        let allAnnotations = self.myMapView.annotations
        self.myMapView.removeAnnotations(allAnnotations)

        // remove route
        var overlays = myMapView.overlays
        myMapView.removeOverlays(overlays)

        // clear locArray
        locArray = []
        // clear timer
        // create outlet to reenable start timer button
        
    }
    
    @IBAction func addPin(sender: UITapGestureRecognizer) {
        //get the location and convert to coordinates
        let location = sender.locationInView(self.myMapView)
        let locCoord = self.myMapView.convertPoint(location, toCoordinateFromView: self.myMapView)
        
        // you neeed a CLLocation to calculate distance (convert from CLLocation2D)
        let locLocation = CLLocation(latitude: locCoord.latitude, longitude: locCoord.longitude)
        
        // create a new array to hold all distances from points in locArray
        var distanceArray: [CLLocationDistance] = []
        
        // append distances to the distance array
        if locArray.count > 0{
            for i in 0...locArray.count-1{
                let distanceToNewCoord = locLocation.distanceFromLocation(CLLocation(latitude: locArray[i].latitude, longitude: locArray[i].longitude))
                distanceArray.append(distanceToNewCoord)
                totalDistance += distanceToNewCoord
            }
        }
        // check if new point is too close
        var tooClose = false
        if distanceArray.count > 0 {
            for i in 0...distanceArray.count-1{
                if distanceArray[i] < 20{
                    tooClose = true
                }
            }
        }
        
        // if tooClose is false, append to locArray. otherwise it will show the annotation
        if tooClose == false {
            //adding to array
            locArray.append(locCoord)
            
            //        let placeMark = MKPlacemark(coordinate: locCoord, addressDictionary: nil)
            //        destination = MKMapItem(placemark: placeMark)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = locCoord
            if locArray.count > 8{
                annotation.title = "\(locationNames[7])"
            } else{
                annotation.title = "\(locationNames[locArray.count-1])"
            }
            annotation.subtitle = "Waypoint \(locArray.count)"
            
            //        self.map.removeAnnotation(map.annotations)
            self.myMapView.addAnnotation(annotation)
        }
    }
    @IBAction func showDirection(sender: UIButton) {
        
        for i in 0...locArray.count-1 {
            let sourceLocation = locArray[0]
            let destinationLocation = locArray[i]
            
            let sourcePlaceMark = MKPlacemark(coordinate: sourceLocation, addressDictionary: nil)
            let destinationPlaceMark = MKPlacemark(coordinate: destinationLocation, addressDictionary: nil)
            
            let sourceMapItem = MKMapItem(placemark: sourcePlaceMark)
            let destinationMapItem = MKMapItem(placemark: destinationPlaceMark)
            
            let directionRequest = MKDirectionsRequest()
            directionRequest.source = sourceMapItem
            directionRequest.destination = destinationMapItem
            directionRequest.transportType = .Walking
            
            //calculate direction
            let directions = MKDirections(request: directionRequest)
            directions.calculateDirectionsWithCompletionHandler{(response, error) -> Void in
                
                guard let response = response else {
                    if let error = error {
                        print("Error: \(error)")
                    }
                    
                    return
                }
                
                let route = response.routes[0]
                self.myMapView.addOverlay((route.polyline), level: MKOverlayLevel.AboveRoads)
                
//                let rect = route.polyline.boundingMapRect
//                self.myMapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
                self.liveDistance.text = "\(round(self.totalDistance * 10) / 10) m"
            }
        }
        
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.redColor()
        renderer.lineWidth = 4.0
        
        return renderer
    }
    
    @IBAction func startTimer(sender: UIButton) {
        timer = Int(CACurrentMediaTime())
        timerLabel.text = "0"
        timerLabel.hidden = false
        sender.enabled = false
    }
    let locManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let updateTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
        timerLabel.hidden = true
        // set initial region
        let myLatDelta = 0.01
        let myLongDelta = 0.01
        let mySpan = MKCoordinateSpan(latitudeDelta: myLatDelta, longitudeDelta: myLongDelta)
        let myCoor2D = CLLocationCoordinate2D(latitude: 37.375571, longitude: -121.909858)
        let myRegion = MKCoordinateRegion(center: myCoor2D, span: mySpan)
        
        // center map at loc
        myMapView.setRegion(myRegion, animated: true)
        
        locManager.desiredAccuracy = kCLLocationAccuracyBest
        // info Plist permission
        locManager.requestWhenInUseAuthorization()
        
        locManager.startUpdatingLocation()
        locManager.delegate = self
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       
        // get most recent coord
        let myCoor = locations[locations.count - 1]
        
        // get lat and long
        let myLat = myCoor.coordinate.latitude
        let myLong = myCoor.coordinate.longitude
        let myCoorDistance = CLLocation(latitude: myLat, longitude: myLong)
        
        myMapView.showsUserLocation = true
        // 37.377329 -121.913010
        // add annotation
//        let anno2DCoor = CLLocationCoordinate2D(latitude: 37.375571, longitude: -121.909858)
        // corner of brokaw and zanker
//        // let anno2DCoor = CLLocationCoordinate2D(latitude: 37.3753727, longitude: -121.9102404)
//        let myAnno = MKPointAnnotation()
//        myAnno.coordinate = anno2DCoor
//        myMapView.addAnnotation(myAnno)
        
        // calculates distance between user and location
//        let parkingLot = CLLocation(latitude: 37.375571, longitude: -121.909858)
//        let distanceMeters = parkingLot.distanceFromLocation(myCoorDistance)
        
        //test
//        liveLocation.text = "Lat: \(round(myLat*10000)/10000), Long: \(round(myLong*10000)/10000)"
//        liveDistance.text = "Distance: \(round(distanceMeters*10)/10)"
        
        // check if distance between user and location is less than 10 meters
//        if distanceMeters < 10{
//            distanceMetLabel.text = "we are close enough!"
//            
//            // this sound keeps playing while in range. it also sounds at the beginning before the location is loaded.
//            AudioServicesPlaySystemSound (systemSoundID)
//            
//            // add logic to switch parkingLot to be next waypoint (use the array of waypoints that Adi can build?)
//            
//            // store time in an array for checkpoint times
//            
//        }
        
        
        
        
    }
    func update(){
        elapsedTime = Int(CACurrentMediaTime()) - timer
        print(paused, elapsedTime)
        if paused {
            timerLabel.text = "\(pausedTime)"
        } else {
            timerLabel.text = "\(elapsedTime)"
        }
    }
}

