# Logly

A lightweight, modular, and concurrency-safe logging system for Swift projects. Designed for macOS and iOS applications, it supports log levels, structured formatting, log rotation, file output, asynchronous logging, and crash/signal handling – all configurable at runtime.

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

You can define your own commonly used log categories in your app:

```swift
// MyApp+Logger.swift (inside your app target)

import os
import Logly

extension Logger {
    static let network = Logger.custom(category: "Network")
    static let authentication = Logger.custom(category: "Authentication")
    static let database = Logger.custom(category: "Database")
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

---

## 📄 License

MIT License

---

## 👨‍💻 Author

Built with ❤️ in Swift for scalable and safe application logging.
