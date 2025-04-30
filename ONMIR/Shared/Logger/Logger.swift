import Foundation
import OSLog
import os

public enum LogLevel {
  case error
  case warning
  case info
  case debug
  case verbose

  var symbol: String {
    switch self {
    case .error: return "🚨 ERROR"
    case .warning: return "⚠️ WARNING"
    case .info: return "🔨 INFO"
    case .debug: return "🐛 DEBUG"
    case .verbose: return "👾 VERBOSE"
    }
  }

  var osLogType: OSLogType {
    switch self {
    case .error: return .error
    case .warning: return .error
    case .info: return .info
    case .debug: return .default
    case .verbose: return .default
    }
  }
}

public struct Logger: Sendable {
  private static let subsystem = Bundle.main.bundleIdentifier ?? "Logger"
  private static let systemLogger: os.Logger = os.Logger(subsystem: subsystem, category: "Default")

  public static func error(
    _ items: Any...,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
  ) {
    assertionFailure("\(items.map { String(describing: $0) }.joined(separator: " "))")
    log(level: .error, items: items, file: file, function: function, line: line)
  }

  public static func warning(
    _ items: Any...,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
  ) {
    log(level: .warning, items: items, file: file, function: function, line: line)
  }

  public static func info(
    _ items: Any...,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
  ) {
    log(level: .info, items: items, file: file, function: function, line: line)
  }

  public static func debug(
    _ items: Any...,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
  ) {
    log(level: .debug, items: items, file: file, function: function, line: line)
  }

  public static func verbose(
    _ items: Any...,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
  ) {
    log(level: .verbose, items: items, file: file, function: function, line: line)
  }

  // MARK: - Private

  private static func log(
    level: LogLevel,
    items: [Any],
    file: StaticString,
    function: StaticString,
    line: UInt
  ) {
    let message = items.map { String(describing: $0) }.joined(separator: " ")
    let metadata =
      "[\(file.description.components(separatedBy: "/").last ?? "")][\(function)][\(line)]"

    systemLogger.log(
      level: level.osLogType,
      "\(level.symbol, privacy: .public) \(metadata, privacy: .public) - \(message, privacy: .public)"
    )
  }

  public static func export() -> [Data] {
    do {
      let store = try OSLogStore(scope: .currentProcessIdentifier)
      let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
      let position = store.position(date: threeDaysAgo)

      let entries = try store.getEntries(at: position)
        .compactMap { $0 as? OSLogEntryLog }
        .filter { $0.subsystem == "com.msg.onmir" }

      let datas = entries.compactMap { logEntry -> Data? in
        let formattedLog = """
          \(logEntry.date) \(logEntry.category) \
          [\(logEntry.subsystem)] \
          \(logEntry.composedMessage)\n
          """

        return formattedLog.data(using: .utf8)
      }
      return datas
    } catch {
      print("Failed to retrieve logs: \(error)")
      return []
    }
  }
}
