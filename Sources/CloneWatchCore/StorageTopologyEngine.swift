import Foundation

public struct DiskTopologySnapshot: Codable, Sendable {
    public var generatedAt: Date
    public var rawPlist: [String: String]
    public var summary: [String]
}

public struct StorageTopologyEngine: Sendable {
    public init() {}

    public func discover() -> DiskTopologySnapshot {
        do {
            let output = try FileSystemHelper.runProcess("/usr/sbin/diskutil", ["list", "-plist"])
            let summary = summarizeDiskutilList(output)
            return DiskTopologySnapshot(
                generatedAt: Date(),
                rawPlist: ["diskutil-list-plist": output],
                summary: summary
            )
        } catch {
            return DiskTopologySnapshot(
                generatedAt: Date(),
                rawPlist: [:],
                summary: ["Unable to inspect disk topology: \(error.localizedDescription)"]
            )
        }
    }

    private func summarizeDiskutilList(_ plistText: String) -> [String] {
        var lines: [String] = []
        if plistText.contains("AllDisksAndPartitions") {
            lines.append("diskutil returned AllDisksAndPartitions data.")
        }
        if plistText.contains("APFSVolumes") {
            lines.append("APFS volumes were detected in the current storage topology.")
        }
        if plistText.contains("Partitions") {
            lines.append("Partition information is available for destructive-operation planning.")
        }
        if lines.isEmpty {
            lines.append("diskutil topology output captured for later parsing.")
        }
        return lines
    }
}
