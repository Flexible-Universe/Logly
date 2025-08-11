# Configuration

Learn how to configure Logly for different environments and use cases.

## Overview

Logly supports both synchronous and asynchronous configuration. Choose the style that fits your app architecture and requirements.

## Synchronous Configuration

Recommended for existing apps or when immediate configuration is needed:

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

## Asynchronous Configuration

For apps using async/await patterns:

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

## Environment-Specific Configuration

Configure Logly differently for development, testing, and production:

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

## Configuration Options

### Log Levels
- ``LogLevel/debug``: Detailed diagnostic information
- ``LogLevel/info``: General informational messages
- ``LogLevel/warning``: Warning conditions
- ``LogLevel/error``: Error conditions
- ``LogLevel/fault``: Critical faults

### File Management
- `logToFile`: Enable/disable file logging
- `logFilePath`: Path for log files
- `maxFileSizeInBytes`: Maximum file size before rotation
- `maxLogAge`: Maximum file age before rotation
- `maxRotatedFiles`: Number of rotated files to keep

### Performance Options
- `asynchronousLogging`: Enable background logging queue
- `enableANSIColors`: Colorized console output

## See Also

- ``LoggerConfiguration``
- <doc:Usage>
- <doc:LogRotation>