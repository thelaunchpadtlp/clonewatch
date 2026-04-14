import SwiftUI
import AppKit
import CloneWatchCore

@main
struct CloneWatchMacApp: App {
    @StateObject private var viewModel = CloneWizardViewModel()

    var body: some Scene {
        WindowGroup("CloneWatch") {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 1080, minHeight: 760)
        }
        .windowResizability(.contentSize)
    }
}

enum WizardStep: Int, CaseIterable {
    case source
    case destination
    case plan
    case run
    case verify

    var title: String {
        switch self {
        case .source: return "1. Source"
        case .destination: return "2. Destination"
        case .plan: return "3. Plan"
        case .run: return "4. Run"
        case .verify: return "5. Verify & Decide"
        }
    }
}

@MainActor
final class CloneWizardViewModel: ObservableObject {
    @Published var step: WizardStep = .source
    @Published var sourcePath: String = "/Volumes/1D3"
    @Published var destinationPath: String = "/Users/Shared/1D3-clone"
    @Published var sourceKind: EndpointKind = .volume
    @Published var destinationKind: EndpointKind = .folder
    @Published var intent: JobIntent = .initialClone
    @Published var copyMode: CopyMode = .clone
    @Published var verificationMode: VerificationMode = .metadata
    @Published var postActionPolicy: PostActionPolicy = .manualDecision
    @Published var inventoryDepth: InventoryDepth = .explorable
    @Published var statusMessage: String = "CloneWatch teaches as it works. First choose where the data lives."
    @Published var lastResult: CloneRunResult?
    @Published var lastError: String?
    @Published var isRunning = false
    @Published var detectedPreflight: PreflightResult?

    func next() {
        if let next = WizardStep(rawValue: min(step.rawValue + 1, WizardStep.allCases.count - 1)) {
            step = next
        }
    }

    func back() {
        if let previous = WizardStep(rawValue: max(step.rawValue - 1, 0)) {
            step = previous
        }
    }

    var job: CloneJob {
        CloneJob(
            source: Endpoint(kind: sourceKind, path: sourcePath),
            destination: Endpoint(kind: destinationKind, path: destinationPath),
            intent: intent,
            copyMode: copyMode,
            verificationMode: verificationMode,
            postActionPolicy: postActionPolicy,
            recordPlacements: [.source, .destination, .central],
            inventoryDepth: inventoryDepth
        )
    }

