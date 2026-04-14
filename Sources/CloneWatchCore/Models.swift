import Foundation

public enum EndpointKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case volume
    case folder

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .volume:
            return "Volume"
        case .folder:
            return "Folder"
        }
    }
}

public enum CopyMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case clone
    case mirror
    case incremental

    public var id: String { rawValue }

    public var displayName: String {
        rawValue.capitalized
    }
}

public enum JobIntent: String, Codable, CaseIterable, Identifiable, Sendable {
    case initialClone = "initial-clone"
    case reinforceExistingClone = "reinforce-existing-clone"
    case verifyExistingClone = "verify-existing-clone"
    case documentOnly = "document-only"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .initialClone:
            return "Initial Clone"
        case .reinforceExistingClone:
            return "Reinforce Existing Clone"
        case .verifyExistingClone:
            return "Verify Existing Clone"
        case .documentOnly:
            return "Document Only"
        }
    }
}

public enum VerificationMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case sizeOnly = "size-only"
    case metadata
    case checksumSampled = "checksum-sampled"
    case checksumFull = "checksum-full"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sizeOnly:
            return "Size Only"
        case .metadata:
            return "Metadata + Size"
        case .checksumSampled:
            return "Sampled Checksums"
        case .checksumFull:
            return "Full Checksums"
        }
    }
}

public enum PostActionPolicy: String, Codable, CaseIterable, Identifiable, Sendable {
    case keepBoth = "keep-both"
    case archiveSource = "archive-source"
    case deleteSource = "delete-source"
    case mergeLater = "merge-later"
    case manualDecision = "manual-decision"

    public var id: String { rawValue }
}

public enum RecordPlacement: String, Codable, CaseIterable, Identifiable, Sendable {
    case source
    case destination
    case central

    public var id: String { rawValue }
}

public enum JobState: String, Codable, CaseIterable, Sendable {
    case planned
    case preflightPassed = "preflight-passed"
    case copying
    case verifying
    case completedWithMatch = "completed-with-match"
    case completedWithDifferences = "completed-with-differences"
    case failed
    case cancelled
}

public enum PermissionRequirement: String, Codable, CaseIterable, Identifiable, Sendable {
    case userSelectedFileAccess = "user-selected-file-access"
    case fullDiskAccess = "full-disk-access"
    case administratorPrivileges = "administrator-privileges"
    case removableMediaAccess = "removable-media-access"
    case networkAvailability = "network-availability"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .userSelectedFileAccess:
            return "User-selected file access"
        case .fullDiskAccess:
            return "Full Disk Access"
        case .administratorPrivileges:
            return "Administrator privileges"
        case .removableMediaAccess:
            return "Removable media access"
        case .networkAvailability:
            return "Network availability"
        }
    }
}

public enum RiskLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case low
    case medium
    case high
    case critical

    public var id: String { rawValue }
}

public enum InventoryDepth: String, Codable, CaseIterable, Identifiable, Sendable {
    case explorable
    case forensic

    public var id: String { rawValue }
}

public enum DifferenceStatus: String, Codable, CaseIterable, Sendable {
    case identical
    case missingFromDestination = "missing-from-destination"
    case extraInDestination = "extra-in-destination"
    case differentSize = "different-size"
    case differentMetadata = "different-metadata"
    case differentChecksum = "different-checksum"
    case error
}

public struct Endpoint: Codable, Hashable, Sendable {
    public var kind: EndpointKind
    public var path: String

    public init(kind: EndpointKind, path: String) {
        self.kind = kind
        self.path = path
    }

    public var url: URL {
        URL(fileURLWithPath: path)
    }
}

public struct CloneJob: Codable, Identifiable, Sendable {
    public var id: UUID
    public var createdAt: Date
    public var source: Endpoint
    public var destination: Endpoint
    public var intent: JobIntent
    public var copyMode: CopyMode
    public var verificationMode: VerificationMode
    public var postActionPolicy: PostActionPolicy
    public var reportLocation: String?
    public var recordPlacements: [RecordPlacement]
    public var state: JobState
    public var inventoryDepth: InventoryDepth

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        source: Endpoint,
        destination: Endpoint,
        intent: JobIntent = .initialClone,
        copyMode: CopyMode = .clone,
        verificationMode: VerificationMode = .metadata,
        postActionPolicy: PostActionPolicy = .manualDecision,
        reportLocation: String? = nil,
        recordPlacements: [RecordPlacement] = [.source, .destination, .central],
        state: JobState = .planned,
        inventoryDepth: InventoryDepth = .explorable
    ) {
        self.id = id
        self.createdAt = createdAt
        self.source = source
        self.destination = destination
        self.intent = intent
        self.copyMode = copyMode
        self.verificationMode = verificationMode
        self.postActionPolicy = postActionPolicy
        self.reportLocation = reportLocation
        self.recordPlacements = recordPlacements
        self.state = state
        self.inventoryDepth = inventoryDepth
    }
}

