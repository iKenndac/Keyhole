import Foundation

enum LogLevel: Int, Equatable, Hashable, Comparable {

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    static var `default`: LogLevel {
        #if DEBUG
        return .debug
        #else
        return .warning
        #endif
    }

    static var current: LogLevel = .default

    case debug
    case verbose
    case info
    case warning
    case error

    var singleCharacter: String {
        switch self {
        case .debug: return "D"
        case .verbose: return "V"
        case .info: return "I"
        case .warning: return "W"
        case .error: return "E"
        }
    }
}

func LogDebug(_ message: Any...) { Log(at: .debug, of: .current, message) }
func LogVerbose(_ message: Any...) { Log(at: .verbose, of: .current, message) }
func LogInfo(_ message: Any...) { Log(at: .info, of: .current, message) }
func LogWarning(_ message: Any...) { Log(at: .warning, of: .current, message) }
func LogError(_ message: Any...) { Log(at: .error, of: .current, message) }

func Log(at level: LogLevel, of allowed: LogLevel = .current, _ elements: Any...) {
    Log(at: level, of: allowed, elements)
}

func Log(at level: LogLevel, of allowed: LogLevel = .current, _ elements: [Any]) {
    guard level >= allowed else { return }
    // For some reason _this_ NSLog doesn't print a timestamp ¯\_(ツ)_/¯
    NSLog("%@ [%@] %@", logDateFormatter.string(from: Date()), level.singleCharacter,
          elements.map({ String(describing: $0) }).joined(separator: ", "))
}

fileprivate var logDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return formatter
}()
