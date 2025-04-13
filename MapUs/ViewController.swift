import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate, MKMapViewDelegate {
    var mapView: MKMapView!
    var locationManager: CLLocationManager!
    var takenPhoto: UIImage?
    var currentLocation: CLLocation?
    var tappedLocationCoordinate: CLLocationCoordinate2D?
    var photoAnnotationCoordinates: [CLLocationCoordinate2D] = []
    var shouldUpdateMapRegion = true
    var startButton = UIButton(type: .system)
    var imagesForReview: [UIImage] = []
    var collectionView: UICollectionView!
    var hasStarted = false
    let cameraButton = UIButton(frame: CGRect.zero)
    let consolidateButton = UIButton(type: .system)
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        // Initialize and configure the mapView
        mapView = MKMapView(frame: self.view.bounds)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading // Enable tracking the user's location
        mapView.delegate = self
        self.view.addSubview(mapView)
        
        startButton = UIButton(type: .system)
        startButton.setTitle("Start", for: .normal)
        startButton.backgroundColor = .systemBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 25
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        
        view.addSubview(startButton)
        startButton.translatesAutoresizingMaskIntoConstraints = false
            // Set up constraints
        NSLayoutConstraint.activate([
        startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        startButton.widthAnchor.constraint(equalToConstant: 100),
        startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
         
        //let cameraButton = UIButton(frame: CGRect.zero)
            cameraButton.translatesAutoresizingMaskIntoConstraints = false
            cameraButton.setTitle("Camera", for: .normal)
            cameraButton.backgroundColor = .systemBlue
            cameraButton.layer.cornerRadius = 40
            cameraButton.addTarget(self, action: #selector(openCamera), for: .touchUpInside)
           self.view.addSubview(cameraButton)
        

            // Constraints
            NSLayoutConstraint.activate([
                cameraButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                cameraButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                cameraButton.widthAnchor.constraint(equalToConstant: 80),
                cameraButton.heightAnchor.constraint(equalToConstant: 80)
            ])
        cameraButton.isHidden = true
        guard let userLocation = locationManager.location?.coordinate else {
                print("Current user location is not available.")
                return
            }
            // Store the user's current location's coordinate
            tappedLocationCoordinate = userLocation
            photoAnnotationCoordinates.append(userLocation)
        //let consolidateButton = UIButton(type: .system)
        consolidateButton.setTitle("Finish", for: .normal)
        consolidateButton.setTitleColor(UIColor.white, for: .normal)
        consolidateButton.backgroundColor = .systemBlue
        consolidateButton.layer.cornerRadius = 40
        consolidateButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(consolidateButton)

        NSLayoutConstraint.activate([
            consolidateButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            consolidateButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 20), // Adjusted line
            consolidateButton.widthAnchor.constraint(equalToConstant: 80),
            consolidateButton.heightAnchor.constraint(equalToConstant: 80)
        ])
        consolidateButton.isHidden = true

        consolidateButton.addTarget(self, action: #selector(consolidateAction), for: .touchUpInside)
    }
    
    @objc func enableLocationTracking() {
        mapView.userTrackingMode = .follow
    }
    @objc func consolidateAction() {
        // Fetch images from annotations
        
        let images = collectImagesFromAnnotations()

        // For simplicity in this example, just print the count of collected images
        print("Collected \(images.count) images.")

        // Assuming you have a method to show these images in a UICollectionView or similar
        showImagesForReview(images)
    }
    func showImagesForReview(_ images: [UIImage]) {
        let imageReviewVC = ImageReviewViewController()
            imageReviewVC.images = images // Your array of UIImage
            imageReviewVC.modalPresentationStyle = .fullScreen // Adjust as needed
            self.present(imageReviewVC, animated: true, completion: nil)
    }

    @objc func startButtonTapped() {
        openCamera()
        DispatchQueue.main.async {
                self.startButton.removeFromSuperview()
                self.cameraButton.isHidden = false
                self.consolidateButton.isHidden = false
            }
        
        // Ensure location services are enabled and start updating location
        if CLLocationManager.locationServicesEnabled() {
            switch locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                locationManager.startUpdatingLocation()
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization() // Or requestAlwaysAuthorization() as needed
            default:
                // Location services are not authorized; handle appropriately
                print("Location services not authorized or unavailable")
            }
        } else {
            print("Location services are disabled.")
        }
    }
// Handle authorization changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            mapView.showsUserLocation = true
        default:
            // Handle .notDetermined, .restricted, and .denied cases
            break
        }
    }
    // Update map region based on user's location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, shouldUpdateMapRegion else { return }

        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 300, longitudinalMeters: 300)
        mapView.setRegion(region, animated: true)
        
        // Reset the flag if you only want the automatic centering to occur once
        shouldUpdateMapRegion = false
    }
    // Function to center map on a specific location
    func centerMapOnLocation(location: CLLocation) {
        let regionRadius: CLLocationDistance = 100
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
        latitudinalMeters: regionRadius,longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    // Handle location manager errors
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }

    class PhotoAnnotation: NSObject, MKAnnotation {
        dynamic var coordinate: CLLocationCoordinate2D
        var title: String?
        var image: UIImage?
        
        init(coordinate: CLLocationCoordinate2D, title: String, image: UIImage?) {
            self.coordinate = coordinate
            self.title = title
            self.image = image
        }
    }
