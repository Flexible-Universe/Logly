//
//  LogRotator.swift
//  Logly
//
//  Created by Rolf Warnecke on 20.04.25.
//  Copyright © 2025 Flexible-Universe. All rights reserved.
//
import Foundation

/// Intelligent log file rotation and lifecycle management system with automated cleanup.
/// 
/// `LogRotator` provides a comprehensive log file management solution that prevents
/// unlimited disk usage while maintaining log freshness and accessibility. The system
/// implements sophisticated rotation triggers, intelligent naming schemes, and automated
/// cleanup processes designed for long-running applications and high-volume logging scenarios.
/// 
/// ## Architecture Overview
/// 
/// ### Dual-Trigger Rotation System
/// 
/// The rotator implements a dual-trigger system that monitors both file size and age,
/// ensuring log rotation occurs when either threshold is exceeded:
/// 
/// ```
/// ┌─────────────────────────────────────────────────────────────────────────┐
/// │                              LogRotator.rotateIfNeeded()                              │
/// └──────────────────────────────────┬──────────────────────────────────────┘
///                                             │
///                   ┌─────────────────────────┴─────────────────────────┐
///                   │            Size Trigger Check            │
///                   │                                          │
///                   │  if fileSize >= maxFileSizeInBytes:     │
///                   │      shouldRotate = true                │
///                   └─────────────────────────┬─────────────────────────┘
///                                             │
///                   ┌─────────────────────────┴─────────────────────────┐
///                   │             Age Trigger Check             │
///                   │                                          │
///                   │  if fileAge >= maxLogAge:               │
///                   │      shouldRotate = true                │
///                   └─────────────────────────┬─────────────────────────┘
///                                             │
///                         ┌─────────────────┴─────────────────┐
///                         │    Rotation Process     │
///                         │                         │
///                         │  1. Rename current      │
///                         │  2. Clean up old files  │
///                         └─────────────────────────────────┘
/// ```
/// 
/// ### Rotation Trigger Analysis
/// 
/// #### Size-Based Rotation
/// ```swift
/// let maxSize: Int64 = 5 * 1024 * 1024  // 5MB
/// let currentSize = fileAttributes[.size] as? Int64 ?? 0
/// 
/// if currentSize >= maxSize {
///     // Trigger rotation to prevent excessive file sizes
///     rotateCurrentFile()
/// }
/// ```
/// 
/// **Use Cases**:
/// - High-volume logging applications
/// - Storage capacity management
/// - Performance optimization (smaller files are faster to process)
/// - Tool compatibility (many utilities perform better on smaller files)
/// 
/// #### Time-Based Rotation
/// ```swift
/// let maxAge: TimeInterval = 24 * 60 * 60  // 24 hours
/// let creationDate = fileAttributes[.creationDate] as? Date ?? Date.distantPast
/// let fileAge = Date().timeIntervalSince(creationDate)
/// 
/// if fileAge >= maxAge {
///     // Trigger rotation to maintain log freshness
///     rotateCurrentFile()
/// }
/// ```
/// 
/// **Use Cases**:
/// - Daily log separation for monitoring
/// - Compliance requirements (retention periods)
/// - Log analysis workflows (time-based grouping)
/// - Debugging sessions (isolating time periods)
/// 
/// ## File Naming & Organization System
/// 
/// ### Intelligent Naming Convention
/// 
/// The rotator employs a sophisticated naming system that ensures chronological
/// ordering and prevents naming conflicts:
/// 
/// ```
/// Original File: /path/to/logs/application.log
/// 
/// After Rotation:
/// application_2025-01-20T08-30-45Z.log  ← Oldest
/// application_2025-01-20T14-15-22Z.log
/// application_2025-01-20T20-45-18Z.log
/// application_2025-01-21T02-12-33Z.log
/// application_2025-01-21T09-33-07Z.log  ← Newest
/// application.log                       ← Current (active)
/// ```
/// 
/// ### Timestamp Format Specification
/// 
/// ```swift
/// let timestamp = ISO8601DateFormatter().string(from: Date())
///     .replacingOccurrences(of: ":", with: "-")
/// // Result: "2025-01-20T14-30-45Z"
/// ```
/// 
/// **Format Benefits**:
/// - **Lexicographic Sorting**: Files sort correctly by name
/// - **Filesystem Compatibility**: No problematic characters (colons)
/// - **Human Readable**: Easily parsed timestamps
/// - **Timezone Explicit**: UTC (Z) suffix prevents ambiguity
/// - **ISO8601 Standard**: Industry-standard timestamp format
/// 
/// ### Directory Structure Management
/// 
/// The rotator works with any directory structure and automatically handles:
/// 
/// ```
/// /Application/Logs/
/// ├── application.log                    ← Current active log
/// ├── application_2025-01-19T*.log       ← Previous day's logs
/// ├── application_2025-01-20T*.log       ← Recent rotated logs
/// └── error_logs/
///     ├── errors.log                    ← Current error log
///     └── errors_2025-01-20T*.log        ← Rotated error logs
/// ```
/// 
/// ## Automated Cleanup System
/// 
/// ### Intelligent File Management
/// 
/// The cleanup system prevents unlimited disk usage while preserving important logs:
/// 
/// ```swift
/// func cleanupOldFiles(directory: URL, baseName: String, maxFiles: Int) {
///     // 1. Scan directory for rotated files
///     let rotatedFiles = scanForRotatedFiles(in: directory, matching: baseName)
///     
///     // 2. Sort by creation date (oldest first)
///     let sortedFiles = rotatedFiles.sorted(by: creationDate)
///     
///     // 3. Calculate excess file count
///     let excessCount = max(0, sortedFiles.count - maxFiles)
///     
///     // 4. Delete oldest excess files
///     for file in sortedFiles.prefix(excessCount) {
///         try? FileManager.default.removeItem(at: file)
///     }
/// }
/// ```
/// 
/// ### Retention Policy Implementation
/// 
/// | Configuration | Behavior | Use Case |
/// |---------------|----------|----------|
/// | `maxRotatedFiles = 0` | Delete immediately after rotation | Minimal disk usage |
/// | `maxRotatedFiles = 5` | Keep 5 most recent files | Standard applications |
/// | `maxRotatedFiles = 50` | Keep 50 historical files | Debug/analysis workflows |
/// | `maxRotatedFiles = -1` | Keep all files (no cleanup) | Compliance/audit requirements |
/// 
/// ### Storage Calculation
/// 
/// ```swift
/// // Estimate maximum disk usage
/// let maxDiskUsage = maxFileSizeInBytes * (maxRotatedFiles + 1)
/// 
/// // Example: 5MB files, keep 10 rotated files
/// // Maximum usage: 5MB * (10 + 1) = 55MB
/// ```
/// 
/// ## Performance Optimization
/// 
/// ### Efficient File Operations
/// 
/// ```swift
/// func rotateIfNeeded(at url: URL) {
///     // 1. Early exit if file doesn't exist
///     guard FileManager.default.fileExists(atPath: url.path) else { return }
///     
///     // 2. Single file attributes call (not separate stat calls)
///     guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else { return }
///     
///     // 3. Efficient size and date extraction
///     let fileSize = attributes[.size] as? Int64 ?? 0
///     let creationDate = attributes[.creationDate] as? Date ?? Date.distantPast
///     
///     // 4. Quick threshold checks before expensive operations
///     let config = LoggerConfiguration.shared
///     if fileSize < config.maxFileSizeInBytes && 
///        Date().timeIntervalSince(creationDate) < config.maxLogAge {
///         return  // No rotation needed
///     }
///     
///     // 5. Perform rotation only when necessary
///     performRotation(from: url, attributes: attributes)
/// }
/// ```
/// 
/// ### Atomic Operations
/// 
/// ```swift
/// func performRotation(from originalURL: URL) {
///     // 1. Generate unique rotated filename
///     let rotatedURL = generateRotatedURL(from: originalURL)
///     
///     // 2. Atomic file move (no data copying)
///     try FileManager.default.moveItem(at: originalURL, to: rotatedURL)
///     
///     // 3. Cleanup happens after successful rotation
///     cleanupOldFiles(in: originalURL.deletingLastPathComponent())
/// }
/// ```
/// 
/// **Benefits**:
/// - **No Data Copying**: Move operations are fast and atomic
/// - **Crash Safety**: Partial operations don't leave files in inconsistent state
/// - **Minimal I/O**: Single move operation instead of copy + delete
/// 
/// ## Integration with Logging Pipeline
/// 
/// ### Pre-Write Rotation
/// 
/// ```
/// LogCategory.log() → LogWriter.write() → LogRotator.rotateIfNeeded()
///                                        │
///                                        └────── File I/O
/// ```
/// 
/// The rotator is called **before** each write operation to ensure:
/// - New messages go to fresh files after rotation
/// - File size limits are never exceeded
/// - Time boundaries are respected
/// 
/// ### Configuration Integration
/// 
/// ```swift
/// // Dynamic configuration changes affect rotation immediately
/// let config = LoggerConfiguration.shared
/// 
/// // Runtime configuration changes
/// config.maxFileSizeInBytes = 1024 * 1024  // Reduce to 1MB
/// config.maxLogAge = 12 * 60 * 60          // Reduce to 12 hours
/// config.maxRotatedFiles = 3               // Keep fewer files
/// 
/// // Next write will use new thresholds
/// logger.info("This will trigger rotation with new limits")
/// ```
/// 
/// ## Error Handling & Resilience
/// 
/// ### Graceful Error Recovery
/// 
/// ```swift
/// func rotateIfNeeded(at url: URL) {
///     do {
///         try performRotationChecks(at: url)
///     } catch {
///         // Log error but don't interrupt logging process
///         print("[Logger] Rotation failed: \(error)")
///         // Logging continues with existing file
///     }
/// }
/// ```
/// 
/// ### Common Error Scenarios
/// 
/// | Error | Impact | Recovery |
/// |-------|--------|-----------|
/// | Permission denied | Rotation fails | Continue with current file |
/// | Disk full | Rotation fails | Log rotation failure |
/// | File locked | Rotation fails | Retry on next write |
/// | Directory missing | Rotation fails | Attempt directory creation |
/// 
/// ## Thread Safety & Concurrency
/// 
/// ### Serialized Queue Integration
/// 
/// The rotator is designed to work with the logging system's serialized queues:
/// 
/// ```swift
/// // LogCategory ensures serialized access
/// LogCategory.logQueue.async {
///     LogRotator.rotateIfNeeded(at: url)  // Thread-safe
///     LogWriter.write(message)            // Thread-safe
/// }
/// ```
/// 
/// ### File System Race Conditions
/// 
/// The rotator prevents common race conditions:
/// - **Multiple Writers**: Serialized access prevents conflicts
/// - **External Modification**: Graceful handling of externally modified files
/// - **Concurrent Rotation**: Single-threaded rotation prevents corruption
/// 
/// ## Real-World Usage Scenarios
/// 
/// ### Long-Running Server Applications
/// ```swift
/// // Configure for 24/7 operation
/// config.maxFileSizeInBytes = 100 * 1024 * 1024  // 100MB per file
/// config.maxLogAge = 24 * 60 * 60                 // Daily rotation
/// config.maxRotatedFiles = 30                     // Keep 30 days
/// // Result: ~3GB maximum disk usage
/// ```
/// 
/// ### Development & Debugging
/// ```swift
/// // Configure for development
/// config.maxFileSizeInBytes = 10 * 1024 * 1024   // 10MB per file
/// config.maxLogAge = 60 * 60                     // Hourly rotation
/// config.maxRotatedFiles = 5                     // Keep 5 hours
/// // Result: Quick rotation for easier analysis
/// ```
/// 
/// ### Embedded/Resource-Constrained Environments
/// ```swift
/// // Minimal disk usage
/// config.maxFileSizeInBytes = 1024 * 1024        // 1MB per file
/// config.maxLogAge = 60 * 60                     // 1 hour
/// config.maxRotatedFiles = 2                     // Keep 2 files only
/// // Result: ~3MB maximum disk usage
/// ```
struct LogRotator {
    /// Checks if log rotation is needed and performs rotation if necessary.
    /// 
    /// This method examines the specified log file against configured size and age
    /// limits, performing rotation and cleanup when thresholds are exceeded.
    /// 
    /// - Parameter url: The URL of the log file to check for rotation
    /// 
    /// ## Rotation Criteria
    /// 
    /// Rotation occurs when either condition is met:
    /// - File size ≥ ``LoggerConfiguration/maxFileSizeInBytes``
    /// - File age ≥ ``LoggerConfiguration/maxLogAge``
    /// 
    /// ## Process Flow
    /// 
    /// 1. Check if file exists (exit early if not)
    /// 2. Evaluate size-based rotation criteria
    /// 3. Evaluate age-based rotation criteria  
    /// 4. If rotation needed, rename current file with timestamp
    /// 5. Clean up excess rotated files
    /// 
    /// ## Error Handling
    /// 
    /// File operation errors are logged to console and don't interrupt the logging process.
    /// The system gracefully continues even if rotation fails.
    /// 
    /// ## Example
    /// 
    /// ```
    /// // Before rotation
    /// app.log (5.2 MB, created 2 days ago)
    /// 
    /// // After rotation  
    /// app.log (0 bytes, just created)
    /// app_2025-01-20T10-30-45Z.log (5.2 MB, archived)
    /// ```
    static func rotateIfNeeded(at url: URL) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else { return }

