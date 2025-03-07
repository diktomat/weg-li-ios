// Created for weg-li in 2021.

import Combine
import ComposableArchitecture
import ComposableCoreLocation
import MapKit
@testable import weg_li
import XCTest

class ReportStoreTests: XCTestCase {
    let fixedUUID = { UUID() }
    let fixedDate = { Date() }

    let districs = DistrictFixtures.districts

    var report: Report!

    override func setUp() {
        super.setUp()

        report = Report(
            uuid: fixedUUID(),
            images: ImagesViewState(
                showImagePicker: false,
                storedPhotos: [StorableImage(uiImage: UIImage(systemName: "pencil")!)!],
                coordinateFromImagePicker: .zero
            ),
            contact: .preview,
            district: nil,
            date: fixedDate,
            description: .init()
        )
    }

    // MARK: - Reducer integration tests

    func test_updateContact_shouldUpdateState() {
        let store = TestStore(
            initialState: report,
            reducer: reportReducer,
            environment: ReportEnvironment(
                mainQueue: DispatchQueue.immediate.eraseToAnyScheduler(),
                locationManager: LocationManager.unimplemented(),
                placeService: .noop,
                regulatoryOfficeMapper: .noop
            )
        )

        let firstName = "BOB"
        let lastName = "ROSS"
        let city = "Rosstown"
        store.assert(
            .send(.contact(.firstNameChanged(firstName))) {
                $0.contact.firstName = firstName
            },
            .send(.contact(.lastNameChanged(lastName))) {
                $0.contact.name = lastName
            },
            .send(.contact(.townChanged(city))) {
                $0.contact.address.city = city
            }
        )
    }

    func test_updateCar_shouldUpdateState() {
        let store = TestStore(
            initialState: report,
            reducer: reportReducer,
            environment: ReportEnvironment(
                mainQueue: DispatchQueue.immediate.eraseToAnyScheduler(),
                locationManager: LocationManager.unimplemented(),
                placeService: .noop,
                regulatoryOfficeMapper: .noop
            )
        )

        let color = 1
        let type = 2
        store.assert(
            .send(.description(.setColor(color))) {
                $0.description.selectedColor = color
            },
            .send(.description(.setBrand(type))) {
                $0.description.selectedBrand = type
            }
        )
    }

    func test_updateCharge_shouldUpdateState() {
        let store = TestStore(
            initialState: report,
            reducer: reportReducer,
            environment: ReportEnvironment(
                mainQueue: DispatchQueue.immediate.eraseToAnyScheduler(),
                locationManager: LocationManager.unimplemented(),
                placeService: .noop,
                regulatoryOfficeMapper: .noop
            )
        )

        let duration = 42
        let type = 23
        store.assert(
            .send(.description(.setCharge(type))) {
                $0.description.selectedType = type
            },
            .send(.description(.setDuraration(duration))) {
                $0.description.selectedDuration = duration
            }
        )
    }

    func test_updateImages_shouldTriggerAddressResolve() {
        let image = UIImage(systemName: "pencil")!
        let coordinate: CLLocationCoordinate2D = .init(latitude: 43.32, longitude: 32.43)
        let expectedAddress = GeoAddress(
            street: ContactState.preview.address.street,
            city: ContactState.preview.address.city,
            postalCode: ContactState.preview.address.postalCode
        )

        let store = TestStore(
            initialState: report,
            reducer: reportReducer,
            environment: ReportEnvironment(
                mainQueue: DispatchQueue.immediate.eraseToAnyScheduler(),
                locationManager: LocationManager.unimplemented(),
                placeService: PlacesServiceClient(
                    getPlacemarks: { _ in Effect(value: [expectedAddress]) }
                ),
                regulatoryOfficeMapper: .noop
            )
        )

        store.assert(
            .send(.images(.addPhotos([StorableImage(uiImage: image)]))) {
                $0.images.storedPhotos = [StorableImage(uiImage: image)!]
            },
            .send(.images(.setResolvedCoordinate(coordinate))) {
                $0.location.userLocationState.region = CoordinateRegion(center: coordinate)
            },
            .receive(.location(.resolveLocation(coordinate))) {
                $0.location.isResolvingAddress = true
            },
            .receive(.location(.resolveAddressFinished(.success([expectedAddress])))) {
                $0.location.isResolvingAddress = false
                $0.location.resolvedAddress = expectedAddress
            },
            .receive(.mapGeoAddressToDistrict(expectedAddress))
        )
    }

