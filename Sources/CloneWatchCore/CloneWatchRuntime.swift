import Foundation

public struct CloneRunResult: Sendable {
    public var preflight: PreflightResult
    public var sourceSnapshot: InventorySnapshot
    public var destinationSnapshot: InventorySnapshot
    public var verification: VerificationResult
    public var ledger: LedgerOutput
    public var runLog: [RunLogEvent]
    public var progressTimeline: [RunProgressSnapshot]
}

public final class CloneWatchRuntime {
    private let preflightChecker = PreflightChecker()
    private let inventoryEngine = InventoryEngine()
    private let verificationEngine = VerificationEngine()
    private let copyEngine = CopyEngine()
    private let ledgerEngine = LedgerEngine()

    public init() {}

    public func execute(
        job: CloneJob,
        onProgress: ((RunProgressSnapshot) -> Void)? = nil
    ) throws -> CloneRunResult {
        var log: [RunLogEvent] = [RunLogEvent(level: "info", message: "CloneWatch started job \(job.id.uuidString).")]
        var progressTimeline: [RunProgressSnapshot] = []
        var phaseStarts: [RunPhase: Date] = [:]
        var previousPhase: RunPhase?

        func emit(
            phase: RunPhase,
            state: RunPhaseState,
            message: String,
            estimatedTransferFiles: Int64? = nil,
            estimatedTransferBytes: Int64? = nil
        ) {
            if state == .running {
                phaseStarts[phase] = Date()
            }
            let duration: Double?
            if state == .completed || state == .failed || state == .skipped, let start = phaseStarts[phase] {
                duration = Date().timeIntervalSince(start)
            } else {
                duration = nil
            }
            let snapshot = RunProgressSnapshot(
                phase: phase,
                state: state,
                previousPhase: previousPhase,
                overallPercent: overallPercent(for: phase, state: state),
                message: message,
                estimatedTransferFiles: estimatedTransferFiles,
                estimatedTransferBytes: estimatedTransferBytes,
                durationSeconds: duration
            )
            progressTimeline.append(snapshot)
            onProgress?(snapshot)
            previousPhase = phase
        }

        emit(phase: .preflight, state: .running, message: "Validating source and destination before any copy.")
        let preflight = preflightChecker.run(job: job)
        log.append(RunLogEvent(level: preflight.canProceed ? "info" : "error", message: "Preflight completed. Proceed=\(preflight.canProceed)"))
        guard preflight.canProceed else {
            emit(phase: .preflight, state: .failed, message: "Preflight failed. Clone was stopped.")
            throw CloneWatchError.invalidDestination("Preflight failed. Review the generated checks before copying.")
        }
        emit(phase: .preflight, state: .completed, message: "Preflight completed. Safe to continue.")

        try copyEngine.copy(job: job, logger: &log, onProgress: { event in
            switch event {
            case .skipped:
                emit(phase: .dryRun, state: .skipped, message: "Dry-run skipped because copy phase is not required for this intent.")
                emit(phase: .copy, state: .skipped, message: "Copy phase skipped because this is verify-only or document-only.")
            case .dryRunStarted:
                emit(phase: .dryRun, state: .running, message: "Estimating what would change before copying.")
            case .dryRunCompleted(let summary):
                emit(
                    phase: .dryRun,
                    state: .completed,
                    message: summary == nil ? "Dry-run completed." : "Dry-run estimated transfer scope.",
                    estimatedTransferFiles: summary?.transferredFiles,
                    estimatedTransferBytes: summary?.transferredBytes
                )
            case .copyStarted:
                emit(phase: .copy, state: .running, message: "Copying only what is needed to destination.")
            case .copyCompleted:
                emit(phase: .copy, state: .completed, message: "Copy phase completed.")
            }
        })

        emit(phase: .sourceScan, state: .running, message: "Scanning source inventory.")
        log.append(RunLogEvent(level: "info", message: "Starting source inventory scan."))
        let sourceSnapshot = inventoryEngine.scan(root: job.source.url, depth: job.inventoryDepth, verificationMode: job.verificationMode)
        emit(phase: .sourceScan, state: .completed, message: "Source inventory scan completed.")

        emit(phase: .destinationScan, state: .running, message: "Scanning destination inventory.")
        log.append(RunLogEvent(level: "info", message: "Starting destination inventory scan."))
        let destinationSnapshot = inventoryEngine.scan(root: job.destination.url, depth: job.inventoryDepth, verificationMode: job.verificationMode)
        emit(phase: .destinationScan, state: .completed, message: "Destination inventory scan completed.")

        emit(phase: .verify, state: .running, message: "Comparing source and destination inventories.")
        let verification = verificationEngine.compare(
            source: sourceSnapshot,
            destination: destinationSnapshot,
            mode: job.verificationMode
        )
        log.append(RunLogEvent(level: "info", message: "Verification finished with confidence \(verification.summary.confidence)."))
        emit(phase: .verify, state: .completed, message: "Verification completed with confidence \(verification.summary.confidence).")

        emit(phase: .ledger, state: .running, message: "Writing durable ledger and evidence bundle.")
        let ledger = try ledgerEngine.createBundle(
            job: job,
            preflight: preflight,
            sourceSnapshot: sourceSnapshot,
            destinationSnapshot: destinationSnapshot,
            verification: verification,
            runLog: log,
            progressTimeline: progressTimeline
        )
        log.append(RunLogEvent(level: "info", message: "Ledger written to \(ledger.centralBundleURL.path)."))
        emit(phase: .ledger, state: .completed, message: "Ledger written to \(ledger.centralBundleURL.path).")
        return CloneRunResult(
            preflight: preflight,
            sourceSnapshot: sourceSnapshot,
            destinationSnapshot: destinationSnapshot,
            verification: verification,
            ledger: ledger,
            runLog: log,
            progressTimeline: progressTimeline
        )
    }

    private func overallPercent(for phase: RunPhase, state: RunPhaseState) -> Double {
        let index = Double(RunPhase.allCases.firstIndex(of: phase) ?? 0)
        let total = Double(max(RunPhase.allCases.count, 1))
        let base = (index / total) * 100.0
        switch state {
        case .running:
            return min(99.0, base + (100.0 / total) * 0.5)
        case .completed, .skipped:
            return min(100.0, ((index + 1.0) / total) * 100.0)
        case .failed:
            return min(100.0, base)
        case .pending:
            return base
        }
    }
}
