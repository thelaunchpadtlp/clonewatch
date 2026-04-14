import Foundation

public struct VerificationEngine: Sendable {
    public init() {}

    public func compare(
        source: InventorySnapshot,
        destination: InventorySnapshot,
        mode: VerificationMode = .metadata
    ) -> VerificationResult {
        let sourceMap = Dictionary(uniqueKeysWithValues: source.entries.map { ($0.relativePath, $0) })
        let destinationMap = Dictionary(uniqueKeysWithValues: destination.entries.map { ($0.relativePath, $0) })
        let allKeys = Set(sourceMap.keys).union(destinationMap.keys).sorted()

        var differences: [DifferenceEntry] = []
        var identicalCount = 0
        var missingCount = 0
        var extraCount = 0
        var differentCount = 0
        var warningCount = 0

        for key in allKeys {
            let a = sourceMap[key]
            let b = destinationMap[key]

            switch (a, b) {
            case let (lhs?, rhs?):
                if lhs.error != nil || rhs.error != nil {
                    differences.append(
                        DifferenceEntry(
                            relativePath: key,
                            status: .error,
                            sourceSize: lhs.size,
                            destinationSize: rhs.size,
                            detail: lhs.error ?? rhs.error ?? "Unknown inventory error"
                        )
                    )
                    warningCount += 1
                } else if lhs.itemType != rhs.itemType {
                    differences.append(
                        DifferenceEntry(
                            relativePath: key,
                            status: .differentMetadata,
                            sourceSize: lhs.size,
                            destinationSize: rhs.size,
                            detail: "Types differ: \(lhs.itemType) vs \(rhs.itemType)"
                        )
                    )
                    differentCount += 1
                } else if lhs.size != rhs.size {
                    differences.append(
                        DifferenceEntry(
                            relativePath: key,
                            status: .differentSize,
                            sourceSize: lhs.size,
                            destinationSize: rhs.size,
                            detail: "Sizes differ."
                        )
                    )
                    differentCount += 1
                } else if shouldCompareChecksums(mode: mode, lhs: lhs, rhs: rhs) {
                    differences.append(
                        DifferenceEntry(
                            relativePath: key,
                            status: .differentChecksum,
                            sourceSize: lhs.size,
                            destinationSize: rhs.size,
                            detail: "Checksums differ."
                        )
                    )
                    differentCount += 1
                } else if shouldCompareMetadata(mode: mode), let detail = metadataDifferenceDetail(lhs: lhs, rhs: rhs) {
                    differences.append(
                        DifferenceEntry(
                            relativePath: key,
                            status: .differentMetadata,
                            sourceSize: lhs.size,
                            destinationSize: rhs.size,
                            detail: detail
                        )
                    )
                    warningCount += 1
                } else {
                    identicalCount += 1
                }
            case let (lhs?, nil):
                differences.append(
                    DifferenceEntry(
                        relativePath: key,
                        status: .missingFromDestination,
                        sourceSize: lhs.size,
                        destinationSize: nil,
                        detail: "Present in source, missing from destination."
                    )
                )
                missingCount += 1
            case let (nil, rhs?):
                differences.append(
                    DifferenceEntry(
                        relativePath: key,
                        status: .extraInDestination,
                        sourceSize: nil,
                        destinationSize: rhs.size,
                        detail: "Present in destination, missing from source."
                    )
                )
                extraCount += 1
            case (nil, nil):
                continue
            }
        }

        let safeToDelete = missingCount == 0 && differentCount == 0 && warningCount == 0
        let confidence: String
        if safeToDelete {
            confidence = "green"
        } else if missingCount == 0 && differentCount <= 10 {
            confidence = "yellow"
        } else {
            confidence = "red"
        }

        return VerificationResult(
            createdAt: Date(),
            sourceRoot: source.rootPath,
            destinationRoot: destination.rootPath,
            differences: differences,
            summary: VerificationSummary(
                identicalCount: identicalCount,
                missingCount: missingCount,
                extraCount: extraCount,
                differentCount: differentCount,
                warningCount: warningCount,
                confidence: confidence,
                safeToDeleteSource: safeToDelete
            )
        )
    }

    private func shouldCompareMetadata(mode: VerificationMode) -> Bool {
        mode != .sizeOnly
    }

    private func shouldCompareChecksums(mode: VerificationMode, lhs: InventoryEntry, rhs: InventoryEntry) -> Bool {
        guard mode == .checksumFull || mode == .checksumSampled else { return false }
        guard let lhsChecksum = lhs.checksum, let rhsChecksum = rhs.checksum else { return false }
        return lhsChecksum != rhsChecksum
    }

    private func metadataDifferenceDetail(lhs: InventoryEntry, rhs: InventoryEntry) -> String? {
        if lhs.permissions != rhs.permissions {
            return "Permissions differ."
        }
        if lhs.modifiedAt != rhs.modifiedAt {
            return "Modification dates differ."
        }
        if lhs.symlinkTarget != rhs.symlinkTarget {
            return "Symlink targets differ."
        }
        return nil
    }
}