    func runJob() {
        isRunning = true
        lastError = nil
        statusMessage = "Running preflight, copy, inventory, verification, and ledger generation."

        let runtime = CloneWatchRuntime()
        let currentJob = job
        Task {
            do {
                let result = try runtime.execute(job: currentJob)
                await MainActor.run {
                    self.lastResult = result
                    self.statusMessage = "Job finished. A durable audit bundle was written to the central CloneWatch records folder and mirrored into source/destination."
                    self.step = .verify
                    self.isRunning = false
                }
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                    self.statusMessage = "The job stopped before completion."
                    self.isRunning = false
                }
            }
        }
    }

    func refreshPreflight() {
        detectedPreflight = PreflightChecker().run(job: job)
    }

    func choosePath(forSource: Bool) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = forSource ? "Pick the source folder or mounted volume root." : "Pick the destination folder or mounted volume root."
        if panel.runModal() == .OK, let url = panel.url {
            if forSource {
                sourcePath = url.path
            } else {
                destinationPath = url.path
            }
            refreshPreflight()
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: CloneWizardViewModel

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            mainPanel
        }
        .background(
            LinearGradient(colors: [Color(red: 0.97, green: 0.93, blue: 0.88), Color(red: 0.91, green: 0.95, blue: 0.92)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("CloneWatch")
                .font(.system(size: 34, weight: .bold, design: .serif))
            Text("A Mac-first clone, verification, and evidence platform. The app explains what is happening so you can make safe decisions later.")
                .foregroundStyle(.secondary)

            ForEach(WizardStep.allCases, id: \.rawValue) { step in
                HStack {
                    Circle()
                        .fill(step.rawValue <= viewModel.step.rawValue ? Color.green : Color.gray.opacity(0.25))
                        .frame(width: 12, height: 12)
                    Text(step.title)
                        .fontWeight(step == viewModel.step ? .semibold : .regular)
                }
            }

            Spacer()

            Text("What happens here")
                .font(.headline)
            Text(viewModel.statusMessage)
                .font(.callout)
                .foregroundStyle(.secondary)

            if let error = viewModel.lastError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
            }
        }
        .padding(28)
        .frame(width: 280, alignment: .topLeading)
        .background(Color.white.opacity(0.45))
    }

    private var mainPanel: some View {
        VStack(alignment: .leading, spacing: 22) {
            switch viewModel.step {
            case .source:
                SourceDestinationStepView(
                    title: "Choose the source",
                    explanation: "The source is the place that currently contains the data you care about. This can be a mounted volume or a folder.",
                    kind: $viewModel.sourceKind,
                    path: $viewModel.sourcePath,
                    onChoose: { viewModel.choosePath(forSource: true) }
                )
            case .destination:
                SourceDestinationStepView(
                    title: "Choose the destination",
                    explanation: "The destination is where the clone will be built. CloneWatch will create its evidence ledger there too.",
                    kind: $viewModel.destinationKind,
                    path: $viewModel.destinationPath,
                    onChoose: { viewModel.choosePath(forSource: false) }
                )
            case .plan:
                PlanStepView(viewModel: viewModel)
            case .run:
                RunStepView(viewModel: viewModel)
            case .verify:
                VerifyStepView(viewModel: viewModel)
            }

            Spacer()

            HStack {
                Button("Back") { viewModel.back() }
                    .disabled(viewModel.step == .source || viewModel.isRunning)
                Spacer()
                if viewModel.step != .verify {
                    Button(viewModel.step == .run ? "Run CloneWatch" : "Next") {
                        if viewModel.step == .run {
                            viewModel.runJob()
                        } else {
                            viewModel.next()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isRunning)
                }
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { viewModel.refreshPreflight() }
        .onChange(of: viewModel.sourcePath) { _, _ in viewModel.refreshPreflight() }
        .onChange(of: viewModel.destinationPath) { _, _ in viewModel.refreshPreflight() }
        .onChange(of: viewModel.sourceKind) { _, _ in viewModel.refreshPreflight() }
        .onChange(of: viewModel.destinationKind) { _, _ in viewModel.refreshPreflight() }
        .onChange(of: viewModel.intent) { _, _ in viewModel.refreshPreflight() }
    }
}

struct SourceDestinationStepView: View {
    let title: String
    let explanation: String
    @Binding var kind: EndpointKind
    @Binding var path: String
    let onChoose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .serif))
            Text(explanation)
                .foregroundStyle(.secondary)
            Picker("Type", selection: $kind) {
                ForEach(EndpointKind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            TextField("/path/to/location", text: $path)
                .textFieldStyle(.roundedBorder)
            Button("Choose with macOS picker") {
                onChoose()
            }
            CalloutCard(
                title: "Why this matters",
                message: "CloneWatch treats both folders and mounted volumes as file trees. The important thing is choosing the correct root path."
            )
        }
    }
}

struct PlanStepView: View {
    @ObservedObject var viewModel: CloneWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Review the plan")
                .font(.system(size: 28, weight: .bold, design: .serif))
            Text("This is the moment to sanity-check what CloneWatch will do before anything gets copied.")
                .foregroundStyle(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                GridRow { Text("Source").bold(); Text(viewModel.sourcePath) }
                GridRow { Text("Destination").bold(); Text(viewModel.destinationPath) }
                GridRow { Text("Intent").bold(); Text(viewModel.intent.displayName) }
                GridRow { Text("Copy mode").bold(); Text(viewModel.copyMode.displayName) }
                GridRow { Text("Verification").bold(); Text(viewModel.verificationMode.displayName) }
                GridRow { Text("Post-action").bold(); Text(viewModel.postActionPolicy.rawValue) }
                GridRow { Text("Inventory depth").bold(); Text(viewModel.inventoryDepth.rawValue) }
            }

