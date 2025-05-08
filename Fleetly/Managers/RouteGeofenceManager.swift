import CoreLocation
import MapKit

// MARK: - Utility Functions
struct CoordinateUtils {
    static func metersPerDegreeLatitude() -> Double {
        return 111_000.0 // Approximate meters per degree latitude
    }
    
    static func metersPerDegreeLongitude(atLatitude latitude: Double) -> Double {
        return 111_000.0 * cos(latitude * .pi / 180.0)
    }
}

class RouteGeofenceManager {
    private let maxDeviationDistance: CLLocationDistance = 100 // meters
    private var leftCorridor: MKPolyline? // Left side of the corridor
    private var rightCorridor: MKPolyline? // Right side of the corridor
    private var isMonitoring = false
    private var lastKnownLocation: CLLocation?
    private var hasDeviated = false
    
    // Callback for deviation events
    var onDeviationDetected: ((CLLocation, CLLocationDistance) -> Void)?
    
    func startMonitoring(route: MKRoute) {
        guard !isMonitoring else { return }
        
        // Create corridor polylines from route
        createRouteCorridor(from: route)
        isMonitoring = true
        hasDeviated = false
        print("Started monitoring route with geofence corridor")
    }
    
    func stopMonitoring() {
        isMonitoring = false
        leftCorridor = nil
        rightCorridor = nil
        hasDeviated = false
        print("Stopped monitoring route")
    }
    