    func test_submitButtonTap_createsMail_andPresentsMailView() {
        let image = UIImage(systemName: "pencil")!
        let store = TestStore(
            initialState: Report(
                uuid: fixedUUID(),
                images: ImagesViewState(
                    showImagePicker: false,
                    storedPhotos: [StorableImage(uiImage: image)!],
                    coordinateFromImagePicker: .zero
                ),
                contact: .empty,
                district: districs[0],
                date: fixedDate,
                description: .init(),
                location: LocationViewState(
                    locationOption: .currentLocation,
                    isMapExpanded: false,
                    isResolvingAddress: false,
                    resolvedAddress: .init(
                        street: Report.preview.contact.address.street,
                        city: Report.preview.contact.address.city,
                        postalCode: Report.preview.contact.address.postalCode
                    ),
                    userLocationState: .init()
                )
            ),
            reducer: reportReducer,
            environment: ReportEnvironment(
                mainQueue: DispatchQueue.immediate.eraseToAnyScheduler(),
                locationManager: LocationManager.unimplemented(),
                placeService: .noop,
                regulatoryOfficeMapper: .noop
            )
        )

        store.assert(
            .send(ReportAction.mail(.submitButtonTapped)),
            .receive(ReportAction.mail(.presentMailContentView(true))) {
                $0.mail.isPresentingMailContent = true
            }
        )
    }

    func test_locationOptionCurrentLocation_shouldTriggerResolveLocation_andSetDistrict() {
        let store = TestStore(
            initialState: report,
            reducer: reportReducer,
            environment: ReportEnvironment(
                mainQueue: DispatchQueue.immediate.eraseToAnyScheduler(),
                locationManager: LocationManager.unimplemented(),
                placeService: .noop,
                regulatoryOfficeMapper: .live(districs)
            )
        )

        let expectedAddress = GeoAddress(
            street: "Teststrasse 5",
            city: "Berlin",
            postalCode: "12437"
        )

        store.assert(
            .send(.location(.resolveAddressFinished(.success([expectedAddress])))) {
                $0.location.resolvedAddress = expectedAddress
            },
            .receive(.mapGeoAddressToDistrict(expectedAddress)),
            .receive(.mapDistrictFinished(.success(districs[0]))) {
                $0.district = self.districs[0]
            }
        )
    }

    func test_imagesAction_shouldNotTriggerResolveLocation_whenLocationisNotMappable() {
        let store = TestStore(
            initialState: report,
            reducer: reportReducer,
            environment: ReportEnvironment(
                mainQueue: DispatchQueue.immediate.eraseToAnyScheduler(),
                locationManager: LocationManager.unimplemented(),
                placeService: .noop,
                regulatoryOfficeMapper: .live(districs)
            )
        )

        let expectedAddress = GeoAddress(
            street: "Teststrasse 5",
            city: "Hamburg",
            postalCode: "20099"
        )

        store.assert(
            .send(.location(.resolveAddressFinished(.success([expectedAddress])))) {
                $0.location.resolvedAddress = expectedAddress
            },
            .receive(.mapGeoAddressToDistrict(expectedAddress)),
            .receive(.mapDistrictFinished(.failure(.unableToMatchRegularityOffice))) {
                $0.district = nil
            }
        )
    }

    func test_imagesAction_shouldFail_whenOnlyPostalCodeEnteredManually() {
        let store = TestStore(
            initialState: Report(
                uuid: fixedUUID(),
                images: ImagesViewState(
                    showImagePicker: false,
                    storedPhotos: [],
                    coordinateFromImagePicker: .zero
                ),
                contact: .empty,
                district: nil,
                date: fixedDate,
                description: .init(),
                location: .init(
                    locationOption: .manual,
                    isMapExpanded: false,
                    isResolvingAddress: false,
                    resolvedAddress: .init(
                        street: "",
                        city: "",
                        postalCode: "1243"
                    ),
                    userLocationState: .init()
                )
            ),
            reducer: reportReducer,
            environment: ReportEnvironment(
                mainQueue: DispatchQueue.immediate.eraseToAnyScheduler(),
                locationManager: LocationManager.unimplemented(),
                placeService: .noop,
                regulatoryOfficeMapper: .live(districs)
            )
        )

        let expectedAddress = GeoAddress(
            street: "",
            city: "",
            postalCode: "12437"
        )

        let newPostalCode = "12437"
        store.assert(
            .send(.location(.updateGeoAddressPostalCode(newPostalCode))) {
                $0.location.resolvedAddress = GeoAddress(
                    street: "",
                    city: "",
                    postalCode: newPostalCode
                )
            },
            .receive(.mapGeoAddressToDistrict(expectedAddress)),
            .receive(.mapDistrictFinished(.failure(.unableToMatchRegularityOffice))) {
                $0.district = nil
            }
        )
    }

    func test_imagesAction_shouldSucceed_whenOnlyPostalCodeAndCityEnteredManually() {
        let store = TestStore(
            initialState: Report(
                uuid: fixedUUID(),
                images: ImagesViewState(
                    showImagePicker: false,
                    storedPhotos: [],
                    coordinateFromImagePicker: .zero
                ),
                contact: .empty,
                district: nil,
                date: fixedDate,
                description: .init(),
                location: .init(
                    locationOption: .manual,
                    isMapExpanded: false,
                    isResolvingAddress: false,
                    resolvedAddress: .init(
                        street: "",
                        city: "Berlin",
                        postalCode: "1243"
                    ),
                    userLocationState: .init()
                )
            ),
            reducer: reportReducer,
            environment: ReportEnvironment(
                mainQueue: DispatchQueue.immediate.eraseToAnyScheduler(),
                locationManager: LocationManager.unimplemented(),
                placeService: .noop,
                regulatoryOfficeMapper: .live(districs)
            )
        )

        let expectedAddress = GeoAddress(
            street: "",
            city: "Berlin",
            postalCode: "12437"
        )

        let newPostalCode = "12437"
        store.assert(
            .send(.location(.updateGeoAddressPostalCode(newPostalCode))) {
                $0.location.resolvedAddress = expectedAddress
            },
            .receive(.mapGeoAddressToDistrict(expectedAddress)),
            .receive(.mapDistrictFinished(.success(districs[0]))) {
                $0.district = self.districs[0]
            }
        )
    }

