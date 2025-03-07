// Created for weg-li in 2021.

import Combine
import ComposableArchitecture
import ComposableCoreLocation
import Contacts
import Foundation
import MapKit
import UIKit

// MARK: - AppState

struct HomeState: Equatable {
    /// Settings
    var settings = SettingsState(contact: .empty)

    /// Reports a user has sent
    var reports: [Report] = []

    /// Holds a report that has not been stored or sent via mail
    private var _storedReport: Report?
    var reportDraft: Report {
        get {
            guard let report = _storedReport else {
                return Report(images: .init(), contact: settings.contact, date: Date.init)
            }
            return report
        }
        set {
            _storedReport = newValue
        }
    }

    var showReportWizard = false
}

// MARK: - AppAction

enum HomeAction: Equatable {
    case settings(SettingsAction)
    case report(ReportAction)
    case showReportWizard(Bool)
    case reportSaved
    case onAppear
}

// MARK: - Environment

struct HomeEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue>
    var userDefaultsClient: UserDefaultsClient
    var imageConverter: ImageConverter
}

/// Reducer handling actions from the HomeView and combining it with the reducers from descending screens.
let homeReducer = Reducer<HomeState, HomeAction, HomeEnvironment>.combine(
    reportReducer
        .pullback(
            state: \.reportDraft,
            action: /HomeAction.report,
            environment: { environment in
                ReportEnvironment(
                    mainQueue: environment.mainQueue,
                    locationManager: .live,
                    placeService: .live,
                    regulatoryOfficeMapper: .live()
                )
            }
        ),
    settingsReducer.pullback(
        state: \.settings,
        action: /HomeAction.settings,
        environment: { _ in SettingsEnvironment(uiApplicationClient: .live) }
    ),
    Reducer { state, action, environment in
        switch action {
        // restore state from userdefaults
        case .onAppear:
            if let contact = environment.userDefaultsClient.contact {
                state.settings = SettingsState(contact: contact)
            }
            state.reports = environment.userDefaultsClient.reports
            return .none
        // After the EditDescriptionView disappeared the contact data needs to be synced with the reportDraft
        // and stored.
        case let .settings(settingsAction):
            switch settingsAction {
            case .contact(.onDisappear):
                state.reportDraft.contact = state.settings.contact
                return environment.userDefaultsClient.setContact(state.settings.contact)
                    .fireAndForget()
            default:
                return .none
            }
        // After the emailResult reports the mail has been sent the report will be stored.
        case let .report(reportAction):
            switch reportAction {
            case let .mail(mailAction):
                switch mailAction {
                case let .setMailResult(result):
                    guard let mailComposerResult = result else {
                        return .none
                    }
                    switch mailComposerResult {
                    case .sent:
                        state.reports.append(state.reportDraft)

                        return Effect.concatenate(
                            environment.userDefaultsClient.setReports(state.reports)
                                .fireAndForget(),
                            Effect(value: HomeAction.reportSaved)
                        )
                    default:
                        return .none
                    }
                default:
                    return .none
                }
            case .contact:
                // sync contact with draftReport contact
                state.settings.contact = state.reportDraft.contact
                return .none
            case .resetConfirmButtonTapped:
                state.reportDraft = Report(images: .init(), contact: state.settings.contact, date: Date.init)
                return .none
            default:
                return .none
            }
        case let .showReportWizard(value):
            state.showReportWizard = value
            return .none
        // Reset report draft after it was .
        case .reportSaved:
            state.reportDraft = Report(images: .init(), contact: state.settings.contact, date: Date.init)
            return .none
        }
    }
)

extension HomeState {
    static let preview = HomeState()

    // init for previews
    init(reports: [Report]) {
        self.init()
        self.reports = reports
    }
}

typealias Address = CNPostalAddress
