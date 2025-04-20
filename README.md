# Logly

A lightweight, modular, and concurrency-safe logging system for Swift projects. Designed for macOS and iOS applications, it supports log levels, structured formatting, log rotation, file output, and asynchronous logging – all configurable at runtime.

---

## 🚀 Features

- ✅ Log levels (`debug`, `info`, `warning`, `error`, `fault`)
- ✅ Structured format with timestamps, filenames, and line numbers
- ✅ Asynchronous logging to prevent UI blocking
- ✅ Log file output
- ✅ Automatic log rotation (by file size or file age)
- ✅ Limits total number of rotated log files
- ✅ Easy configuration via `LoggerConfiguration`
- ✅ Modular Swift Package design for easy integration

---

## 📦 Installation

### Swift Package Manager (SPM)

1. Open your project in Xcode
2. Go to `File > Add Packages...`
3. Paste the URL of this repository
4. Add `LoggingPackage` to your target

---

## 🧠 How it Works

The package uses Apple's `os.Logger` under the hood, wrapped in a custom `LogCategory` type. You configure the behavior globally using `LoggerConfiguration`, and log messages using `Logger.network`, `Logger.authentication`, or your own categories.

Logging can be asynchronous to improve performance and prevent blocking the main thread. Logs can be printed to the console and/or written to a file. Files are automatically rotated based on size or age, and older files are deleted based on a file limit.

---

## 🛠 Configuration

Set up your logging preferences at app launch (e.g. inside `AppDelegate` or `@main App`):

```swift
LoggerConfiguration.currentLogLevel = .info
LoggerConfiguration.logToFile = true
LoggerConfiguration.logFilePath = FileManager.default
    .urls(for: .documentDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("my_logs/app.log")
LoggerConfiguration.logFormat = "[{timestamp}] {level} {category} {file}:{line} - {message}"
LoggerConfiguration.maxFileSizeInBytes = 1_000_000 // 1 MB
LoggerConfiguration.maxLogAge = 60 * 60 * 24 // 24 hours
LoggerConfiguration.maxRotatedFiles = 3
LoggerConfiguration.asynchronousLogging = true
```

---

## 🧪 Usage

Hier ist der ergänzte Abschnitt für die `README.md`:

---

### 🧩 Define Your Own Log Categories

You can define your own commonly used log categories in your app to simplify usage:

```swift
// MyApp+Logger.swift (inside your app target)

import Logly

extension Logger {
    static let network = Logger.custom(category: "Network")
    static let authentication = Logger.custom(category: "Authentication")
    static let database = Logger.custom(category: "Database")
}
```

Then you can use them like this:

```swift
Logger.network.debug("Request sent to API")
Logger.authentication.warning("Token is about to expire")
Logger.database.error("Failed to fetch records")
```

This keeps your logging usage consistent and organized by concern across your entire app.

### Custom Log Category

```swift
let analyticsLogger = Logger.custom(category: "Analytics")
analyticsLogger.info("User tapped on 'Start'")
```

---

## 📂 Output Example

```
[2025-04-20T10:12:45Z] DEBUG   Network        APISession.swift:45 - Fetching data from API
[2025-04-20T10:12:46Z] INFO    Authentication AuthManager.swift:33 - User login succeeded
```

---

## 🔄 Log Rotation

- When the log file exceeds `LoggerConfiguration.maxFileSizeInBytes`, it is rotated.
- When the log file is older than `LoggerConfiguration.maxLogAge`, it is rotated.
- Old rotated logs are named like: `app_2025-04-20T12-30-00Z.log`
- Only `LoggerConfiguration.maxRotatedFiles` most recent files are kept.

---

## ⚠️ Concurrency

- All configuration values are declared in an `actor`, so access is concurrency-safe.
- Asynchronous logging uses a dedicated background queue.
- Avoid accessing log configuration from multiple threads without `await` if you extend it.

---

## 📄 License

MIT License

---

## 👨‍💻 Author

Built with ❤️ in Swift for scalable and safe application logging.
