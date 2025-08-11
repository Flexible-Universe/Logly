# Log Rotation

Understand and configure automatic log file rotation in Logly.

## Overview

Logly automatically rotates log files based on size and age limits to prevent logs from consuming excessive disk space while maintaining historical data for debugging.

## How Log Rotation Works

Log rotation is triggered when either condition is met:
- **File size** exceeds the configured maximum (`maxFileSizeInBytes`)
- **File age** exceeds the configured maximum (`maxLogAge`)

When rotation occurs:
1. The current log file is renamed with a timestamp: `app_2025-01-20T12-30-00Z.log`
2. A new log file is created at the original path
3. Old rotated files beyond the retention limit are automatically deleted

## Configuration

### Synchronous Configuration

```swift
let config = LoggerConfiguration.shared

// Set maximum file size (5 MB)
config.maxFileSizeInBytes = 5 * 1024 * 1024

// Set maximum file age (24 hours)
config.maxLogAge = 60 * 60 * 24

// Keep 5 rotated files (delete older ones)
config.maxRotatedFiles = 5
```

### Asynchronous Configuration

```swift
let config = LoggerConfiguration.shared

// Set maximum file size (5 MB)
await config.setMaxFileSizeInBytes(5 * 1024 * 1024)

// Set maximum file age (24 hours) 
await config.setMaxLogAge(60 * 60 * 24)

// Keep 5 rotated files (delete older ones)
await config.setMaxRotatedFiles(5)
```

## Configuration Options

### File Size Limits

```swift
// Small files (1 MB) - frequent rotation
config.maxFileSizeInBytes = 1024 * 1024

// Medium files (10 MB) - balanced approach  
config.maxFileSizeInBytes = 10 * 1024 * 1024

// Large files (50 MB) - less frequent rotation
config.maxFileSizeInBytes = 50 * 1024 * 1024

// Disable size-based rotation
config.maxFileSizeInBytes = 0
```

### Age Limits

```swift
// Hourly rotation
config.maxLogAge = 60 * 60 // 1 hour

// Daily rotation
config.maxLogAge = 60 * 60 * 24 // 24 hours

// Weekly rotation  
config.maxLogAge = 60 * 60 * 24 * 7 // 7 days

// Disable age-based rotation
config.maxLogAge = 0
```

### Retention Policy

```swift
// Keep only 3 rotated files
config.maxRotatedFiles = 3

// Keep 10 rotated files (longer history)
config.maxRotatedFiles = 10

// Keep unlimited rotated files (not recommended)
config.maxRotatedFiles = 0
```

## Environment-Specific Rotation

Configure different rotation policies for different environments:

```swift
func configureRotation() {
    let config = LoggerConfiguration.shared
    
    #if DEBUG
    // Development: smaller files, shorter retention
    config.maxFileSizeInBytes = 1024 * 1024  // 1 MB
    config.maxLogAge = 60 * 60 * 2           // 2 hours
    config.maxRotatedFiles = 3               // Keep 3 files
    
    #else
    // Production: larger files, longer retention
    config.maxFileSizeInBytes = 10 * 1024 * 1024  // 10 MB
    config.maxLogAge = 60 * 60 * 24               // 24 hours  
    config.maxRotatedFiles = 10                   // Keep 10 files
    #endif
}
```

## File Naming Convention

Rotated files follow this naming pattern:
```
original_filename_YYYY-MM-DDTHH-MM-SSZ.extension
```

### Examples

If your log file is `app.log`, rotated files will be named:
```
app.log                    // Current log file
app_2025-01-20T10-30-45Z.log  // Rotated file from 10:30:45 UTC
app_2025-01-20T09-15-30Z.log  // Rotated file from 09:15:30 UTC
app_2025-01-19T18-45-12Z.log  // Rotated file from previous day
```

## Monitoring Log Files

You can programmatically access information about log files:

```swift
class LogAnalyzer {
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
    
    static func getTotalLogFileSize() -> Int64 {
        return getLogFileURLs().reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }
}
```

## Best Practices

1. **Balance file size and rotation frequency** - smaller files rotate more often but are easier to handle
2. **Consider your storage constraints** - adjust retention policies based on available disk space  
3. **Monitor log volume** - high-traffic applications may need more aggressive rotation
4. **Test rotation in development** - verify your rotation settings work as expected
5. **Plan for log analysis** - ensure your rotation policy maintains enough history for debugging

## Performance Considerations

- Rotation checks happen before each write operation
- The check is optimized and has minimal performance impact
- Large numbers of rotated files may slow directory operations
- Consider using separate log directories for different categories if you have high log volumes

## See Also

- ``LogRotator``
- ``LoggerConfiguration``
- <doc:Configuration>
- <doc:PerformanceOptimization>