            Picker("Job intent", selection: $viewModel.intent) {
                ForEach(JobIntent.allCases) { intent in
                    Text(intent.displayName).tag(intent)
                }
            }
            Picker("Copy mode", selection: $viewModel.copyMode) {
                ForEach(CopyMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            Picker("Verification mode", selection: $viewModel.verificationMode) {
                ForEach(VerificationMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            Picker("Inventory depth", selection: $viewModel.inventoryDepth) {
                ForEach(InventoryDepth.allCases) { depth in
                    Text(depth.rawValue.capitalized).tag(depth)
                }
            }
            CalloutCard(
                title: "Default safety rule",
                message: "CloneWatch never auto-deletes the source. It documents what happened so a human can decide later."
            )
            CalloutCard(
                title: "Efficient reinforcement",
                message: "If you already cloned once and now just want to refresh the clone, choose 'Reinforce Existing Clone'. CloneWatch will use rsync to send only the differences instead of recopying everything."
            )
            PermissionAndRiskView(viewModel: viewModel)
        }
        .onAppear { viewModel.refreshPreflight() }
    }
}

struct RunStepView: View {
    @ObservedObject var viewModel: CloneWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Run the job")
                .font(.system(size: 28, weight: .bold, design: .serif))
            Text("When you start, CloneWatch will run preflight checks, copy the data, scan both trees, compare them, and write an audit bundle in three places.")
                .foregroundStyle(.secondary)
            CalloutCard(
                title: "Evidence bundle",
                message: "The bundle includes JSON, Markdown, HTML, and SQLite files so you can inspect the result from the app, Terminal, or another device."
            )
            if viewModel.isRunning {
                ProgressView("CloneWatch is working...")
                    .progressViewStyle(.linear)
            }
        }
    }
}

struct VerifyStepView: View {
    @ObservedObject var viewModel: CloneWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Verify and decide")
                .font(.system(size: 28, weight: .bold, design: .serif))
            if let result = viewModel.lastResult {
                Text("CloneWatch finished the copy and wrote the ledger. Here is the quick read so you can decide what to do next.")
                    .foregroundStyle(.secondary)
                HStack {
                    SummaryPill(label: "Confidence", value: result.verification.summary.confidence)
                    SummaryPill(label: "Missing", value: "\(result.verification.summary.missingCount)")
                    SummaryPill(label: "Extra", value: "\(result.verification.summary.extraCount)")
                    SummaryPill(label: "Different", value: "\(result.verification.summary.differentCount)")
                }
                Text("Central ledger:")
                    .font(.headline)
                Text(result.ledger.centralBundleURL.path)
                    .textSelection(.enabled)
                if !result.ledger.placementURLs.isEmpty {
                    Text("Mirrored records:")
                        .font(.headline)
                    ForEach(result.ledger.placementURLs, id: \.path) { url in
                        Text(url.path)
                            .textSelection(.enabled)
                    }
                }
                if let firstDiff = result.verification.differences.first {
                    CalloutCard(
                        title: "First flagged difference",
                        message: "\(firstDiff.relativePath): \(firstDiff.detail)"
                    )
                }
            } else {
                Text("Run a job first. This screen becomes your final review checkpoint.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PermissionAndRiskView: View {
    @ObservedObject var viewModel: CloneWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Permissions and platform realities")
                .font(.headline)
            if let preflight = viewModel.detectedPreflight {
                ForEach(preflight.permissions, id: \.requirement) { item in
                    Text("• \(item.requirement.displayName): \(item.detail)")
                        .foregroundStyle(.secondary)
                }
                if let source = preflight.sourceEnvironment, !source.notes.isEmpty {
                    Text("Source notes")
                        .font(.subheadline.bold())
                    ForEach(source.notes, id: \.self) { note in
                        Text("• \(note)")
                            .foregroundStyle(.secondary)
                    }
                }
                if let destination = preflight.destinationEnvironment, !destination.notes.isEmpty {
                    Text("Destination notes")
                        .font(.subheadline.bold())
                    ForEach(destination.notes, id: \.self) { note in
                        Text("• \(note)")
                            .foregroundStyle(.secondary)
                    }
                }
                if !preflight.risks.isEmpty {
                    Text("Detected risks")
                        .font(.subheadline.bold())
                    ForEach(Array(preflight.risks.enumerated()), id: \.offset) { _, risk in
                        Text("• [\(risk.level.rawValue.uppercased())] \(risk.title): \(risk.detail)")
                            .foregroundStyle(risk.level == .critical ? .red : .secondary)
                    }
                }
            } else {
                Text("CloneWatch will inspect permissions and path risks here before the run starts.")
                    .foregroundStyle(.secondary)
            }
            CalloutCard(
                title: "Important macOS rule",
                message: "CloneWatch can ask you to choose files and can prompt for admin work through a helper later, but Full Disk Access cannot be silently granted by the app itself. The app must detect that need and guide you."
            )
        }
    }
}

struct CalloutCard: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(message)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct SummaryPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .padding(12)
        .background(Color.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
