import Foundation
import CryptoKit

public struct InventoryEngine: Sendable {
    public init() {}

    public func scan(root: URL, depth: InventoryDepth, verificationMode: VerificationMode) -> InventorySnapshot {
        var entries: [InventoryEntry] = []
        let fm = FileManager.default
        let resourceKeys: Set<URLResourceKey> = [
            .isRegularFileKey,
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey,
            .fileResourceIdentifierKey,
            .volumeIdentifierKey,
            .parentDirectoryURLKey,
        ]

        if let rootEntry = makeEntry(url: root, relativePath: ".", depth: depth, verificationMode: verificationMode) {
            entries.append(rootEntry)
        }

        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsPackageDescendants],
            errorHandler: { url, error in
                let entry = InventoryEntry(
                    relativePath: url.path.replacingOccurrences(of: root.path + "/", with: ""),
                    absolutePath: url.path,
                    itemType: "error",
                    size: nil,
                    createdAt: nil,
                    modifiedAt: nil,
                    permissions: nil,
                    ownerID: nil,
                    groupID: nil,
                    inode: nil,
                    symlinkTarget: nil,
                    checksum: nil,
                    error: error.localizedDescription
                )
                entries.append(entry)
                return true
            }
        ) else {
            return InventorySnapshot(rootPath: root.path, createdAt: Date(), depth: depth, entries: entries)
        }

        for case let url as URL in enumerator {
            let relativePath = url.path.replacingOccurrences(of: root.path + "/", with: "")
            if relativePath.hasPrefix(".clonewatch/records") {
                continue
            }
            if let entry = makeEntry(url: url, relativePath: relativePath, depth: depth, verificationMode: verificationMode) {
                entries.append(entry)
            }
        }

        entries.sort { $0.relativePath < $1.relativePath }
        return InventorySnapshot(rootPath: root.path, createdAt: Date(), depth: depth, entries: entries)
    }

    private func makeEntry(url: URL, relativePath: String, depth: InventoryDepth, verificationMode: VerificationMode) -> InventoryEntry? {
        let path = url.path
        let fm = FileManager.default
        do {
            let values = try url.resourceValues(forKeys: [
                .isRegularFileKey,
                .isDirectoryKey,
                .isSymbolicLinkKey,
                .fileSizeKey,
                .creationDateKey,
                .contentModificationDateKey,
            ])
            let attrs = try fm.attributesOfItem(atPath: path)
            let type: String
            if values.isDirectory == true {
                type = "folder"
            } else if values.isSymbolicLink == true {
                type = "symlink"
            } else {
                type = "file"
            }

            let checksum: String?
            if type == "file" && (verificationMode == .checksumFull || depth == .forensic) {
                checksum = try? fileChecksum(url: url)
            } else {
                checksum = nil
            }

            let symlinkTarget: String?
            if type == "symlink" {
                symlinkTarget = try? fm.destinationOfSymbolicLink(atPath: path)
            } else {
                symlinkTarget = nil
            }

            return InventoryEntry(
                relativePath: relativePath,
                absolutePath: path,
                itemType: type,
                size: (attrs[.size] as? NSNumber)?.int64Value,
                createdAt: values.creationDate,
                modifiedAt: values.contentModificationDate,
                permissions: FileSystemHelper.permissionsString(for: path),
                ownerID: (attrs[.ownerAccountID] as? NSNumber)?.uint32Value,
                groupID: (attrs[.groupOwnerAccountID] as? NSNumber)?.uint32Value,
                inode: (attrs[.systemFileNumber] as? NSNumber)?.uint64Value,
                symlinkTarget: symlinkTarget,
                checksum: checksum,
                error: nil
            )
        } catch {
            return InventoryEntry(
                relativePath: relativePath,
                absolutePath: path,
                itemType: "error",
                size: nil,
                createdAt: nil,
                modifiedAt: nil,
                permissions: nil,
                ownerID: nil,
                groupID: nil,
                inode: nil,
                symlinkTarget: nil,
                checksum: nil,
                error: error.localizedDescription
            )
        }
    }

    private func fileChecksum(url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let data = try? handle.read(upToCount: 1024 * 1024)
            guard let data, !data.isEmpty else { return false }
            hasher.update(data: data)
            return true
        }) {}
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
