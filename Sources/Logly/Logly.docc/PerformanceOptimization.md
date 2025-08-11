# Performance Optimization

Learn how to optimize Logly for maximum performance in production applications.

## Overview

Logly is designed for high performance, but proper configuration and usage patterns can further optimize performance for your specific use case.

## Asynchronous Logging

Enable asynchronous logging to prevent UI blocking:

```swift
let config = LoggerConfiguration.shared

// Enable async logging (recommended for production)
config.asynchronousLogging = true

// Or with async API
await config.setAsynchronousLogging(true)
```

### Benefits of Async Logging
- **Non-blocking**: Log calls return immediately
- **UI responsiveness**: Main thread is never blocked by I/O operations
- **Batched writes**: Multiple log messages can be batched for efficiency
- **Queue-based**: Uses dedicated background queues for processing

### When to Use Sync vs Async

```swift
// Synchronous logging - good for:
// - Critical error paths where you need guaranteed logging
// - Debug builds where immediate output is helpful
// - Low-volume logging scenarios
config.asynchronousLogging = false

// Asynchronous logging - good for:
// - Production applications
// - High-volume logging
// - UI-responsive applications
config.asynchronousLogging = true
```

## Log Level Optimization

Set appropriate log levels for different environments:

```swift
#if DEBUG
// Development: verbose logging
config.currentLogLevel = .debug
#elseif STAGING  
// Staging: moderate logging
config.currentLogLevel = .info
#else
// Production: minimal logging
config.currentLogLevel = .warning
#endif
```

### Log Level Performance Impact

- **Debug**: Highest overhead, most detailed
- **Info**: Moderate overhead, general information
- **Warning**: Low overhead, important events only
- **Error**: Minimal overhead, errors only
- **Fault**: Lowest overhead, critical issues only

## Memory Management

### String Interpolation Optimization

Avoid expensive string operations when logging is disabled:

```swift
// ❌ Poor performance - string interpolation happens regardless of log level
logger.debug("Processing \(expensiveComputation()) items")

// ✅ Better performance - check log level first
if config.currentLogLevel.rawValue <= LogLevel.debug.rawValue {
    logger.debug("Processing \(expensiveComputation()) items")
}

// ✅ Best performance - use closure-based logging (if available)
logger.debug { "Processing \(expensiveComputation()) items" }
```

### Memory-Efficient Logging

```swift
// ❌ Creates unnecessary string objects
let userId = user.id
let userName = user.name  
logger.info("User \(userId) (\(userName)) logged in")

// ✅ More memory efficient
logger.info("User \(user.id) (\(user.name)) logged in")
```

## File I/O Optimization

### Log Rotation Configuration

Balance file size and rotation frequency:

```swift
// For high-volume applications
config.maxFileSizeInBytes = 50 * 1024 * 1024  // 50 MB - less frequent rotation
config.maxRotatedFiles = 5                     // Keep fewer files

// For low-volume applications  
config.maxFileSizeInBytes = 5 * 1024 * 1024   // 5 MB - more frequent rotation
config.maxRotatedFiles = 10                    // Keep more files for history
```

### Directory Optimization

Use appropriate directories for log files:

```swift
// ❌ Avoid Documents directory (synced to iCloud)
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

// ✅ Use Application Support (not synced, better performance)
let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("Logs")

config.logFilePath = appSupportPath.appendingPathComponent("app.log")
```

## Format String Optimization

Simpler formats perform better:

```swift
// ❌ Complex format with many tokens
config.logFormat = "[{timestamp}] {level} {category} {file}:{line} | {message}"

// ✅ Simpler format for production
config.logFormat = "{timestamp} {level} {message}"

// ✅ Minimal format for maximum performance
config.logFormat = "{level}: {message}"
```

## Concurrency Optimization

### Thread Safety Best Practices

```swift
// ✅ Thread-safe configuration access
let level = LoggerConfiguration.shared.currentLogLevel

// ✅ Safe to call from any thread
DispatchQueue.global().async {
    logger.info("Background operation completed")
}

// ✅ Efficient async context usage
Task {
    await logger.info("Async operation completed")
}
```

### Queue Management

Logly uses optimized queues internally:

```swift
// Logly's internal queue structure (for reference):
// - Concurrent queue for configuration reads
// - Barrier queue for configuration writes  
// - Dedicated queue for async logging operations
// - Thread-safe message formatting and file operations
```

## Monitoring Performance

### Measuring Log Performance

```swift
class LoggingPerformanceMonitor {
    static func measureLoggingPerformance() {
        let logger = Logger.custom(category: "Performance")
        let iterations = 1000
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<iterations {
            logger.info("Test message \(i)")
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let messagesPerSecond = Double(iterations) / duration
        
        print("Logged \(iterations) messages in \(duration)s")
        print("Performance: \(messagesPerSecond) messages/second")
    }
}
```

### Performance Profiling

Use Instruments to profile logging performance:

1. **Time Profiler**: Identify bottlenecks in logging code
2. **System Trace**: Monitor file I/O operations
3. **Memory Graph**: Check for memory leaks in logging paths
4. **Disk Activity**: Monitor log file write patterns

## Production Recommendations

### Optimal Production Configuration

```swift
func configureForProduction() {
    let config = LoggerConfiguration.shared
    
    // Performance optimizations
    config.asynchronousLogging = true           // Non-blocking
    config.currentLogLevel = .warning           // Minimal logging
    config.enableANSIColors = false             // No color processing
    
    // Efficient formatting  
    config.logFormat = "{timestamp} {level} {message}"
    config.logLevelWidth = 5                    // Minimal padding
    
    // Balanced rotation
    config.maxFileSizeInBytes = 20 * 1024 * 1024  // 20 MB
    config.maxLogAge = 60 * 60 * 24               // 24 hours
    config.maxRotatedFiles = 5                    // Limited retention
    
    // Efficient file location
    let appSupportPath = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Logs")
    
    config.logFilePath = appSupportPath.appendingPathComponent("production.log")
}
```

## Performance Testing

Always test logging performance in your specific environment:

```swift
class LoggingBenchmark {
    static func benchmarkSyncVsAsync() {
        let logger = Logger.custom(category: "Benchmark")
        let config = LoggerConfiguration.shared
        let iterations = 10000
        
        // Test synchronous logging
        config.asynchronousLogging = false
        let syncStart = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<iterations {
            logger.info("Sync message \(i)")
        }
        
        let syncDuration = CFAbsoluteTimeGetCurrent() - syncStart
        
        // Test asynchronous logging
        config.asynchronousLogging = true  
        let asyncStart = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<iterations {
            logger.info("Async message \(i)")
        }
        
        let asyncDuration = CFAbsoluteTimeGetCurrent() - asyncStart
        
        print("Sync:  \(syncDuration)s for \(iterations) messages")
        print("Async: \(asyncDuration)s for \(iterations) messages")
        print("Async speedup: \(syncDuration / asyncDuration)x")
    }
}
```

## See Also

- ``LoggerConfiguration``
- <doc:Configuration>
- <doc:LogRotation>
- <doc:Usage>