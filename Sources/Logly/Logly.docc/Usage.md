# Usage

Learn how to use Logly effectively in your Swift applications.

## Overview

Logly provides both synchronous and asynchronous APIs for logging. Choose the approach that best fits your application's architecture.

## Defining Log Categories

Create organized logging categories for different parts of your application:

```swift
// MyApp+Logger.swift (inside your app target)

import os
import Logly

extension Logger {
    static let network = Logger.custom(category: "Network")
    static let authentication = Logger.custom(category: "Authentication")
    static let database = Logger.custom(category: "Database")
    static let ui = Logger.custom(category: "UI")
    static let analytics = Logger.custom(
        subsystem: "com.myapp.analytics",
        category: "Events"
    )
}
```

## Synchronous Logging

Recommended for existing apps that don't use async/await extensively:

```swift
// Using predefined categories
Logger.network.debug("Request sent to API")
Logger.authentication.warning("Token is about to expire")
Logger.database.error("Failed to fetch records")

// Custom category with custom subsystem
let analyticsLogger = Logger.custom(subsystem: "com.myapp.analytics", category: "Analytics")
analyticsLogger.info("User tapped on 'Start'")

// Available log levels
logger.debug("Debug information")
logger.info("General information")
logger.warning("Warning message")
logger.error("Error occurred")
logger.fault("Critical fault")
```

## Asynchronous Logging

For apps using async/await patterns:

```swift
// Using predefined categories with await
await Logger.network.debug("Request sent to API")
await Logger.authentication.warning("Token is about to expire")
await Logger.database.error("Failed to fetch records")

// Custom category with custom subsystem
let analyticsLogger = Logger.custom(subsystem: "com.myapp.analytics", category: "Analytics")
await analyticsLogger.info("User tapped on 'Start'")

// Available log levels
await logger.debug("Debug information")
await logger.info("General information")
await logger.warning("Warning message")
await logger.error("Error occurred")
await logger.fault("Critical fault")
```

## Real-World Examples

### Network Layer Logging

```swift
class APIClient {
    private let logger = Logger.custom(category: "NetworkClient")
    
    func fetchData(from url: URL) async throws -> Data {
        logger.info("Starting request to \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                logger.info("Request completed with status \(httpResponse.statusCode)")
                
                if httpResponse.statusCode >= 400 {
                    logger.error("HTTP error \(httpResponse.statusCode) for \(url)")
                    throw APIError.httpError(httpResponse.statusCode)
                }
            }
            
            return data
        } catch {
            logger.error("Network request failed: \(error.localizedDescription)")
            throw error
        }
    }
}
```

### Database Operations

```swift
class DataManager {
    private let logger = Logger.custom(category: "Database")
    
    func saveUser(_ user: User) {
        logger.debug("Attempting to save user with ID: \(user.id)")
        
        do {
            try persistentContainer.viewContext.save()
            logger.info("Successfully saved user: \(user.username)")
        } catch {
            logger.error("Failed to save user: \(error.localizedDescription)")
            // Handle error...
        }
    }
    
    func migrateDatabase() {
        logger.warning("Starting database migration - this may take a while")
        
        // Migration logic...
        
        logger.info("Database migration completed successfully")
    }
}
```

### SwiftUI Integration

```swift
struct ContentView: View {
    private let logger = Logger.custom(category: "UI")
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading...")
                    .onAppear {
                        logger.debug("Loading indicator appeared")
                    }
            } else {
                Text("Content loaded")
                    .onAppear {
                        logger.info("Content view displayed")
                    }
            }
        }
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        logger.info("Starting data load")
        isLoading = true
        
        defer {
            isLoading = false
            logger.debug("Data loading completed, UI updated")
        }
        
        do {
            // Simulate async work
            try await Task.sleep(for: .seconds(2))
            await logger.info("Data loaded successfully")
        } catch {
            await logger.error("Failed to load data: \(error)")
        }
    }
}
```

## Thread Safety

All logging operations are thread-safe and can be called from any queue:

```swift
// Safe to call from any thread (both sync and async versions)
DispatchQueue.global().async {
    Logger.network.info("Background operation completed")
}

DispatchQueue.main.async {
    Logger.network.debug("UI update finished")
}

// Also works in async contexts
Task {
    await Logger.network.info("Async task completed")
}
```

## Performance Monitoring

```swift
class PerformanceLogger {
    private let logger = Logger.custom(category: "Performance")
    
    func measureAndLog<T>(_ operation: String, _ block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.debug("Starting operation: \(operation)")
        
        let result = try block()
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        if duration > 1.0 {
            logger.warning("Slow operation '\(operation)' took \(String(format: "%.2f", duration))s")
        } else {
            logger.info("Operation '\(operation)' completed in \(String(format: "%.2f", duration))s")
        }
        
        return result
    }
}

// Usage
let performanceLogger = PerformanceLogger()
let result = performanceLogger.measureAndLog("Database query") {
    return database.fetchUsers()
}
```

## See Also

- ``LogCategory``
- ``Logger``
- <doc:Configuration>
- <doc:FormatCustomization>