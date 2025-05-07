//
//  MapViewWithRoute.swift
//  FleetlyDriver
//
//  Created by Sayal Singh on 25/04/25.
//
import SwiftUI
import MapKit

struct MapViewWithRoute: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let pickup: Location
    let drop: Location
    let route: MKRoute?
    @Binding var mapStyle: MapStyle
    let isTripStarted: Bool
    let userLocationCoordinate: CLLocationCoordinate2D?
    let poiAnnotations: [CustomPointAnnotation]
    
    private let carAnnotationIdentifier = "carAnnotation"
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        mapView.removeOverlays(mapView.overlays)
        let nonCarAnnotations = mapView.annotations.filter {
            if let annotation = $0 as? CustomPointAnnotation {
                return annotation.annotationType != .car
            }
            return true
        }
        mapView.removeAnnotations(nonCarAnnotations)
        
        switch mapStyle {
        case .standard: mapView.mapType = .standard
        case .satellite: mapView.mapType = .satellite
        case .hybrid: mapView.mapType = .hybrid
        case .hybridFlyover: mapView.mapType = .hybridFlyover
        }
        
        let pickupAnnotation = CustomPointAnnotation()
        pickupAnnotation.coordinate = pickup.coordinate
        pickupAnnotation.title = pickup.name
        pickupAnnotation.annotationType = .pickup
        
        let dropAnnotation = CustomPointAnnotation()
        dropAnnotation.coordinate = drop.coordinate
        dropAnnotation.title = drop.name
        dropAnnotation.annotationType = .drop
        
        var annotationsToAdd = [pickupAnnotation, dropAnnotation]
        annotationsToAdd.append(contentsOf: poiAnnotations)
        
        mapView.addAnnotations(annotationsToAdd)
        
        if let route = route {
            mapView.addOverlay(route.polyline)
            if !isTripStarted {
                let rect = route.polyline.boundingMapRect
                mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
            }
        }
        
        if isTripStarted {
            var carAnnotation: CustomPointAnnotation
            if let existingCarAnnotation = mapView.annotations.first(where: {
                ($0 as? CustomPointAnnotation)?.annotationType == .car
            }) as? CustomPointAnnotation {
                carAnnotation = existingCarAnnotation
            } else {
                carAnnotation = CustomPointAnnotation()
                carAnnotation.annotationType = .car
                carAnnotation.title = "Your Car"
                if let userLocation = userLocationCoordinate {
                    carAnnotation.coordinate = userLocation
                } else {
                    carAnnotation.coordinate = pickup.coordinate
                }
                mapView.addAnnotation(carAnnotation)
            }
            
            if let userLocation = userLocationCoordinate {
                UIView.animate(withDuration: 0.5) {
                    carAnnotation.coordinate = userLocation
                }
                let viewRegion = MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
                mapView.setRegion(viewRegion, animated: true)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let customAnnotation = annotation as? CustomPointAnnotation {
                switch customAnnotation.annotationType {
                case .pickup:
                    let identifier = "pickupPin"
                    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    if annotationView == nil {
                        annotationView = MKMarkerAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
                        annotationView?.canShowCallout = true
                    } else {
                        annotationView?.annotation = customAnnotation
                    }
                    if let markerView = annotationView as? MKMarkerAnnotationView {
                        markerView.markerTintColor = .green
                        markerView.glyphImage = UIImage(systemName: "mappin.circle.fill")
                    }
                    return annotationView
                case .drop:
                    let identifier = "dropPin"
                    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    if annotationView == nil {
                        annotationView = MKMarkerAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
                        annotationView?.canShowCallout = true
                    } else {
                        annotationView?.annotation = customAnnotation
                    }
                    if let markerView = annotationView as? MKMarkerAnnotationView {
                        markerView.markerTintColor = .red
                        markerView.glyphImage = UIImage(systemName: "mappin.circle.fill")
                    }
                    return annotationView
                case .car:
                    let identifier = "carAnnotation"
                    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    if annotationView == nil {
                        annotationView = MKAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
                        annotationView?.canShowCallout = true
                    } else {
                        annotationView?.annotation = customAnnotation
                    }
                    if let carImage = UIImage(systemName: "car.fill") {
                        let resizedImage = resizeImage(image: carImage, targetSize: CGSize(width: 30, height: 30))
                        let circleSize = CGSize(width: 40, height: 40)
                        UIGraphicsBeginImageContextWithOptions(circleSize, false, 0)
                        let context = UIGraphicsGetCurrentContext()!
                        context.setFillColor(UIColor.blue.cgColor)
                        context.fillEllipse(in: CGRect(origin: .zero, size: circleSize))
                        let carRect = CGRect(
                            x: (circleSize.width - resizedImage.size.width) / 2,
                            y: (circleSize.height - resizedImage.size.height) / 2,
                            width: resizedImage.size.width,
                            height: resizedImage.size.height
                        )
                        resizedImage.withTintColor(.white).draw(in: carRect)
                        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        annotationView?.image = finalImage
                    }
                    return annotationView
                case .hospital:
                    let identifier = "hospitalPin"
                    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    if annotationView == nil {
                        annotationView = MKMarkerAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
                        annotationView?.canShowCallout = true
                    } else {
                        annotationView?.annotation = customAnnotation
                    }
                    if let markerView = annotationView as? MKMarkerAnnotationView {
                        markerView.markerTintColor = .purple
                        markerView.glyphImage = UIImage(systemName: "cross.circle.fill")
                    }
                    return annotationView
                case .petrolPump:
                    let identifier = "petrolPumpPin"
                    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    if annotationView == nil {
                        annotationView = MKMarkerAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
                        annotationView?.canShowCallout = true
                    } else {
                        annotationView?.annotation = customAnnotation
                    }
                    if let markerView = annotationView as? MKMarkerAnnotationView {
                        markerView.markerTintColor = .orange
                        markerView.glyphImage = UIImage(systemName: "fuelpump.circle.fill")
                    }
                    return annotationView
                case .mechanics:
                    let identifier = "mechanicsPin"
                    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    if annotationView == nil {
                        annotationView = MKMarkerAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
                        annotationView?.canShowCallout = true
                    } else {
                        annotationView?.annotation = customAnnotation
                    }
                    if let markerView = annotationView as? MKMarkerAnnotationView {
                        markerView.markerTintColor = .gray
                        markerView.glyphImage = UIImage(systemName: "wrench.and.screwdriver.fill")
                    }
                    return annotationView
                case .none:
                    return nil
                }
            }
            return nil
        }
        
        private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
            let size = image.size
            let widthRatio = targetSize.width / size.width
            let heightRatio = targetSize.height / size.height
            var newSize: CGSize
            if widthRatio > heightRatio {
                newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
            } else {
                newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
            }
            let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage!
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
