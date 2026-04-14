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

        var arguments = ["-aEH", "--human-readable", "--itemize-changes", "--stats", "--progress"]
        switch job.copyMode {
        case .clone, .mirror:
            arguments.append("--delete")
        case .incremental:
            break
        }
        if job.intent == .reinforceExistingClone {
            logger.append(
                RunLogEvent(
                    level: "info",
                    message: "Reinforcement mode uses rsync to copy only what changed, so unchanged files are not recopied."
                )
            )
        }
        arguments.append(contentsOf: [source, destination])

        logger.append(RunLogEvent(level: "info", message: "Starting rsync copy from \(source) to \(destination)."))
        let rsyncOutput = try FileSystemHelper.runProcess("/usr/bin/rsync", arguments)
        logger.append(RunLogEvent(level: "info", message: rsyncOutput))
        logger.append(RunLogEvent(level: "info", message: "Copy phase finished successfully."))
    }
}
