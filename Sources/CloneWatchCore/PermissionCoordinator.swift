import Foundation

public struct PermissionCoordinator: Sendable {
    public init() {}

    public func assess(job: CloneJob) -> [PermissionAssessment] {
        var items: [PermissionAssessment] = []

        items.append(
            PermissionAssessment(
                requirement: .userSelectedFileAccess,
                status: "required",
                detail: "CloneWatch should ask the user to choose source and destination paths through native macOS panels whenever possible."
            )
        )

        if needsFullDiskAccess(path: job.source.path) || needsFullDiskAccess(path: job.destination.path) {
            items.append(
                PermissionAssessment(
                    requirement: .fullDiskAccess,
                    status: "manual-system-setting",
                    detail: "macOS does not let apps silently grant Full Disk Access to themselves. CloneWatch must detect the need, explain it clearly, and guide the user to System Settings."
                )
            )
        }

        if job.source.kind == .volume || job.destination.kind == .volume || job.intent == .reinforceExistingClone {
            items.append(
                PermissionAssessment(
                    requirement: .removableMediaAccess,
                    status: "required",
                    detail: "External volumes must be mounted and readable before CloneWatch can work safely."
                )
            )
        }

        if job.intent == .initialClone || job.intent == .reinforceExistingClone {
            items.append(
                PermissionAssessment(
                    requirement: .administratorPrivileges,
                    status: "conditional",
                    detail: "Normal file copies can often run as the user, but deleting volumes, repartitioning disks, mounting/unmounting, and certain protected writes require a privileged helper."
                )
            )
        }

        let involvesCloud = job.source.path.contains("Mobile Documents") || job.destination.path.contains("Mobile Documents")
        if involvesCloud {
            items.append(
                PermissionAssessment(
                    requirement: .networkAvailability,
                    status: "conditional",
                    detail: "If iCloud-backed files are not fully downloaded, CloneWatch may need network access to hydrate placeholders before cloning."
                )
            )
        }

        return items
    }

    public func needsFullDiskAccess(path: String) -> Bool {
        let protectedPrefixes = [
            "/Library",
            "/System",
            "/private",
            "/Users",
        ]
        if path.hasPrefix(NSHomeDirectory() + "/Library") {
            return true
        }
        return protectedPrefixes.contains(where: { prefix in
            path == prefix || path.hasPrefix(prefix + "/")
        })
    }
}