    func test_removeImage_shouldSetResolvedCoordinateToNil_whenPhotosIsEmptyAfterDelete() {
        let images = [StorableImage(id: fixedUUID(), uiImage: UIImage(systemName: "pencil")!)]
        let coordinate = CLLocationCoordinate2D(latitude: 23.21, longitude: 67.76)

        let store = TestStore(
            initialState: Report(
                uuid: fixedUUID(),
                images: ImagesViewState(
                    showImagePicker: false,
                    storedPhotos: images,
                    coordinateFromImagePicker: coordinate
                ),
                contact: .empty,
                district: nil,
                date: fixedDate,
                description: .init(),
                location: .init(
                    locationOption: .fromPhotos,
                    isMapExpanded: false,
                    isResolvingAddress: false,
                    resolvedAddress: .init(
                        street: "TestStrasse 3",
                        city: "Berlin",
                        postalCode: "1243"
                    ),
                    userLocationState: .init()
                )
            ),
            reducer: reportReducer,
            environment: ReportEnvironment(
                mainQueue: DispatchQueue.immediate.eraseToAnyScheduler(),
                locationManager: LocationManager.unimplemented(),
                placeService: .noop,
                regulatoryOfficeMapper: .live(districs)
            )
        )

        store.assert(
            .send(.images(.image(id: fixedUUID(), action: .removePhoto))) {
                $0.images.storedPhotos = []
                $0.images.coordinateFromImagePicker = nil
            }
        )
    }

    func test_resetDataButtonTap_shouldPresentAnAlert() {
        let store = TestStore(
            initialState: Report(
                uuid: fixedUUID(),
                images: .init(),
                contact: .empty,
                district: nil,
                date: fixedDate,
                description: .init(),
                location: .init(
                    locationOption: .fromPhotos,
                    isMapExpanded: false,
                    isResolvingAddress: false,
                    resolvedAddress: .init(
                        street: "TestStrasse 3",
                        city: "Berlin",
                        postalCode: "1243"
                    ),
                    userLocationState: .init()
                )
            ),
            reducer: reportReducer,
            environment: ReportEnvironment(
                mainQueue: DispatchQueue.immediate.eraseToAnyScheduler(),
                locationManager: LocationManager.unimplemented(),
                placeService: .noop,
                regulatoryOfficeMapper: .noop
            )
        )

        store.assert(
            .send(.resetButtonTapped) {
                $0.alert = .resetReportAlert
            }
        )
    }

    func test_setShowContact_shouldPresentAnAlert() {
        let store = TestStore(
            initialState: Report(
                uuid: fixedUUID(),
                images: .init(),
                contact: .empty,
                district: nil,
                date: fixedDate,
                description: .init(),
                location: .init(
                    locationOption: .fromPhotos,
                    isMapExpanded: false,
                    isResolvingAddress: false,
                    resolvedAddress: .init(
                        street: "TestStrasse 3",
                        city: "Berlin",
                        postalCode: "1243"
                    ),
                    userLocationState: .init()
                )
            ),
            reducer: reportReducer,
            environment: ReportEnvironment(
                mainQueue: DispatchQueue.immediate.eraseToAnyScheduler(),
                locationManager: LocationManager.unimplemented(),
                placeService: .noop,
                regulatoryOfficeMapper: .noop
            )
        )

        store.assert(
            .send(.setShowEditContact(true)) {
                $0.showEditContact = true
            }
        )
    }

    func test_setShowDescription_shouldPresentAnAlert() {
        let store = TestStore(
            initialState: Report(
                uuid: fixedUUID(),
                images: .init(),
                contact: .empty,
                district: nil,
                date: fixedDate,
                description: .init(),
                location: .init(
                    locationOption: .fromPhotos,
                    isMapExpanded: false,
                    isResolvingAddress: false,
                    resolvedAddress: .init(
                        street: "TestStrasse 3",
                        city: "Berlin",
                        postalCode: "1243"
                    ),
                    userLocationState: .init()
                )
            ),
            reducer: reportReducer,
            environment: ReportEnvironment(
                mainQueue: DispatchQueue.immediate.eraseToAnyScheduler(),
                locationManager: LocationManager.unimplemented(),
                placeService: .noop,
                regulatoryOfficeMapper: .noop
            )
        )

        store.assert(
            .send(.setShowEditDescription(true)) {
                $0.showEditDescription = true
            }
        )
    }
}
