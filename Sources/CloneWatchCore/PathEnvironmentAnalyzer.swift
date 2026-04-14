import Foundation

public struct PathEnvironmentAnalyzer: Sendable {
    public init() {}

    public func analyze(path: String) -> PathEnvironment {
        let normalized = URL(fileURLWithPath: path).standardizedFileURL.path
        let isICloud = normalized.contains("/Library/Mobile Documents/") || normalized.contains("/Mobile Documents/")
        let isSharedICloud = isICloud && normalized.localizedCaseInsensitiveContains("shared")
        let isProtected = normalized.hasPrefix("/System/") || normalized.hasPrefix("/private/") || normalized.hasPrefix(NSHomeDirectory() + "/Library/")
        let isRemovable = normalized.hasPrefix("/Volumes/")
        let mayRequireHydration = isICloud

        var notes: [String] = []
        if isICloud {
            notes.append("This path appears to live in iCloud Drive or a File Provider area.")
            notes.append("Files may exist as placeholders and require hydration before a strict clone can be trusted.")
        }
        if isSharedICloud {
            notes.append("Shared iCloud folders may change while another person or device syncs new content.")
        }
        if isProtected {
            notes.append("This path sits in a protected macOS area and may require Full Disk Access or privileged operations.")
        }
        if isRemovable {
            notes.append("This path appears to be on a mounted volume under /Volumes.")
        }

        return PathEnvironment(
            path: normalized,
            isICloudDrive: isICloud,
            isInsideSharedICloudFolder: isSharedICloud,
            isInsideSystemProtectedArea: isProtected,
            isRemovableVolume: isRemovable,
            mayRequireHydration: mayRequireHydration,
            notes: notes
        )
    }
}
