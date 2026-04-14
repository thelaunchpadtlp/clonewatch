import Foundation

public struct CopyEngine: Sendable {
    public init() {}

    public func copy(job: CloneJob, logger: inout [RunLogEvent]) throws {
        if job.intent == .verifyExistingClone || job.intent == .documentOnly {
            logger.append(RunLogEvent(level: "info", message: "Skipping copy phase because the job intent is \(job.intent.rawValue)."))
            return
        }

        let source = job.source.url.path + "/"
        let destination = job.destination.url.path + "/"
        let destinationParent = job.destination.url.deletingLastPathComponent()
        try FileSystemHelper.ensureDirectory(destinationParent)
        if !FileManager.default.fileExists(atPath: job.destination.url.path) {
            try FileSystemHelper.ensureDirectory(job.destination.url)
        }

        let arguments = buildRsyncArguments(job: job)
        if job.intent == .reinforceExistingClone {
            logger.append(
                RunLogEvent(
                    level: "info",
                    message: "Reinforcement mode uses rsync to copy only what changed, so unchanged files are not recopied."
                )
            )
        }
        let dryRunOutput = try FileSystemHelper.runProcess(
            "/usr/bin/rsync",
            dryRunArguments(for: arguments)
        )
        if let summary = parseDryRunSummary(dryRunOutput) {
            logger.append(
                RunLogEvent(
                    level: "info",
                    message: "Dry-run estimate: \(summary.transferredFiles) files to transfer, \(summary.transferredBytes) bytes."
                )
            )
        } else {
            logger.append(RunLogEvent(level: "info", message: "Dry-run completed. Could not parse transfer counts from rsync output."))
        }

        logger.append(RunLogEvent(level: "info", message: "Starting rsync copy from \(source) to \(destination)."))
        let rsyncOutput = try FileSystemHelper.runProcess("/usr/bin/rsync", arguments)
        logger.append(RunLogEvent(level: "info", message: rsyncOutput))
        logger.append(RunLogEvent(level: "info", message: "Copy phase finished successfully."))
    }

    func buildRsyncArguments(job: CloneJob) -> [String] {
        var arguments = ["-aEH", "--human-readable", "--itemize-changes", "--stats", "--progress"]
        switch job.copyMode {
        case .clone, .mirror:
            arguments.append("--delete")
        case .incremental:
            break
        }
        arguments.append(contentsOf: [job.source.url.path + "/", job.destination.url.path + "/"])
        return arguments
    }

    func dryRunArguments(for executionArguments: [String]) -> [String] {
        var args = executionArguments
        if !args.contains("--dry-run") {
            args.insert("--dry-run", at: 0)
        }
        args.removeAll(where: { $0 == "--progress" })
        return args
    }

    func parseDryRunSummary(_ output: String) -> DryRunSummary? {
        let transferredFiles = firstInt(in: output, after: "Number of regular files transferred:")
        let transferredBytes = firstInt(in: output, after: "Total transferred file size:")
        guard let transferredFiles, let transferredBytes else {
            return nil
        }
        return DryRunSummary(transferredFiles: transferredFiles, transferredBytes: transferredBytes)
    }

    private func firstInt(in text: String, after label: String) -> Int64? {
        guard let range = text.range(of: label) else { return nil }
        let suffix = text[range.upperBound...]
        let line = suffix.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        let digits = line.replacingOccurrences(of: ",", with: "")
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .first(where: { !$0.isEmpty })
        guard let raw = digits else { return nil }
        return Int64(raw)
    }
}

struct DryRunSummary: Sendable, Equatable {
    let transferredFiles: Int64
    let transferredBytes: Int64
}
