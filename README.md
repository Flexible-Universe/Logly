# Logly

A lightweight, modular, and concurrency-safe logging system for Swift projects. Designed for macOS and iOS applications, it supports log levels, structured formatting, log rotation, file output, asynchronous logging, and crash/signal handling – all configurable at runtime.

> **Swift Package Documentation**: For complete API documentation with examples, build and browse the DocC documentation using `swift package generate-documentation --target Logly` or view it in Xcode.

## Quick Start

```swift
import Logly

// Basic setup
let logger = Logger.custom(category: "MyApp")
logger.info("Application started")

// Configure for production
let config = LoggerConfiguration.shared
config.currentLogLevel = .warning
config.logToFile = true
config.logFilePath = documentsDirectory.appendingPathComponent("app.log")

// Enable crash handling
LoggerCrashHandler.install()
```

---

## 🚀 Features

- ✅ **Log levels**: `debug`, `info`, `warning`, `error`, `fault`
- ✅ **Structured formatting** with customizable format strings and timestamps
- ✅ **Asynchronous logging** to prevent UI blocking
- ✅ **File output** with automatic log rotation
- ✅ **Log rotation** by file size and file age
- ✅ **Automatic cleanup** of old rotated log files
- ✅ **ANSI color support** for console output
- ✅ **Crash and signal handling** with automatic logging
- ✅ **Thread-safe configuration** with concurrent queue design
- ✅ **Dual API**: Both synchronous and async/await support
- ✅ **Modular Swift Package** design for easy integration

---

## 📦 Installation

### Swift Package Manager (SPM)

1. Open your project in Xcode
2. Go to `File > Add Packages...`
3. Paste the URL of this repository
4. Add `Logly` to your target

**Minimum Requirements:**

- iOS 16.0+ or macOS 13.0+
- Swift 6.1+

---

## 🧠 How it Works

Logly provides a `LogCategory` structure that wraps Apple's `os.Logger` with additional features. The system is built around:

- **Thread-safe configuration** (`LoggerConfiguration`) using concurrent queues with barrier writes
- **Dual API support**: Use either synchronous or async/await patterns
- **Asynchronous logging option** using dedicated queues to avoid blocking
- **Automatic log rotation** when files exceed size or age limits
- **Crash/signal handling** that automatically logs crashes and signals
- **Customizable formatting** with token-based format strings

---

## 🛠 Configuration

Logly supports both synchronous and asynchronous configuration. Choose the style that fits your app:

### Synchronous Configuration (Recommended for existing apps)

```swift
import Logly

// Configure logging (completely synchronous)
let config = LoggerConfiguration.shared

// Set log level
config.currentLogLevel = .info

// Enable file logging
config.logToFile = true
config.logFilePath = FileManager.default
    .urls(for: .documentDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("my_logs/app.log")

// Customize format
config.logFormat = "{timestamp} - {level} - {category} - {file}:{line} - {message}"

// Configure rotation
config.maxFileSizeInBytes = 5 * 1024 * 1024 // 5 MB
config.maxLogAge = 60 * 60 * 24 // 24 hours
config.maxRotatedFiles = 5

// Enable asynchronous logging
config.asynchronousLogging = true

// Enable ANSI colors for console
config.enableANSIColors = true

// Optional: Install crash and signal handlers
LoggerCrashHandler.install()
```

### Asynchronous Configuration (For async/await apps)

```swift
import Logly

// Configure logging with async/await
Task {
    let config = LoggerConfiguration.shared
    
    // Set log level
    await config.setCurrentLogLevel(.info)
    
    // Enable file logging
    await config.setLogToFile(true)
    await config.setLogFilePath(
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("my_logs/app.log")
    )
    
    // Customize format
    await config.setLogFormat("{timestamp} - {level} - {category} - {file}:{line} - {message}")
    
    // Configure rotation
    await config.setMaxFileSizeInBytes(5 * 1024 * 1024) // 5 MB
    await config.setMaxLogAge(60 * 60 * 24) // 24 hours
    await config.setMaxRotatedFiles(5)
    
    // Enable asynchronous logging
    await config.setAsynchronousLogging(true)
    
    // Enable ANSI colors for console
    await config.setEnableANSIColors(true)
}

// Optional: Install crash and signal handlers
LoggerCrashHandler.install()
```

---

## 🧪 Usage

### 🧩 Define Your Own Log Categories

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

