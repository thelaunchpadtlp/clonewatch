import Testing
@testable import CloneWatchCore

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
