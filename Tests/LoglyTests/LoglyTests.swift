import XCTest
import os
@testable import Logly

final class LoglyTests: XCTestCase {
    func testLogLevelDescriptionAndColor() {
        XCTAssertEqual(LogLevel.debug.description, "DEBUG")
        XCTAssertEqual(LogLevel.info.description, "INFO")
        XCTAssertEqual(LogLevel.warning.description, "WARNING")
        XCTAssertEqual(LogLevel.error.description, "ERROR")
        XCTAssertEqual(LogLevel.fault.description, "FAULT")

        XCTAssertEqual(LogLevel.debug.ansiColorCode, "\u{001B}[0;36m")
        XCTAssertEqual(LogLevel.info.ansiColorCode, "\u{001B}[0;32m")
        XCTAssertEqual(LogLevel.warning.ansiColorCode, "\u{001B}[0;33m")
        XCTAssertEqual(LogLevel.error.ansiColorCode, "\u{001B}[0;31m")
        XCTAssertEqual(LogLevel.fault.ansiColorCode, "\u{001B}[1;31m")
    }

    func testLoggerConfigurationAsyncProperties() async {
        let config = LoggerConfiguration.shared
        await config.setCurrentLogLevel(.error)
        let level = await config.getCurrentLogLevel()
        XCTAssertEqual(level, .error)

        await config.setLogToFile(false)
        let logToFile = await config.getLogToFile()
        XCTAssertFalse(logToFile)

        let dummyURL = FileManager.default.temporaryDirectory.appendingPathComponent("dummy.log")
        await config.setLogFilePath(dummyURL)
        let logFilePath = await config.getLogFilePath()
        XCTAssertEqual(logFilePath, dummyURL)

        await config.setEnableANSIColors(false)
        let ansiEnabled = await config.getEnableANSIColors()
        XCTAssertFalse(ansiEnabled)
    }

    func testLogFormatterFormat() async {
        // Set known format and params
        let config = LoggerConfiguration.shared
        await config.setLogFormat("{level} {category} {file}:{line} {message}")
        await config.setLogLevelWidth(5)
        await config.setCategoryWidth(8)
        
        let formatted = await LogFormatter.format(
            level: .info,
            category: "TestCat",
            message: "Hello!",
            file: "/tmp/TestFile.swift",
            line: 123
        )
        // Should contain INFO and category and file name
        XCTAssertTrue(formatted.contains("INFO"))
        XCTAssertTrue(formatted.contains("TestCat"))
        XCTAssertTrue(formatted.contains("TestFile.swift:123"))
        XCTAssertTrue(formatted.contains("Hello!"))
    }

    func testLogCategoryFormatting() async {
        // This test indirectly verifies formattedLog by checking output from log formatter
        let config = LoggerConfiguration.shared
        await config.setLogFormat("{level} {category} {file}:{line} {message}")
        await config.setLogLevelWidth(5)
        await config.setCategoryWidth(10)
        let _ = Logger.custom(category: "MyTestCat")
        let formatted = await LogFormatter.format(level: .warning, category: "MyTestCat", message: "Test msg", file: "/foo/bar.swift", line: 99)
        XCTAssertFalse(formatted.contains("WARNING"))
        XCTAssertTrue(formatted.contains("MyTestCat ")) // Note the space
        XCTAssertTrue(formatted.contains("bar.swift:99"))
        XCTAssertTrue(formatted.contains("Test msg"))
    }
}
