import Foundation

public struct CloneRunResult: Sendable {
    public var preflight: PreflightResult
    public var sourceSnapshot: InventorySnapshot
    public var destinationSnapshot: InventorySnapshot
    public var verification: VerificationResult
    public var ledger: LedgerOutput
    public var runLog: [RunLogEvent]
}

public final class CloneWatchRuntime {
    private let preflightChecker = PreflightChecker()
    private let inventoryEngine = InventoryEngine()
    private let verificationEngine = VerificationEngine()
    private let copyEngine = CopyEngine()
    private let ledgerEngine = LedgerEngine()

    public init() {}

    public func execute(job: CloneJob) throws -> CloneRunResult {
        var log: [RunLogEvent] = [RunLogEvent(level: "info", message: "CloneWatch started job \(job.id.uuidString).")]
        let preflight = preflightChecker.run(job: job)
        log.append(RunLogEvent(level: preflight.canProceed ? "info" : "error", message: "Preflight completed. Proceed=\(preflight.canProceed)"))
        guard preflight.canProceed else {
            throw CloneWatchError.invalidDestination("Preflight failed. Review the generated checks before copying.")
        }

        try copyEngine.copy(job: job, logger: &log)
        log.append(RunLogEvent(level: "info", message: "Starting source inventory scan."))
        let sourceSnapshot = inventoryEngine.scan(root: job.source.url, depth: job.inventoryDepth, verificationMode: job.verificationMode)
        log.append(RunLogEvent(level: "info", message: "Starting destination inventory scan."))
        let destinationSnapshot = inventoryEngine.scan(root: job.destination.url, depth: job.inventoryDepth, verificationMode: job.verificationMode)
        let verification = verificationEngine.compare(source: sourceSnapshot, destination: destinationSnapshot)
        log.append(RunLogEvent(level: "info", message: "Verification finished with confidence \(verification.summary.confidence)."))
        let ledger = try ledgerEngine.createBundle(
            job: job,
            preflight: preflight,
            sourceSnapshot: sourceSnapshot,
            destinationSnapshot: destinationSnapshot,
            verification: verification,
            runLog: log
        )
        log.append(RunLogEvent(level: "info", message: "Ledger written to \(ledger.centralBundleURL.path)."))
        return CloneRunResult(
            preflight: preflight,
            sourceSnapshot: sourceSnapshot,
            destinationSnapshot: destinationSnapshot,
            verification: verification,
            ledger: ledger,
            runLog: log
        )
    }
}
