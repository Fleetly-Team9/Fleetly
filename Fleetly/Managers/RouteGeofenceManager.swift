import CoreLocation
import MapKit

class RouteGeofenceManager {
    private let maxDeviationDistance: CLLocationDistance = 100 // meters
    private var routeCorridor: MKPolygon?
    private var isMonitoring = false
    private var lastKnownLocation: CLLocation?
    
    // Callback for deviation events
    var onDeviationDetected: ((CLLocation, CLLocationDistance) -> Void)?
    
    func startMonitoring(route: MKRoute) {
        guard !isMonitoring else { return }
        
        // Create corridor polygon from route
        createRouteCorridor(from: route)
        isMonitoring = true
    }
    
    func stopMonitoring() {
        isMonitoring = false
        routeCorridor = nil
    }
    
    func updateLocation(_ location: CLLocation) {
        guard isMonitoring, let corridor = routeCorridor else { return }
        
        // Calculate distance to route
        let distance = calculateDistanceToRoute(location, corridor: corridor)
        
        // Check if vehicle has deviated
        if distance > maxDeviationDistance {
            onDeviationDetected?(location, distance)
        }
        
        lastKnownLocation = location
    }
    
    private func createRouteCorridor(from route: MKRoute) {
        let coordinates = route.polyline.coordinates
        var corridorPoints: [CLLocationCoordinate2D] = []
        
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
        routeCorridor = MKPolygon(coordinates: corridorPoints, count: corridorPoints.count)
    }
    
    private func calculateDistanceToRoute(_ location: CLLocation, corridor: MKPolygon) -> CLLocationDistance {
        // Convert location to coordinate
        let coordinate = location.coordinate
        
        // Check if point is inside corridor using ray casting algorithm
        if isPointInPolygon(coordinate, polygon: corridor) {
            return 0
        }
        
        // Calculate minimum distance to corridor edges
        var minDistance = Double.infinity
        let points = corridor.points()
        
        for i in 0..<corridor.pointCount {
            let point1 = points[i]
            let point2 = points[(i + 1) % corridor.pointCount]
            
            let distance = distanceToLineSegment(
                point: coordinate,
                lineStart: point1.coordinate,
                lineEnd: point2.coordinate
            )
            
            minDistance = min(minDistance, distance)
        }
        
        return minDistance
    }
    
    private func isPointInPolygon(_ point: CLLocationCoordinate2D, polygon: MKPolygon) -> Bool {
        let points = polygon.points()
        var isInside = false
        var j = polygon.pointCount - 1
        
        for i in 0..<polygon.pointCount {
            if ((points[i].coordinate.latitude > point.latitude) != (points[j].coordinate.latitude > point.latitude)) &&
                (point.longitude < (points[j].coordinate.longitude - points[i].coordinate.longitude) * (point.latitude - points[i].coordinate.latitude) / (points[j].coordinate.latitude - points[i].coordinate.latitude) + points[i].coordinate.longitude) {
                isInside = !isInside
            }
            j = i
        }
        
        return isInside
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
} 