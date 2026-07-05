//
//  SentryReporting.swift
//  LoglySentry
//
//  Copyright © 2026 Flexible-Universe. All rights reserved.
//

#if canImport(Sentry)
import Foundation
import Sentry

/// The set of Sentry effects LoglySentry performs. Abstracted behind a seam so
/// the activation and emit paths can be tested with a spy instead of the
/// process-global `SentrySDK`. Internal — consumers never inject a reporter.
protocol SentryReporting: Sendable {
    var isEnabled: Bool { get }
    func start(_ configure: @escaping (Options) -> Void)
    func captureError(_ error: Error, category: String)
    func captureMessage(level: SentryLevel, category: String, message: String)
    func addBreadcrumb(level: SentryLevel, category: String, message: String)
}

/// Default `SentryReporting` that forwards to the real `SentrySDK`.
struct SentrySDKReporter: SentryReporting {
    var isEnabled: Bool { SentrySDK.isEnabled }

    func start(_ configure: @escaping (Options) -> Void) {
        SentrySDK.start(configureOptions: configure)
    }

    func captureError(_ error: Error, category: String) {
        SentrySDK.capture(error: error) { scope in
            scope.setTag(value: category, key: "category")
        }
    }

    func captureMessage(level: SentryLevel, category: String, message: String) {
        let event = Event(level: level)
        event.message = SentryMessage(formatted: message)
        event.tags = ["category": category]
        SentrySDK.capture(event: event)
    }

    func addBreadcrumb(level: SentryLevel, category: String, message: String) {
        let crumb = Breadcrumb(level: level, category: category)
        crumb.message = message
        SentrySDK.addBreadcrumb(crumb)
    }
}
#endif