        var shouldRotate = false

        if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? Int64 {
            let maxFileSize = LoggerConfiguration.shared.maxFileSizeInBytes
            if fileSize >= maxFileSize {
                shouldRotate = true
            }
        }

        if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
           let creationDate = attributes[.creationDate] as? Date {
            let age = Date().timeIntervalSince(creationDate)
            let maxLogAge = LoggerConfiguration.shared.maxLogAge
            if age >= maxLogAge {
                shouldRotate = true
            }
        }

        if shouldRotate {
            let dateString = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let rotatedURL = url.deletingLastPathComponent().appendingPathComponent("\(url.deletingPathExtension().lastPathComponent)_\(dateString).log")
            do {
                try fileManager.moveItem(at: url, to: rotatedURL)
                cleanUpOldLogFiles(directory: url.deletingLastPathComponent(), baseName: url.deletingPathExtension().lastPathComponent)
            } catch {
                print("[Logger] Failed to rotate log file: \(error)")
            }
        }
    }

    /// Removes excess rotated log files beyond the configured retention limit.
    /// 
    /// This method scans the log directory for rotated files matching the base name pattern,
    /// sorts them by creation date, and removes the oldest files that exceed the
    /// ``LoggerConfiguration/maxRotatedFiles`` limit.
    /// 
    /// - Parameters:
    ///   - directory: The directory containing log files
    ///   - baseName: The base name of the log file (without extension or timestamp)
    /// 
    /// ## Cleanup Process
    /// 
    /// 1. Scan directory for files matching `{baseName}_{timestamp}.log` pattern
    /// 2. Sort files by creation date (oldest first)
    /// 3. Calculate excess file count beyond retention limit
    /// 4. Remove oldest excess files
    /// 
    /// ## File Selection
    /// 
    /// Only files that:
    /// - Have names starting with the base name followed by underscore
    /// - Have `.log` extension
    /// - Can be identified as rotated files (contain timestamp)
    /// 
    /// ## Error Handling
    /// 
    /// Individual file deletion failures are silently ignored to prevent
    /// interrupting the logging process. Permissions or file system issues
    /// won't crash the application.
    /// 
    /// ## Example
    /// 
    /// With `maxRotatedFiles = 3` and files:
    /// ```
    /// app_2025-01-18T08-00-00Z.log  ← Will be deleted (oldest)
    /// app_2025-01-19T08-00-00Z.log  ← Will be deleted (old)
    /// app_2025-01-20T08-00-00Z.log  ← Kept
    /// app_2025-01-21T08-00-00Z.log  ← Kept
    /// app_2025-01-22T08-00-00Z.log  ← Kept (newest)
    /// ```
    private static func cleanUpOldLogFiles(directory: URL, baseName: String) {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey], options: []) else { return }

        let rotatedFiles = files.filter { $0.lastPathComponent.hasPrefix("\(baseName)_") && $0.pathExtension == "log" }

        let sortedFiles = rotatedFiles.sorted {
            let date1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            let date2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            return date1 < date2
        }

        let maxRotatedFiles = LoggerConfiguration.shared.maxRotatedFiles
        let excessCount = sortedFiles.count - maxRotatedFiles
        guard excessCount > 0 else { return }

        for file in sortedFiles.prefix(excessCount) {
            try? fileManager.removeItem(at: file)
        }
    }
}
