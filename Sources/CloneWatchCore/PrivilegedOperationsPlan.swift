import Foundation

public struct PrivilegedOperation: Codable, Sendable {
    public var title: String
    public var detail: String
    public var destructive: Bool
}

public struct PrivilegedOperationsPlan: Codable, Sendable {
    public var operations: [PrivilegedOperation]
}

public struct DiskOperationsPlanner: Sendable {
    public init() {}

    public func plan(for job: CloneJob) -> PrivilegedOperationsPlan {
        var operations: [PrivilegedOperation] = []

        if job.source.kind == .volume || job.destination.kind == .volume {
            operations.append(
                PrivilegedOperation(
                    title: "Mount / unmount volume",
                    detail: "Volume workflows may need mount-state control and safety checks before or after the clone.",
                    destructive: false
                )
            )
        }

        operations.append(
            PrivilegedOperation(
                title: "Delete or archive source volume after verified cutover",
                detail: "This is a future DiskOps action, not part of the copy itself. It must live behind a privileged helper, explicit identity checks, and a separate confirmation boundary.",
                destructive: true
            )
        )

        operations.append(
            PrivilegedOperation(
                title: "Resize partitions or APFS containers",
                detail: "Disk Utility-level topology changes require administrator privileges, topology discovery, and rollback-aware planning.",
                destructive: true
            )
        )

        return PrivilegedOperationsPlan(operations: operations)
    }
}
