# Sentry Integration

Send Logly's errors and crashes to Sentry as a reusable transport layer.

## Overview

Logly's core stays dependency-free. The optional `LoglySentry` product adds a
Sentry backend that activates only when a Sentry URL (DSN) is configured.

- **URL set** → Sentry starts (crash handler on) and a sink forwards events.
- **URL `nil`/empty** → Sentry stays fully disabled, with no overhead.

## Activate

`LoglySentry` lives behind the `Sentry` package trait (off by default), so Logly-only consumers never fetch `sentry-cocoa`. To use the Sentry backend, enable the trait where you declare the dependency:

```swift
.package(url: "https://github.com/Flexible-Universe/Logly", from: "x.y.z",
         traits: ["Sentry"])
```

```swift
import Logly
import LoglySentry

// As early as possible at app start:
LoggerConfiguration.shared.sentryURL = "https://…@sentry.io/123"  // or nil
LoglySentry.bootstrap(scrub: Redaction.scrub)  // scrub is optional
```

`bootstrap()` is idempotent and a no-op without a URL.

## Attach the underlying error

Pass the real `Error` so Sentry produces grouped exception events instead of
plain message events:

```swift
do {
    try store.save()
} catch {
    Logger.database.error("save failed", error: error)  // → Sentry exception
}
```

Existing calls without an error keep working and become message events.

## Level mapping

| Logly level | Sentry |
|---|---|
| `.fault` | captured exception (with `Error`) or fatal message event |
| `.error` | captured exception (with `Error`) or error message event |
| `.warning` | breadcrumb (warning) |
| `.info` / `.debug` | breadcrumb (info) |

## Crash handling

`bootstrap()` sets `enableCrashHandler = true`; Sentry owns crashes. Do **not**
also call ``LoggerCrashHandler/install()`` — two handlers would fight over the
same POSIX signals.

## Privacy (GDPR)

Supply an app-specific `scrub` closure — it is wired to Sentry's `beforeSend`
and must strip PII (license plates, GPS, account names, file paths) before
events are sent. Defaults are privacy-conservative: `sendDefaultPii = false`,
`tracesSampleRate = 0`. Choose an EU data region in Sentry.