public struct PreflightCheck: Codable, Sendable {
    public var label: String
    public var passed: Bool
    public var detail: String

    public init(label: String, passed: Bool, detail: String) {
        self.label = label
        self.passed = passed
        self.detail = detail
    }
}

public struct PermissionAssessment: Codable, Sendable {
    public var requirement: PermissionRequirement
    public var status: String
    public var detail: String

    public init(requirement: PermissionRequirement, status: String, detail: String) {
        self.requirement = requirement
        self.status = status
        self.detail = detail
    }
}

public struct PathEnvironment: Codable, Sendable {
    public var path: String
    public var isICloudDrive: Bool
    public var isInsideSharedICloudFolder: Bool
    public var isInsideSystemProtectedArea: Bool
    public var isRemovableVolume: Bool
    public var mayRequireHydration: Bool
    public var notes: [String]

    public init(
        path: String,
        isICloudDrive: Bool,
        isInsideSharedICloudFolder: Bool,
        isInsideSystemProtectedArea: Bool,
        isRemovableVolume: Bool,
        mayRequireHydration: Bool,
        notes: [String]
    ) {
        self.path = path
        self.isICloudDrive = isICloudDrive
        self.isInsideSharedICloudFolder = isInsideSharedICloudFolder
        self.isInsideSystemProtectedArea = isInsideSystemProtectedArea
        self.isRemovableVolume = isRemovableVolume
        self.mayRequireHydration = mayRequireHydration
        self.notes = notes
    }
}

public struct StorageRisk: Codable, Sendable {
    public var title: String
    public var level: RiskLevel
    public var detail: String

    public init(title: String, level: RiskLevel, detail: String) {
        self.title = title
        self.level = level
        self.detail = detail
    }
}

public struct PreflightResult: Codable, Sendable {
    public var checks: [PreflightCheck]
    public var permissions: [PermissionAssessment]
    public var sourceEnvironment: PathEnvironment?
    public var destinationEnvironment: PathEnvironment?
    public var risks: [StorageRisk]
    public var canProceed: Bool

    public init(
        checks: [PreflightCheck],
        permissions: [PermissionAssessment] = [],
        sourceEnvironment: PathEnvironment? = nil,
        destinationEnvironment: PathEnvironment? = nil,
        risks: [StorageRisk] = []
    ) {
        self.checks = checks
        self.permissions = permissions
        self.sourceEnvironment = sourceEnvironment
        self.destinationEnvironment = destinationEnvironment
        self.risks = risks
        self.canProceed = checks.allSatisfy(\.passed) && !risks.contains(where: { $0.level == .critical })
    }
}

public struct InventoryEntry: Codable, Sendable {
    public var relativePath: String
    public var absolutePath: String
    public var itemType: String
    public var size: Int64?
    public var createdAt: Date?
    public var modifiedAt: Date?
    public var permissions: String?
    public var ownerID: UInt32?
    public var groupID: UInt32?
    public var inode: UInt64?
    public var symlinkTarget: String?
    public var checksum: String?
    public var error: String?
}

public struct InventorySnapshot: Codable, Sendable {
    public var rootPath: String
    public var createdAt: Date
    public var depth: InventoryDepth
    public var entries: [InventoryEntry]
}

public struct DifferenceEntry: Codable, Sendable {
    public var relativePath: String
    public var status: DifferenceStatus
    public var sourceSize: Int64?
    public var destinationSize: Int64?
    public var detail: String
}

public struct VerificationSummary: Codable, Sendable {
    public var identicalCount: Int
    public var missingCount: Int
    public var extraCount: Int
    public var differentCount: Int
    public var warningCount: Int
    public var confidence: String
    public var safeToDeleteSource: Bool
}

public struct VerificationResult: Codable, Sendable {
    public var createdAt: Date
    public var sourceRoot: String
    public var destinationRoot: String
    public var differences: [DifferenceEntry]
    public var summary: VerificationSummary
}

public struct RunLogEvent: Codable, Sendable {
    public var timestamp: Date
    public var level: String
    public var message: String

    public init(timestamp: Date = Date(), level: String, message: String) {
        self.timestamp = timestamp
        self.level = level
        self.message = message
    }
}

public struct AuditBundleManifest: Codable, Sendable {
    public var jobID: UUID
    public var generatedAt: Date
    public var artifacts: [String]
    public var placements: [String]
}

public struct ProjectMemoryEntry: Codable, Sendable {
    public var title: String
    public var updatedAt: Date
    public var summary: String
}
