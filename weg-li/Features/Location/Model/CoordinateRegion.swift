// Created for weg-li in 2021.

import CoreLocation
import Foundation
import MapKit

struct CoordinateRegion: Equatable {
    var center: CLLocationCoordinate2D
    var span: MKCoordinateSpan

    /// Initialize with center coordinate
    /// - Parameters:
    ///   - center: Coordinate of the region center.
    ///   - span: Zoom level with a default value of 0.02
    init(
        center: CLLocationCoordinate2D,
        span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    ) {
        self.center = center
        self.span = span
    }

    init(coordinateRegion: MKCoordinateRegion) {
        center = coordinateRegion.center
        span = coordinateRegion.span
    }

    var asMKCoordinateRegion: MKCoordinateRegion {
        .init(center: center, span: span)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.center.latitude == rhs.center.latitude
            && lhs.center.longitude == rhs.center.longitude
            && lhs.span.latitudeDelta == rhs.span.latitudeDelta
            && lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
}
