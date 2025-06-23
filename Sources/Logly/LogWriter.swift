//
//  LogWriter.swift
//  Logly
//
//  Created by Rolf Warnecke on 20.04.25.
//  Copyright © 2025 Flexible-Universe. All rights reserved.
//
import Foundation

struct LogWriter {
    /// Writes a log message to the configured log file synchronously.
    /// This function ensures log rotation is performed if needed before writing.
    static func write(_ message: String) {
        let url = LoggerConfiguration.shared.logFilePath
        LogRotator.rotateIfNeeded(at: url)

        do {
            let fileHandle = try FileHandle(forWritingTo: url)
            fileHandle.seekToEndOfFile()
            if let data = (message + "\n").data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } catch {
            do {
                try (message + "\n").write(to: url, atomically: true, encoding: .utf8)
            } catch {
                print("[Logger] Failed to write log to file: \(error)")
            }
        }
    }
}