### Synchronous Logging (Recommended for existing apps)

All logging methods have synchronous versions that work immediately:

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

### Asynchronous Logging (For async/await apps)

All logging methods also support async/await:

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

### Real-World Usage Examples

#### Network Layer Logging

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

#### Database Operations

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

### Thread Safety

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

#### SwiftUI Integration

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

---

## 🎨 Format Customization

Logly supports customizable log format strings with the following tokens:

- `{timestamp}` - ISO8601 formatted timestamp
- `{level}` - Log level (padded to configured width)
- `{category}` - Category name (padded to configured width)
- `{file}` - Filename (without path)
- `{line}` - Line number
- `{message}` - The actual log message

```swift
// Synchronous format configuration
config.logFormat = "[{timestamp}] {level} {category} {file}:{line} - {message}"
config.logLevelWidth = 7  // Pad level to 7 characters
config.categoryWidth = 12 // Pad category to 12 characters

// Or async format configuration
await config.setLogFormat("[{timestamp}] {level} {category} {file}:{line} - {message}")
await config.setLogLevelWidth(7)  // Pad level to 7 characters
await config.setCategoryWidth(12) // Pad category to 12 characters
```

---

## 📂 Output Example

```plaintext
2025-01-20T10:12:45Z - INFO    - Network     - APISession.swift:45 - Fetching data from API
2025-01-20T10:12:46Z - WARNING - Authentication - AuthManager.swift:33 - Token is about to expire
2025-01-20T10:12:47Z - ERROR   - Database   - DataStore.swift:78 - Failed to fetch records
```

---

## 🔄 Log Rotation

Logly automatically rotates log files based on:

- **File size**: When the log file exceeds the configured maximum size
- **File age**: When the log file is older than the configured maximum age

**Rotation behavior:**

- Old files are renamed with timestamps: `app_2025-01-20T12-30-00Z.log`
- Only the most recent rotated files are kept (configurable limit)
- Rotation checks happen before each write operation

```swift
// Synchronous configuration
config.maxFileSizeInBytes = 5 * 1024 * 1024 // 5 MB
config.maxLogAge = 60 * 60 * 24 // 24 hours
config.maxRotatedFiles = 5 // Keep 5 rotated files

// Or async configuration
await config.setMaxFileSizeInBytes(5 * 1024 * 1024) // 5 MB
await config.setMaxLogAge(60 * 60 * 24) // 24 hours
await config.setMaxRotatedFiles(5) // Keep 5 rotated files
```

---

## 💥 Crash and Signal Handling

Logly can automatically capture and log crashes and signals:

```swift
// Install crash handlers (call once at app startup)
LoggerCrashHandler.install()
```

This will automatically log:

- **Uncaught exceptions** with stack traces
- **System signals** (SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE)

Crash logs are written to a special "Crash" and "Signal" category.

---

## ⚡ Concurrency & Performance

- **Thread-safe configuration**: All settings are managed by concurrent queues with barrier writes
- **Dual API support**: Choose between synchronous or async/await patterns
- **Asynchronous logging option**: Uses dedicated background queues when enabled
- **Concurrent reads**: Multiple threads can read configuration simultaneously
- **Serialized writes**: Configuration changes are thread-safe

```swift
// Synchronous API - works from any thread
let currentLevel = LoggerConfiguration.shared.currentLogLevel
LoggerConfiguration.shared.currentLogLevel = .error
logger.info("This works from any thread")

// Async API - works in async contexts
Task {
    let currentLevel = await LoggerConfiguration.shared.getCurrentLogLevel()
    await LoggerConfiguration.shared.setCurrentLogLevel(.error)
    await logger.info("This works in async contexts")
}

// Asynchronous processing happens internally when enabled
LoggerConfiguration.shared.asynchronousLogging = true
```

---

## 🎨 ANSI Color Support

Console output supports ANSI colors for better readability:

- **Debug**: Cyan
- **Info**: Green  
- **Warning**: Yellow
- **Error**: Red
- **Fault**: Bright Red

Colors can be enabled/disabled:

```swift
// Synchronous
config.enableANSIColors = true // Default: true

// Or async
await config.setEnableANSIColors(true) // Default: true
```

---

## 🔧 Advanced Configuration

### API Choice Guide

**Use Synchronous API when:**

- Integrating into existing codebases without async/await
- Simple setup and configuration
- Immediate execution is preferred

