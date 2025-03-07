// Created for weg-li in 2021.

import Combine
import ComposableArchitecture
import CoreLocation

/// Reverse geo coding client.
struct PlacesServiceClient {
    var getPlacemarks: (CLLocation) -> Effect<[GeoAddress], PlacesServiceError>
}

extension PlacesServiceClient {
    static let live = Self(
        getPlacemarks: { location in
            .future { promise in
                CLGeocoder().reverseGeocodeLocation(location) { placemarks, error -> Void in
                    if let err = error {
                        return promise(.failure(PlacesServiceError(message: "\(String(describing: error))")))
                    }
                    guard let marks = placemarks, !marks.isEmpty else {
                        return promise(.failure(PlacesServiceError(message: "\(String(describing: placemarks))")))
                    }
                    return promise(
                        .success(
                            marks
                                .compactMap(\.postalAddress)
                                .map { GeoAddress(address: $0) }
                        )
                    )
                }
            }
        }
    )

    static let noop = Self(
        getPlacemarks: { _ in .none }
    )
}

struct PlacesServiceError: Equatable, Error {
    var message = ""
}
