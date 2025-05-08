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
            
            if let corridor = createGeofenceCorridor(from: route) {
                mapView.addOverlay(corridor)
            }
            
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
    
    private func createGeofenceCorridor(from route: MKRoute) -> MKPolygon? {
        let coordinates = route.polyline.coordinates
        var corridorPoints: [CLLocationCoordinate2D] = []
        let maxDeviationDistance: CLLocationDistance = 100 // meters
        
        // Create points for both sides of the corridor
        for i in 0..<coordinates.count - 1 {
            let current = coordinates[i]
            let next = coordinates[i + 1]
            
            // Calculate perpendicular offset
            let bearing = calculateBearing(from: current, to: next)
            let offset = maxDeviationDistance / 111000 // Convert meters to degrees (approximate)
            
            // Add points for both sides of the corridor
            let leftPoint = calculateOffsetPoint(from: current, bearing: bearing - 90, distance: offset)
            let rightPoint = calculateOffsetPoint(from: current, bearing: bearing + 90, distance: offset)
            
            corridorPoints.append(leftPoint)
            corridorPoints.append(rightPoint)
        }
        
        // Create polygon from corridor points
        return MKPolygon(coordinates: corridorPoints, count: corridorPoints.count)
    }
    
    private func calculateBearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lon1 = start.longitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let lon2 = end.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x)
        
        return bearing * 180 / .pi
    }
    
    private func calculateOffsetPoint(from point: CLLocationCoordinate2D, bearing: Double, distance: Double) -> CLLocationCoordinate2D {
        let bearingRad = bearing * .pi / 180
        let lat1 = point.latitude * .pi / 180
        let lon1 = point.longitude * .pi / 180
        
        let lat2 = asin(sin(lat1) * cos(distance) + cos(lat1) * sin(distance) * cos(bearingRad))
        let lon2 = lon1 + atan2(sin(bearingRad) * sin(distance) * cos(lat1), cos(distance) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(
            latitude: lat2 * 180 / .pi,
            longitude: lon2 * 180 / .pi
        )
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
                    let identifier = "carPin"
                    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    if annotationView == nil {
                        annotationView = MKMarkerAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
                        annotationView?.canShowCallout = true
                    } else {
                        annotationView?.annotation = customAnnotation
                    }
                    if let markerView = annotationView as? MKMarkerAnnotationView {
                        markerView.markerTintColor = .blue
                        markerView.glyphImage = UIImage(systemName: "car.fill")
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
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 5
                return renderer
            } else if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.1)
                renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.3)
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
