# Format Customization

Customize log output formats to match your application's needs.

## Overview

Logly supports customizable log format strings with various tokens for timestamps, log levels, categories, file information, and messages.

## Format Tokens

Available tokens for log format customization:

- `{timestamp}` - ISO8601 formatted timestamp
- `{level}` - Log level (padded to configured width)
- `{category}` - Category name (padded to configured width)
- `{file}` - Filename (without path)
- `{line}` - Line number
- `{message}` - The actual log message

## Basic Format Configuration

### Synchronous Configuration

```swift
let config = LoggerConfiguration.shared

// Set custom format
config.logFormat = "[{timestamp}] {level} {category} {file}:{line} - {message}"

// Configure padding
config.logLevelWidth = 7  // Pad level to 7 characters
config.categoryWidth = 12 // Pad category to 12 characters
```

### Asynchronous Configuration

```swift
let config = LoggerConfiguration.shared

// Set custom format
await config.setLogFormat("[{timestamp}] {level} {category} {file}:{line} - {message}")

// Configure padding
await config.setLogLevelWidth(7)  // Pad level to 7 characters
await config.setCategoryWidth(12) // Pad category to 12 characters
```

## Format Examples

### Default Format

```swift
config.logFormat = "{timestamp} - {level} - {category} - {file}:{line} - {message}"
```

**Output:**
```
2025-01-20T10:12:45Z - INFO    - Network     - APISession.swift:45 - Fetching data from API
2025-01-20T10:12:46Z - WARNING - Authentication - AuthManager.swift:33 - Token is about to expire
2025-01-20T10:12:47Z - ERROR   - Database   - DataStore.swift:78 - Failed to fetch records
```

### Compact Format

```swift
config.logFormat = "{level}: {message}"
config.logLevelWidth = 5
```

**Output:**
```
INFO : Fetching data from API
WARN : Token is about to expire
ERROR: Failed to fetch records
```

### Detailed Format

```swift
config.logFormat = "[{timestamp}] [{level}] {category} | {file}:{line} | {message}"
config.logLevelWidth = 8
config.categoryWidth = 15
```

**Output:**
```
[2025-01-20T10:12:45Z] [INFO    ] Network         | APISession.swift:45 | Fetching data from API
[2025-01-20T10:12:46Z] [WARNING ] Authentication  | AuthManager.swift:33 | Token is about to expire
[2025-01-20T10:12:47Z] [ERROR   ] Database        | DataStore.swift:78 | Failed to fetch records
```

## Environment-Specific Formatting

Configure different formats for different build configurations:

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

## ANSI Color Support

Enable colorized console output for better readability:

```swift
// Enable colors (default: true)
config.enableANSIColors = true

// Or with async API
await config.setEnableANSIColors(true)
```

### Color Mapping

- **Debug**: Cyan
- **Info**: Green  
- **Warning**: Yellow
- **Error**: Red
- **Fault**: Bright Red

## Advanced Formatting

### JSON-Style Format

```swift
config.logFormat = "{\\"time\\": \\"{timestamp}\\", \\"level\\": \\"{level}\\", \\"category\\": \\"{category}\\", \\"message\\": \\"{message}\\"}"
```

**Output:**
```json
{"time": "2025-01-20T10:12:45Z", "level": "INFO", "category": "Network", "message": "Fetching data from API"}
```

### Syslog-Style Format

```swift
config.logFormat = "{timestamp} MyApp[{category}]: {level}: {message}"
```

**Output:**
```
2025-01-20T10:12:45Z MyApp[Network]: INFO: Fetching data from API
```

## Custom Log Formatter

For more advanced formatting needs, you can use the ``LogFormatter`` class directly:

```swift
let formattedMessage = LogFormatter.format(
    level: .info,
    category: "CustomCategory", 
    message: "Custom message",
    file: #file,
    line: #line
)
print(formattedMessage)
```

## Best Practices

1. **Keep formats consistent** across your application
2. **Use appropriate detail levels** for different environments
3. **Consider log parsing tools** when designing formats
4. **Test format changes** with your log analysis workflow
5. **Balance readability and performance** - complex formats can impact performance

## See Also

- ``LoggerConfiguration``
- ``LogFormatter``
- <doc:Configuration>
- <doc:Usage>