    func updateLocation(_ location: CLLocation) {
        guard isMonitoring, let leftCorridor = leftCorridor, let rightCorridor = rightCorridor else { return }
        
        // Calculate distance to the route corridor
        let distance = calculateDistanceToRoute(location, leftCorridor: leftCorridor, rightCorridor: rightCorridor)
        
        // Check if vehicle has deviated
        if distance > maxDeviationDistance {
            if !hasDeviated {
                hasDeviated = true
                print("⚠️ VEHICLE HAS DEVIATED FROM ROUTE!")
                print("Deviation distance: \(Int(distance)) meters")
                print("Current location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                onDeviationDetected?(location, distance)
            }
        } else {
            if hasDeviated {
                hasDeviated = false
                print("✅ Vehicle has returned to the route")
            }
        }
        
        lastKnownLocation = location
    }
    
    private func createRouteCorridor(from route: MKRoute) {
        let coordinates = route.polyline.coordinates
        guard coordinates.count >= 2 else { return }
        
        let avgLat = coordinates.reduce(0) { $0 + $1.latitude } / Double(coordinates.count)
        let metersToLatDegrees = 1.0 / CoordinateUtils.metersPerDegreeLatitude()
        let metersToLonDegrees = 1.0 / CoordinateUtils.metersPerDegreeLongitude(atLatitude: avgLat)
        
        let halfWidthLat = (maxDeviationDistance / 2.0) * metersToLatDegrees
        let halfWidthLon = (maxDeviationDistance / 2.0) * metersToLonDegrees
        
        var leftSide: [CLLocationCoordinate2D] = []
        var rightSide: [CLLocationCoordinate2D] = []
        
        for i in 0..<coordinates.count-1 {
            let p1 = coordinates[i]
            let p2 = coordinates[i+1]
            
            let dx = p2.longitude - p1.longitude
            let dy = p2.latitude - p1.latitude
            let length = sqrt(dx*dx + dy*dy)
            
            if length < 1e-6 { continue }
            
            let perpX = -dy / length
            let perpY = dx / length
            
            let offsetLat = perpY * halfWidthLat
            let offsetLon = perpX * halfWidthLon
            
            let leftPoint1 = CLLocationCoordinate2D(
                latitude: p1.latitude + offsetLat,
                longitude: p1.longitude + offsetLon
            )
            let rightPoint1 = CLLocationCoordinate2D(
                latitude: p1.latitude - offsetLat,
                longitude: p1.longitude - offsetLon
            )
            
            if i == 0 {
                leftSide.append(leftPoint1)
                rightSide.append(rightPoint1)
            }
            
            if i == coordinates.count - 2 {
                let leftPoint2 = CLLocationCoordinate2D(
                    latitude: p2.latitude + offsetLat,
                    longitude: p2.longitude + offsetLon
                )
                let rightPoint2 = CLLocationCoordinate2D(
                    latitude: p2.latitude - offsetLat,
                    longitude: p2.longitude - offsetLon
                )
                leftSide.append(leftPoint2)
                rightSide.append(rightPoint2)
            }
            
            if i < coordinates.count - 2 {
                let p3 = coordinates[i+2]
                
                let dx2 = p3.longitude - p2.longitude
                let dy2 = p3.latitude - p2.latitude
                let length2 = sqrt(dx2*dx2 + dy2*dy2)
                
                if length2 > 1e-6 {
                    let perpX2 = -dy2 / length2
                    let perpY2 = dx2 / length2
                    
                    let offsetLat2 = perpY2 * halfWidthLat
                    let offsetLon2 = perpX2 * halfWidthLon
                    
                    let avgOffsetLat = (offsetLat + offsetLat2) / 2
                    let avgOffsetLon = (offsetLon + offsetLon2) / 2
                    
                    let leftJunction = CLLocationCoordinate2D(
                        latitude: p2.latitude + avgOffsetLat,
                        longitude: p2.longitude + avgOffsetLon
                    )
                    let rightJunction = CLLocationCoordinate2D(
                        latitude: p2.latitude - avgOffsetLat,
                        longitude: p2.longitude - avgOffsetLon
                    )
                    
                    leftSide.append(leftJunction)
                    rightSide.append(rightJunction)
                }
            }
        }
        
        // Create two separate polylines for the left and right sides of the corridor
        leftCorridor = MKPolyline(coordinates: leftSide, count: leftSide.count)
        rightCorridor = MKPolyline(coordinates: rightSide, count: rightSide.count)
        
        print("Created geofence corridor with \(leftSide.count + rightSide.count) points")
    }
    
    private func calculateDistanceToRoute(_ location: CLLocation, leftCorridor: MKPolyline, rightCorridor: MKPolyline) -> CLLocationDistance {
        let coordinate = location.coordinate
        
        // Calculate the minimum distance to either the left or right corridor boundary
        let distanceToLeft = calculateDistanceToPolyline(coordinate, polyline: leftCorridor)
        let distanceToRight = calculateDistanceToPolyline(coordinate, polyline: rightCorridor)
        
        // The relevant distance is the smaller of the two, as it represents the nearest boundary
        return min(distanceToLeft, distanceToRight)
    }
    
    private func calculateDistanceToPolyline(_ point: CLLocationCoordinate2D, polyline: MKPolyline) -> CLLocationDistance {
        var minDistance = Double.infinity
        let points = polyline.points()
        
        for i in 0..<polyline.pointCount-1 {
            let point1 = points[i]
            let point2 = points[i + 1]
            
            let distance = distanceToLineSegment(
                point: point,
                lineStart: point1.coordinate,
                lineEnd: point2.coordinate
            )
            
            minDistance = min(minDistance, distance)
        }
        
        return minDistance
    }
    
    private func distanceToLineSegment(point: CLLocationCoordinate2D, lineStart: CLLocationCoordinate2D, lineEnd: CLLocationCoordinate2D) -> CLLocationDistance {
        let line = CLLocation(latitude: lineStart.latitude, longitude: lineStart.longitude)
            .distance(from: CLLocation(latitude: lineEnd.latitude, longitude: lineEnd.longitude))
        
        if line == 0 {
            return CLLocation(latitude: point.latitude, longitude: point.longitude)
                .distance(from: CLLocation(latitude: lineStart.latitude, longitude: lineStart.longitude))
        }
        
        let t = max(0, min(1, (
            (point.latitude - lineStart.latitude) * (lineEnd.latitude - lineStart.latitude) +
            (point.longitude - lineStart.longitude) * (lineEnd.longitude - lineStart.longitude)
        ) / (line * line)))
        
        let projection = CLLocationCoordinate2D(
            latitude: lineStart.latitude + t * (lineEnd.latitude - lineStart.latitude),
            longitude: lineStart.longitude + t * (lineEnd.longitude - lineStart.longitude)
        )
        
        return CLLocation(latitude: point.latitude, longitude: point.longitude)
            .distance(from: CLLocation(latitude: projection.latitude, longitude: projection.longitude))
    }
    
    // Helper method to get the corridor polylines for rendering on the map
    func getCorridorPolylines() -> [MKPolyline] {
        var polylines: [MKPolyline] = []
        if let left = leftCorridor {
            polylines.append(left)
        }
        if let right = rightCorridor {
            polylines.append(right)
        }
        return polylines
    }
}
