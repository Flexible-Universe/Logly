# Crash Handling

Learn how to automatically capture and log crashes and system signals.

## Overview

Logly can automatically capture uncaught exceptions and system signals, logging them with detailed information to help with debugging and crash analysis.

## Installation

Install crash handlers once at application startup:

```swift
import Logly

// Install both exception and signal handlers
LoggerCrashHandler.install()
```

## What Gets Captured

### Uncaught Exceptions
- Exception name and reason
- Complete stack trace
- Thread information
- Timestamp of the crash

### System Signals
- `SIGABRT` - Abnormal termination
- `SIGILL` - Illegal instruction  
- `SIGSEGV` - Segmentation violation
- `SIGFPE` - Floating-point exception
- `SIGBUS` - Bus error
- `SIGPIPE` - Broken pipe

## Log Categories

Crash information is logged to specific categories:

- **"Crash"** - For uncaught exceptions
- **"Signal"** - For system signals

This allows you to filter and analyze crash logs separately from your application logs.

## Configuration

Crash handlers work with your existing Logly configuration:

```swift
// Configure logging first
let config = LoggerConfiguration.shared
config.logToFile = true
config.logFilePath = documentsDirectory.appendingPathComponent("app.log")

// Then install crash handlers
LoggerCrashHandler.install()
```

## Example Crash Log Output

### Uncaught Exception
```
2025-01-20T10:15:30Z - FAULT - Crash - AppDelegate.swift:45 - Uncaught exception: NSInvalidArgumentException
Reason: [__NSArrayM insertObject:atIndex:]: object cannot be nil
Stack trace:
  0   CoreFoundation    0x00007fff2040a57c __exceptionPreprocess + 242
  1   libobjc.A.dylib   0x00007fff20318eb4 objc_exception_throw + 48
  2   MyApp            0x000000010a234567 -[MyViewController processData:] + 123
  ...
```

### System Signal
```
2025-01-20T10:15:35Z - FAULT - Signal - Unknown:0 - Received signal: SIGSEGV (Segmentation violation)
Signal code: 1
Signal address: 0x0000000000000000
Thread ID: 123456789
```

## Advanced Usage

### Custom Crash Logging

You can also manually log crash information:

```swift
// Manual crash logging
let crashLogger = Logger.custom(category: "CustomCrash")
crashLogger.fault("Critical system error detected")

// With async API
await crashLogger.fault("Critical system error detected")
```

### Crash Analysis

Extract crash logs for analysis:

```swift
class CrashAnalyzer {
    static func extractCrashLogs(from logFile: URL) -> [String] {
        guard let content = try? String(contentsOf: logFile) else {
            return []
        }
        
        return content
            .components(separatedBy: .newlines)
            .filter { line in
                line.contains("FAULT") && 
                (line.contains("- Crash -") || line.contains("- Signal -"))
            }
    }
    
    static func hasCrashLogs() -> Bool {
        let config = LoggerConfiguration.shared
        guard FileManager.default.fileExists(atPath: config.logFilePath.path) else {
            return false
        }
        
        let crashLogs = extractCrashLogs(from: config.logFilePath)
        return !crashLogs.isEmpty
    }
}
```

## Integration with Crash Reporting Services

Logly crash logs can complement crash reporting services:

```swift
import Logly

class CrashManager {
    static func setup() {
        // Install Logly crash handlers first
        LoggerCrashHandler.install()
        
        // Configure other crash reporting services
        // (Firebase Crashlytics, Sentry, etc.)
        
        // Check for previous crashes on app launch
        checkForPreviousCrashes()
    }
    
    private static func checkForPreviousCrashes() {
        if CrashAnalyzer.hasCrashLogs() {
            let logger = Logger.custom(category: "CrashRecovery")
            logger.warning("Previous crash detected, logs available for analysis")
            
            // Optionally upload crash logs to your server
            uploadCrashLogsIfNeeded()
        }
    }
    
    private static func uploadCrashLogsIfNeeded() {
        // Implementation for uploading crash logs
        // to your analytics or crash reporting service
    }
}
```

## Best Practices

1. **Install early** - Call `LoggerCrashHandler.install()` as early as possible in your app lifecycle
2. **Ensure file logging** - Make sure `logToFile` is enabled to capture crash logs persistently
3. **Monitor crash logs** - Regularly check for crash logs in your log files
4. **Complement, don't replace** - Use alongside dedicated crash reporting services for comprehensive coverage
5. **Test crash handling** - Verify crash logging works in your development environment

## Limitations

- Crash handlers cannot prevent crashes, only log them
- Some types of crashes (like memory corruption) may prevent logging
- Signal handlers may not capture all crash types on all platforms
- Crash logs are written synchronously and may impact crash recovery time

## Thread Safety

All crash handling operations are thread-safe and designed to work reliably even in unstable crash conditions.

## See Also

- ``LoggerCrashHandler``
- ``LogCategory``
- <doc:Configuration>
- <doc:Usage>