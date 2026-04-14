import Foundation

public enum CloneWatchError: Error, LocalizedError {
    case invalidSource(String)
    case invalidDestination(String)
    case processFailed(String)
    case writeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidSource(let message),
             .invalidDestination(let message),
             .processFailed(let message),
             .writeFailed(let message):
            return message
        }
    }
}

public struct FileSystemHelper {
    public static func isoFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    public static func isoString(from date: Date) -> String {
        isoFormatter().string(from: date)
    }

    public static func ensureDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    public static func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        try data.write(to: url)
    }

    public static func writeText(_ text: String, to url: URL) throws {
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    public static func permissionsString(for path: String) -> String? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let permissions = attrs[.posixPermissions] as? NSNumber else {
            return nil
        }
        return String(permissions.intValue, radix: 8)
    }

    public static func runProcess(_ launchPath: String, _ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        let out = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let err = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        guard process.terminationStatus == 0 else {
            throw CloneWatchError.processFailed("Command failed: \(launchPath) \(arguments.joined(separator: " "))\n\(err)")
        }
        return out.isEmpty ? err : out
    }
}