**Use Async API when:**

- Your app already uses async/await patterns
- Working in async contexts (Tasks, async functions)
- Following modern Swift concurrency practices

### Asynchronous vs Synchronous Logging

```swift
// Synchronous logging (blocks current thread until log is written)
config.asynchronousLogging = false
logger.info("This blocks until written to file")

// Asynchronous logging (returns immediately, logging happens in background)
config.asynchronousLogging = true
logger.info("This returns immediately")
```

### Custom Log Paths

```swift
// Custom log directory (synchronous)
let logsDirectory = FileManager.default
    .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("MyApp/Logs")

// Create directory if needed
try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

config.logFilePath = logsDirectory.appendingPathComponent("app.log")

// Or async version
await config.setLogFilePath(logsDirectory.appendingPathComponent("app.log"))
```

#### Environment-Specific Configuration

```swift
class LoggingSetup {
    static func configure() {
        let config = LoggerConfiguration.shared
        
        #if DEBUG
        // Development settings
        config.currentLogLevel = .debug
        config.enableANSIColors = true
        config.logToFile = true
        
        // Use Documents directory for easy access during development
        let documentsPath = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        config.logFilePath = documentsPath.appendingPathComponent("debug.log")
        
        #elseif TESTING
        // Testing settings - minimal logging
        config.currentLogLevel = .error
        config.logToFile = false
        config.enableANSIColors = false
        
        #else
        // Production settings
        config.currentLogLevel = .warning
        config.enableANSIColors = false
        config.asynchronousLogging = true
        
        // Use Application Support directory for production logs
        let appSupportPath = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "MyApp")
            .appendingPathComponent("Logs")
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(
            at: appSupportPath,
            withIntermediateDirectories: true
        )
        
        config.logFilePath = appSupportPath.appendingPathComponent("production.log")
        
        // Stricter rotation for production
        config.maxFileSizeInBytes = 2 * 1024 * 1024  // 2MB
        config.maxLogAge = 60 * 60 * 12               // 12 hours
        config.maxRotatedFiles = 10
        #endif
        
        // Always install crash handler
        LoggerCrashHandler.install()
    }
}
```

---

## 📚 Documentation

### DocC Documentation

Generate comprehensive documentation with code examples:

```bash
# Generate documentation
swift package generate-documentation --target Logly

# Preview documentation
swift package --disable-sandbox preview-documentation --target Logly
```

### Xcode Documentation

1. Open your project in Xcode
2. Go to **Product → Build Documentation**
3. Browse the documentation in Xcode's Documentation window

### Key Documentation Topics

- **Getting Started**: Quick setup and basic usage
- **Configuration**: Detailed configuration options and examples
- **Log Levels**: Understanding severity levels and filtering
- **File Management**: Log rotation, cleanup, and storage
- **Async Support**: Using Logly with Swift Concurrency
- **Performance**: Optimization tips and best practices
- **Troubleshooting**: Common issues and solutions

---

## 🔧 Advanced Usage

### Custom Formatting for Different Environments

```swift
func setupCustomFormatting() {
    let config = LoggerConfiguration.shared
    
    #if DEBUG
    // Detailed format for development
    config.logFormat = "[{timestamp}] {level} {category} {file}:{line} - {message}"
    config.logLevelWidth = 8
    config.categoryWidth = 15
    #else
    // Concise format for production
    config.logFormat = "{timestamp} {level} {message}"
    config.logLevelWidth = 5
    #endif
}
```

### Performance Monitoring Integration

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

### Log Analysis and Monitoring

```swift
class LogAnalyzer {
    static func extractCriticalErrors(from logFile: URL) -> [String] {
        guard let content = try? String(contentsOf: logFile) else {
            return []
        }
        
        return content
            .components(separatedBy: .newlines)
            .filter { line in
                line.contains("ERROR") || line.contains("FAULT")
            }
    }
    
    static func getLogFileURLs() -> [URL] {
        let config = LoggerConfiguration.shared
        let logDirectory = config.logFilePath.deletingLastPathComponent()
        
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: logDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: []
        ) else {
            return []
        }
        
        return files
            .filter { $0.pathExtension == "log" }
            .sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }
    }
}
```

---

## 📄 License

MIT License

---

## 👨‍💻 Author

Built with ❤️ in Swift for scalable and safe application logging.