//
//  ViewController.swift
//  Travel Book
//
//  Created by Sagar Jangra on 25/11/2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    
    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var commentText: UITextField!
    
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleId : UUID?
    
    var annotationTitle = ""
    var annotationSubTitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2.3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        let hideKeyboardGesRecog = UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        view.addGestureRecognizer(hideKeyboardGesRecog)
        
        // fetching data to show the views of the selected title
        if selectedTitle != ""{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleId!.uuidString
            // predicate used to filter out data from Persistent Container
            // And here we using idString as a filter criteria
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0{
                    for result in results as! [NSManagedObject]{
                        // nested if
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                annotationSubTitle = subtitle
                                
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    annotationLatitude = latitude
                                    
                                    if let longitide = result.value(forKey: "longitude") as? Double{
                                        annotationLongitude = longitide
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubTitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubTitle
                                        
                                        //To open the map of selected area and stop updating current location
                                        
                                        locationManager.stopUpdatingLocation()
                                        let span = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                        
                                    }
                                }
                            }
                        }
                      
                    }
                }
                
            }catch{
                print("Error")
            }
            
        }
            

    }
    
    @objc func hideKeyBoard(){
        view.endEditing(true)
    }

    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer){
        // means user has started the long press
        if gestureRecognizer.state == .began{
            
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            // annotation means that red pin point in the map
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text        //no need to Force Wrap bcz -not doing casting in other dataType
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
            
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == ""{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
        else{
            //do nothing // if has been implemented bcz we have not learned asynchronus thingy till now
        }
    }
    
    // func to open location of the saved annotation of a place
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        // if current annotation of is user current location
        if annotation is MKUserLocation{
            return nil
        }
        
        //Dequeue or Create a Reusable Annotation View
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        
        // Create a new MKMarkerAnnotationView if no reusable view is available
        if pinView == nil{
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true //on tapping a callout(a bubble containing extra information) will appear
            pinView?.tintColor = UIColor.black
            
            // Add a detail disclosure button to the annotation view
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button //adding detail button on the right side of the callOut
         }
        
        else{
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    // func to open location in apple maps on clicking the info button
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                //closure
                if let placemark = placemarks{
                    if placemark.count > 0 {
                        
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                             
                    }
                }
            }
        }
    }
    

    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
        }catch{
            print("Error in Saving!")
        }
        
        // Notification is used to send the message to the whole app that new item has been added and we can observe these changes anywhere from the app and perform action on these observations
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
}

