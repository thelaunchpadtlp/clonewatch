import Foundation
import CloneWatchCore

@main
struct CloneWatchDocsTool {
    static func main() throws {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let docsRoot = cwd.appendingPathComponent("docs/chat-history", isDirectory: true)
        let engine = TranscriptReconstructionEngine()
        try engine.processChatHistory(at: docsRoot)
        print("Processed chat history into \(docsRoot.path)")
    }
}
