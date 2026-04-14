import Testing
@testable import CloneWatchCore
import Foundation

@Test
func verificationFlagsMissingDestinationEntries() async throws {
    let source = InventorySnapshot(
        rootPath: "/tmp/source",
        createdAt: .now,
        depth: .explorable,
        entries: [
            InventoryEntry(relativePath: ".", absolutePath: "/tmp/source", itemType: "folder", size: nil, createdAt: nil, modifiedAt: nil, permissions: "755", ownerID: nil, groupID: nil, inode: nil, symlinkTarget: nil, checksum: nil, error: nil),
            InventoryEntry(relativePath: "a.txt", absolutePath: "/tmp/source/a.txt", itemType: "file", size: 10, createdAt: nil, modifiedAt: nil, permissions: "644", ownerID: nil, groupID: nil, inode: nil, symlinkTarget: nil, checksum: nil, error: nil),
        ]
    )
    let destination = InventorySnapshot(
        rootPath: "/tmp/destination",
        createdAt: .now,
        depth: .explorable,
        entries: [
            InventoryEntry(relativePath: ".", absolutePath: "/tmp/destination", itemType: "folder", size: nil, createdAt: nil, modifiedAt: nil, permissions: "755", ownerID: nil, groupID: nil, inode: nil, symlinkTarget: nil, checksum: nil, error: nil),
        ]
    )

    let result = VerificationEngine().compare(source: source, destination: destination)

    #expect(result.summary.missingCount == 1)
    #expect(result.summary.safeToDeleteSource == false)
}

@Test
func preflightRejectsIdenticalPaths() async throws {
    let job = CloneJob(
        source: Endpoint(kind: .folder, path: "/tmp/demo"),
        destination: Endpoint(kind: .folder, path: "/tmp/demo")
    )

    let result = PreflightChecker().run(job: job)

    #expect(result.canProceed == false)
}

@Test
func copyEngineBuildsIncrementalArgumentsWithoutDelete() async throws {
    let job = CloneJob(
        source: Endpoint(kind: .folder, path: "/tmp/source"),
        destination: Endpoint(kind: .folder, path: "/tmp/destination"),
        copyMode: .incremental
    )
    let engine = CopyEngine()
    let args = engine.buildRsyncArguments(job: job)
    #expect(args.contains("--delete") == false)
    #expect(args.contains("/tmp/source/"))
    #expect(args.contains("/tmp/destination/"))
}

@Test
func copyEngineParsesDryRunSummary() async throws {
    let output = """
    Number of regular files transferred: 42
    Total transferred file size: 1,234,567 bytes
    """
    let engine = CopyEngine()
    let summary = engine.parseDryRunSummary(output)
    #expect(summary == DryRunSummary(transferredFiles: 42, transferredBytes: 1_234_567))
}

@Test
func verificationSizeOnlyIgnoresPermissionDifferences() async throws {
    let source = InventorySnapshot(
        rootPath: "/tmp/source",
        createdAt: .now,
        depth: .explorable,
        entries: [
            InventoryEntry(relativePath: "a.txt", absolutePath: "/tmp/source/a.txt", itemType: "file", size: 10, createdAt: nil, modifiedAt: nil, permissions: "644", ownerID: nil, groupID: nil, inode: nil, symlinkTarget: nil, checksum: nil, error: nil),
        ]
    )
    let destination = InventorySnapshot(
        rootPath: "/tmp/destination",
        createdAt: .now,
        depth: .explorable,
        entries: [
            InventoryEntry(relativePath: "a.txt", absolutePath: "/tmp/destination/a.txt", itemType: "file", size: 10, createdAt: nil, modifiedAt: nil, permissions: "600", ownerID: nil, groupID: nil, inode: nil, symlinkTarget: nil, checksum: nil, error: nil),
        ]
    )

    let result = VerificationEngine().compare(source: source, destination: destination, mode: .sizeOnly)
    #expect(result.summary.warningCount == 0)
    #expect(result.summary.differentCount == 0)
}

@Test
func verificationMetadataFlagsPermissionDifferences() async throws {
    let source = InventorySnapshot(
        rootPath: "/tmp/source",
        createdAt: .now,
        depth: .explorable,
        entries: [
            InventoryEntry(relativePath: "a.txt", absolutePath: "/tmp/source/a.txt", itemType: "file", size: 10, createdAt: nil, modifiedAt: nil, permissions: "644", ownerID: nil, groupID: nil, inode: nil, symlinkTarget: nil, checksum: nil, error: nil),
        ]
    )
    let destination = InventorySnapshot(
        rootPath: "/tmp/destination",
        createdAt: .now,
        depth: .explorable,
        entries: [
            InventoryEntry(relativePath: "a.txt", absolutePath: "/tmp/destination/a.txt", itemType: "file", size: 10, createdAt: nil, modifiedAt: nil, permissions: "600", ownerID: nil, groupID: nil, inode: nil, symlinkTarget: nil, checksum: nil, error: nil),
        ]
    )

    let result = VerificationEngine().compare(source: source, destination: destination, mode: .metadata)
    #expect(result.summary.warningCount == 1)
    #expect(result.differences.first?.status == .differentMetadata)
}

@Test
func runtimeEmitsProgressSnapshotsForDocumentOnlyRun() async throws {
    let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("clonewatch-tests-\(UUID().uuidString)", isDirectory: true)
    let source = tempRoot.appendingPathComponent("source", isDirectory: true)
    let destination = tempRoot.appendingPathComponent("destination", isDirectory: true)
    try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
    try "hello".write(to: source.appendingPathComponent("a.txt"), atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: tempRoot) }

    let job = CloneJob(
        source: Endpoint(kind: .folder, path: source.path),
        destination: Endpoint(kind: .folder, path: destination.path),
        intent: .documentOnly,
        copyMode: .incremental
    )

    var snapshots: [RunProgressSnapshot] = []
    let result = try CloneWatchRuntime().execute(job: job, onProgress: { snapshots.append($0) })

    #expect(!snapshots.isEmpty)
    #expect(result.progressTimeline.count == snapshots.count)
    #expect(snapshots.contains(where: { $0.phase == .preflight && $0.state == .completed }))
    #expect(snapshots.contains(where: { $0.phase == .dryRun && $0.state == .skipped }))
    #expect(snapshots.contains(where: { $0.phase == .copy && $0.state == .skipped }))
    #expect(snapshots.contains(where: { $0.phase == .ledger && $0.state == .completed }))
}
