# ``Logly``

A lightweight, modular, and concurrency-safe logging system for Swift projects.

## Overview

Designed for macOS and iOS applications, Logly supports log levels, structured formatting, log rotation, file output, asynchronous logging, and crash/signal handling – all configurable at runtime.

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

## Features

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

## Installation

### Swift Package Manager (SPM)

1. Open your project in Xcode
2. Go to `File > Add Packages...`
3. Paste the URL of this repository
4. Add `Logly` to your target

**Minimum Requirements:**

- iOS 16.0+ or macOS 13.0+
- Swift 6.1+

## How it Works

Logly provides a ``LogCategory`` structure that wraps Apple's `os.Logger` with additional features. The system is built around:

- **Thread-safe configuration** (``LoggerConfiguration``) using concurrent queues with barrier writes
- **Dual API support**: Use either synchronous or async/await patterns
- **Asynchronous logging option** using dedicated queues to avoid blocking
- **Automatic log rotation** when files exceed size or age limits
- **Crash/signal handling** that automatically logs crashes and signals
- **Customizable formatting** with token-based format strings

## Topics

### Getting Started
- <doc:Configuration>
- <doc:Usage>
- <doc:FormatCustomization>

### Core Components
- ``LogCategory``
- ``LoggerConfiguration``
- ``LoggerCrashHandler``
- ``LogLevel``

### Advanced Topics
- <doc:LogRotation>
- <doc:CrashHandling>
- <doc:PerformanceOptimization>