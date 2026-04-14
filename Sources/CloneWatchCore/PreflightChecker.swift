import Foundation

public struct PreflightChecker: Sendable {
    public init() {}

    public func run(job: CloneJob) -> PreflightResult {
        var checks: [PreflightCheck] = []
        let permissions = PermissionCoordinator().assess(job: job)
        let pathAnalyzer = PathEnvironmentAnalyzer()
        let sourceEnvironment = pathAnalyzer.analyze(path: job.source.path)
        let destinationEnvironment = pathAnalyzer.analyze(path: job.destination.path)
        let risks = RiskAssessmentEngine().assess(job: job, source: sourceEnvironment, destination: destinationEnvironment)
        let sourceURL = job.source.url
        let destinationURL = job.destination.url
        let fm = FileManager.default

        let sourceExists = fm.fileExists(atPath: sourceURL.path)
        checks.append(
            PreflightCheck(
                label: "Source exists",
                passed: sourceExists,
                detail: sourceExists ? "Found source at \(sourceURL.path)." : "Source path does not exist."
            )
        )

        let destinationParent = destinationURL.deletingLastPathComponent().path
        let destinationParentExists = fm.fileExists(atPath: destinationParent)
        checks.append(
            PreflightCheck(
                label: "Destination parent exists",
                passed: destinationParentExists,
                detail: destinationParentExists ? "Parent folder is available." : "Create the destination parent before running."
            )
        )

        let sourceReadable = fm.isReadableFile(atPath: sourceURL.path)
        checks.append(
            PreflightCheck(
                label: "Source is readable",
                passed: sourceReadable,
                detail: sourceReadable ? "CloneWatch can read the source." : "CloneWatch cannot read the source path."
            )
        )

        let samePath = sourceURL.standardizedFileURL == destinationURL.standardizedFileURL
        checks.append(
            PreflightCheck(
                label: "Source and destination differ",
                passed: !samePath,
                detail: samePath ? "Source and destination are the same path." : "Source and destination are different."
            )
        )

        let destinationWritable = fm.isWritableFile(atPath: destinationParent)
        checks.append(
            PreflightCheck(
                label: "Destination parent is writable",
                passed: destinationWritable,
                detail: destinationWritable ? "CloneWatch can create records and copies." : "Destination parent is not writable."
            )
        )

        let hiddenRecordPath = destinationURL.appendingPathComponent(".clonewatch").path
        let isNested = destinationURL.path.hasPrefix(sourceURL.path + "/")
        checks.append(
            PreflightCheck(
                label: "Destination is not nested inside source",
                passed: !isNested,
                detail: isNested ? "Nested destinations create recursive clone risks." : "No recursive nesting detected."
            )
        )

        checks.append(
            PreflightCheck(
                label: "Record folder reserved",
                passed: !hiddenRecordPath.isEmpty,
                detail: "CloneWatch will use .clonewatch/records for local evidence bundles."
            )
        )

        if sourceEnvironment.isICloudDrive || destinationEnvironment.isICloudDrive {
            checks.append(
                PreflightCheck(
                    label: "Cloud hydration recommended",
                    passed: true,
                    detail: "At least one endpoint is in iCloud Drive. CloneWatch should verify that required files are downloaded locally before strict verification."
                )
            )
        }

        return PreflightResult(
            checks: checks,
            permissions: permissions,
            sourceEnvironment: sourceEnvironment,
            destinationEnvironment: destinationEnvironment,
            risks: risks
        )
    }
}
