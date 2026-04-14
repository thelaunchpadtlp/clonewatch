import Foundation

public struct LedgerOutput: Sendable {
    public var centralBundleURL: URL
    public var placementURLs: [URL]
}

public struct LedgerEngine: Sendable {
    public init() {}

    public func createBundle(
        job: CloneJob,
        preflight: PreflightResult,
        sourceSnapshot: InventorySnapshot,
        destinationSnapshot: InventorySnapshot,
        verification: VerificationResult,
        runLog: [RunLogEvent],
        progressTimeline: [RunProgressSnapshot]
    ) throws -> LedgerOutput {
        let centralRoot = try centralRecordsRoot()
        let bundleRoot = centralRoot.appendingPathComponent(job.id.uuidString, isDirectory: true)
        try FileSystemHelper.ensureDirectory(bundleRoot)

        let reportEngine = ReportEngine()
        try FileSystemHelper.writeJSON(job, to: bundleRoot.appendingPathComponent("job-spec.json"))
        try FileSystemHelper.writeJSON(runLog, to: bundleRoot.appendingPathComponent("run-log.json"))
        try FileSystemHelper.writeJSON(progressTimeline, to: bundleRoot.appendingPathComponent("run-progress.json"))
        try FileSystemHelper.writeJSON(verification, to: bundleRoot.appendingPathComponent("diff-report.json"))
        try FileSystemHelper.writeJSON(sourceSnapshot, to: bundleRoot.appendingPathComponent("source-index.json"))
        try FileSystemHelper.writeJSON(destinationSnapshot, to: bundleRoot.appendingPathComponent("destination-index.json"))
        try FileSystemHelper.writeText(
            reportEngine.makeSummaryMarkdown(job: job, preflight: preflight, verification: verification),
            to: bundleRoot.appendingPathComponent("summary.md")
        )
        try FileSystemHelper.writeText(
            reportEngine.makeDecisionMarkdown(verification: verification),
            to: bundleRoot.appendingPathComponent("decision-report.md")
        )
        try FileSystemHelper.writeText(
            reportEngine.makeInventoryMarkdown(title: "Source Inventory Summary", snapshot: sourceSnapshot),
            to: bundleRoot.appendingPathComponent("source-index.md")
        )
        try FileSystemHelper.writeText(
            reportEngine.makeInventoryMarkdown(title: "Destination Inventory Summary", snapshot: destinationSnapshot),
            to: bundleRoot.appendingPathComponent("destination-index.md")
        )
        try FileSystemHelper.writeText(
            reportEngine.makeHTMLReport(job: job, verification: verification),
            to: bundleRoot.appendingPathComponent("report.html")
        )
        try writeSQLite(snapshot: sourceSnapshot, to: bundleRoot.appendingPathComponent("source-index.sqlite"))
        try writeSQLite(snapshot: destinationSnapshot, to: bundleRoot.appendingPathComponent("destination-index.sqlite"))

        let artifacts = try FileManager.default.contentsOfDirectory(atPath: bundleRoot.path).sorted()
        let manifest = AuditBundleManifest(
            jobID: job.id,
            generatedAt: Date(),
            artifacts: artifacts,
            placements: job.recordPlacements.map(\.rawValue)
        )
        try FileSystemHelper.writeJSON(manifest, to: bundleRoot.appendingPathComponent("artifacts-manifest.json"))

        let placementURLs = try replicateBundle(job: job, sourceBundle: bundleRoot)
        return LedgerOutput(centralBundleURL: bundleRoot, placementURLs: placementURLs)
    }

    private func centralRecordsRoot() throws -> URL {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/CloneWatch/Jobs", isDirectory: true)
        try FileSystemHelper.ensureDirectory(base)
        return base
    }

    private func replicateBundle(job: CloneJob, sourceBundle: URL) throws -> [URL] {
        var urls: [URL] = []
        for placement in job.recordPlacements {
            let base: URL
            switch placement {
            case .central:
                continue
            case .source:
                base = job.source.url
            case .destination:
                base = job.destination.url
            }
            let target = base
                .appendingPathComponent(".clonewatch/records", isDirectory: true)
                .appendingPathComponent(job.id.uuidString, isDirectory: true)
            try FileSystemHelper.ensureDirectory(target.deletingLastPathComponent())
            if FileManager.default.fileExists(atPath: target.path) {
                try FileManager.default.removeItem(at: target)
            }
            try FileManager.default.copyItem(at: sourceBundle, to: target)
            urls.append(target)
        }
        return urls
    }

    private func writeSQLite(snapshot: InventorySnapshot, to url: URL) throws {
        let tempSQL = url.deletingPathExtension().appendingPathExtension("sql")
        var sql = """
        PRAGMA journal_mode=WAL;
        CREATE TABLE IF NOT EXISTS inventory (
          relative_path TEXT PRIMARY KEY,
          absolute_path TEXT,
          item_type TEXT,
          size INTEGER,
          created_at TEXT,
          modified_at TEXT,
          permissions TEXT,
          owner_id INTEGER,
          group_id INTEGER,
          inode INTEGER,
          symlink_target TEXT,
          checksum TEXT,
          error TEXT
        );

        """
        for entry in snapshot.entries {
            sql += """
            INSERT OR REPLACE INTO inventory (
              relative_path, absolute_path, item_type, size, created_at, modified_at,
              permissions, owner_id, group_id, inode, symlink_target, checksum, error
            ) VALUES (
              \(quoted(entry.relativePath)),
              \(quoted(entry.absolutePath)),
              \(quoted(entry.itemType)),
              \(entry.size.map(String.init) ?? "NULL"),
              \(quoted(entry.createdAt.map(FileSystemHelper.isoString(from:)))),
              \(quoted(entry.modifiedAt.map(FileSystemHelper.isoString(from:)))),
              \(quoted(entry.permissions)),
              \(entry.ownerID.map(String.init) ?? "NULL"),
              \(entry.groupID.map(String.init) ?? "NULL"),
              \(entry.inode.map(String.init) ?? "NULL"),
              \(quoted(entry.symlinkTarget)),
              \(quoted(entry.checksum)),
              \(quoted(entry.error))
            );

            """
        }
        try FileSystemHelper.writeText(sql, to: tempSQL)
        let command = "sqlite3 \(shellQuoted(url.path)) < \(shellQuoted(tempSQL.path))"
        _ = try FileSystemHelper.runProcess("/bin/sh", ["-lc", command])
        try? FileManager.default.removeItem(at: tempSQL)
    }

    private func quoted(_ string: String?) -> String {
        guard let string else { return "NULL" }
        let escaped = string.replacingOccurrences(of: "'", with: "''")
        return "'\(escaped)'"
    }

    private func shellQuoted(_ string: String) -> String {
        "'" + string.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
    }
}