@objc func mapTapped(_ gesture: UITapGestureRecognizer) {
    }
    
    @objc func openCamera() {
        let photoPrompts = [
            "Find something blue",
            "Take a picture with the Professor",
            "Make a funny face",
            "Do a hand stand",
            "Get Angry",
            "Take a pic with a local",
            "Capture some wildlife",
            "Let's see those pearly whites!"
            // Add all other prompts here...
        ]
        // Store the user's current location's coordinate
        let alertController = UIAlertController(title: "Photo", message: photoPrompts.randomElement(), preferredStyle: .alert)
        
        // Use UIAlertAction with a closure to present the camera after "Okay!" is tapped
        alertController.addAction(UIAlertAction(title: "Okay!", style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        present(alertController, animated: true)
    }

    /// Helper method to present the camera interface.
    func presentCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        } else {
            print("Camera not available")
        }
    }
    // UIImagePickerControllerDelegate method
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let currentLocation = locationManager.location?.coordinate else {
               print("Current user location is not available.")
               return
           }
        self.tappedLocationCoordinate = currentLocation
        self.photoAnnotationCoordinates.append(currentLocation)
        guard let image = info[.originalImage] as? UIImage else { return }

        // Use the original image directly without resizing
        self.takenPhoto = image

        // Assuming you're adding an annotation with this image at a stored coordinate
        if let location = self.tappedLocationCoordinate {
            addAnnotation(at: location, with: image) // Use the original image here
        }
        
        // Save the original image to the Photos app
        //UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // If an error occurred, you can alert the user
            showAlertWithTitle("Save error", message: error.localizedDescription)
        } else {
            
        }
    }
    func showAlertWithTitle(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
    func addAnnotation(at coordinate: CLLocationCoordinate2D, with image: UIImage) {
        let photoAnnotations = mapView.annotations.filter { $0 is PhotoAnnotation }
        // Label each photo with "PHOTO" followed by its sequence number
        let title = "PHOTO \(photoAnnotations.count + 1)"
        
        let annotation = PhotoAnnotation(coordinate: coordinate, title: title, image: image)
        mapView.addAnnotation(annotation)
        connectPhotoAnnotationsWithLine()
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        // Detect if the region change is user-initiated
        if mapView.isZoomEnabled || mapView.isRotateEnabled || mapView.isScrollEnabled{
            shouldUpdateMapRegion = false
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Ensure we don't change the default user location annotation view
        if annotation is MKUserLocation {
            return nil
        }

        guard let photoAnnotation = annotation as? PhotoAnnotation else {
            return nil // Return nil if the annotation isn't a PhotoAnnotation to use default view
        }

        let identifier = "ImageAnnotation"
        // Attempt to dequeue an existing annotation view
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            // Create a new MKAnnotationView if one cannot be dequeued
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true // Enable callout bubble on tap
        } else {
            // If an existing view was dequeued, update its annotation
            annotationView?.annotation = annotation
        }

        // Set the custom image for the annotation view
        annotationView?.image = photoAnnotation.image?.croppedToCircle()?.resized(to:CGSize(width: 75, height: 75))
        
        // Optional: Adjust the frame of the annotationView here if you need to resize
        // annotationView?.frame.size = CGSize(width: 50, height: 50)

        return annotationView
    }

    @IBAction func picButton(_ sender: Any) {
        
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .orange // Set polyline color
            renderer.lineWidth = 3.0 // Set polyline width
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    func connectPhotoAnnotationsWithLine() {
        guard photoAnnotationCoordinates.count > 1 else { return } // Need at least two points to draw a line
        
        let polyline = MKPolyline(coordinates: photoAnnotationCoordinates, count: photoAnnotationCoordinates.count)
        mapView.addOverlay(polyline)
    }
    
    func updateAnnotationViewSizes() {
        for annotation in mapView.annotations {
            guard let annotationView = mapView.view(for: annotation) else { continue }
            
            // Calculate a scale factor based on the latitudeDelta (or use longitudeDelta)
            // Note: These scaling factors are arbitrary and may need adjustment
            let scaleFactor = min(max(mapView.region.span.latitudeDelta, 0.05), 0.5)
            let size = max(50, scaleFactor * 3000) // Adjust these numbers as needed
            
            // Ensure the size is within the allowed range
            let newSize = min(max(size, 50), 150)
            annotationView.frame.size = CGSize(width: newSize, height: newSize)
        }
        
    }
    func collectImagesFromAnnotations() -> [UIImage] {
        var images: [UIImage] = []
        for annotation in mapView.annotations {
            if let customAnnotation = annotation as? PhotoAnnotation, let image = customAnnotation.image {
                images.append(image)
            }
        }
        return images
    }
    func setupCollectionView() {
        imagesForReview = collectImagesFromAnnotations()
        collectionView.reloadData() // Assuming collectionView is already set up and linked
    }

    // CollectionView DataSource methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesForReview.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCollectionViewCell else {
            return UICollectionViewCell()
        }
        let image = imagesForReview[indexPath.row]
        cell.imageView.image = image // Assuming your cell has an imageView property
        return cell
    }
    class ImageCollectionViewCell: UICollectionViewCell {
        @IBOutlet var imageView: UIImageView!
        
        var onDelete: (() -> Void)?
        
        @IBAction func deleteButtonTapped(_ sender: UIButton) {
            onDelete?()
        }
    }

}
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        // Begin a graphics context with the target size
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        // Draw the image in the target size
        self.draw(in: CGRect(origin: .zero, size: size))
        // Capture the resized image from the context
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        // End the graphics context
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    func croppedToCircle() -> UIImage? {
        let minEdge = min(size.width, size.height)
        let squareImage = resized(to: CGSize(width: minEdge, height: minEdge))
        let circlePath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: CGSize(width: minEdge, height: minEdge)))
        
        UIGraphicsBeginImageContextWithOptions(squareImage?.size ?? CGSize.zero, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        
        context?.saveGState()
        circlePath.addClip()
        squareImage?.draw(at: CGPoint.zero)
        context?.restoreGState()
        
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return croppedImage
    }
    
}
