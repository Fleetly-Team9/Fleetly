//
//  CustomPointAnnotation.swift
//  FleetlyDriver
//
//  Created by Sayal Singh on 25/04/25.
//

import MapKit

class CustomPointAnnotation: MKPointAnnotation {
    enum AnnotationType {
        case pickup
        case drop
        case car
    }
    
    var annotationType: AnnotationType = .pickup
}
