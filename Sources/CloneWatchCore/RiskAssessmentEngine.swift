import Foundation

public struct RiskAssessmentEngine: Sendable {
    public init() {}

    public func assess(job: CloneJob, source: PathEnvironment, destination: PathEnvironment) -> [StorageRisk] {
        var risks: [StorageRisk] = []

        if source.isICloudDrive || destination.isICloudDrive {
            risks.append(
                StorageRisk(
                    title: "Cloud-backed path detected",
                    level: .high,
                    detail: "iCloud Drive paths can contain placeholders, in-flight sync operations, or shared-folder mutations. CloneWatch should hydrate and stabilize them before high-confidence cloning."
                )
            )
        }

        if source.isInsideSharedICloudFolder || destination.isInsideSharedICloudFolder {
            risks.append(
                StorageRisk(
                    title: "Shared iCloud folder",
                    level: .high,
                    detail: "Another person or another device can change the tree while the clone is running, which weakens consistency guarantees."
                )
            )
        }

        if source.isInsideSystemProtectedArea || destination.isInsideSystemProtectedArea {
            risks.append(
                StorageRisk(
                    title: "Protected macOS location",
                    level: .medium,
                    detail: "Protected locations often need Full Disk Access and extra validation. Some sealed system paths cannot be safely modified even as root."
                )
            )
        }

        if job.source.path == "/" || job.destination.path == "/" {
            risks.append(
                StorageRisk(
                    title: "Root filesystem path",
                    level: .critical,
                    detail: "Using / directly as source or destination is too broad and too dangerous for CloneWatch v2. Choose a narrower root or operate through a controlled privileged module."
                )
            )
        }

        if job.source.kind == .volume && job.destination.kind == .volume {
            risks.append(
                StorageRisk(
                    title: "Volume-to-volume workflow",
                    level: .medium,
                    detail: "Mounted volumes may require mount-state checks, APFS topology discovery, and careful destructive-action boundaries."
                )
            )
        }

        return risks
    }
}
