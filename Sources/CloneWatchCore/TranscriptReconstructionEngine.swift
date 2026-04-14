import Foundation

#if canImport(PDFKit)
import PDFKit
#endif

public struct ExtractedDocument: Sendable {
    public var pdfName: String
    public var pageCount: Int
    public var markdown: String
}

public struct TranscriptReconstructionEngine: Sendable {
    public init() {}

    public func processChatHistory(at docsRoot: URL) throws {
        let rawPDFs = docsRoot.appendingPathComponent("raw-pdfs", isDirectory: true)
        let extracted = docsRoot.appendingPathComponent("extracted", isDirectory: true)
        try FileSystemHelper.ensureDirectory(extracted)

        let pdfs = try FileManager.default.contentsOfDirectory(at: rawPDFs, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension.lowercased() == "pdf" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        let extractedDocs = try pdfs.map { try extractPDF($0) }
        for doc in extractedDocs {
            let outputURL = extracted.appendingPathComponent(doc.pdfName.replacingOccurrences(of: ".pdf", with: ".md"))
            try FileSystemHelper.writeText(doc.markdown, to: outputURL)
        }

        let canonical = try buildCanonicalTranscript(from: extractedDocs)
        try FileSystemHelper.writeText(canonical, to: docsRoot.appendingPathComponent("canonical-transcript.md"))
        try FileSystemHelper.writeText(reconstructionNotes(for: extractedDocs), to: docsRoot.appendingPathComponent("reconstruction-notes.md"))
    }

    private func extractPDF(_ url: URL) throws -> ExtractedDocument {
        #if canImport(PDFKit)
        guard let document = PDFDocument(url: url) else {
            throw CloneWatchError.processFailed("Unable to open \(url.lastPathComponent) with PDFKit.")
        }
        var body = "# \(url.lastPathComponent)\n\n"
        body += "- Extracted with PDFKit\n"
        body += "- Pages: \(document.pageCount)\n\n"
        for index in 0..<document.pageCount {
            let text = document.page(at: index)?.string ?? ""
            body += "## Page \(index + 1)\n\n"
            body += text.trimmingCharacters(in: .whitespacesAndNewlines)
            body += "\n\n"
        }
        return ExtractedDocument(pdfName: url.lastPathComponent, pageCount: document.pageCount, markdown: body)
        #else
        throw CloneWatchError.processFailed("PDFKit is not available on this platform.")
        #endif
    }

    private func buildCanonicalTranscript(from documents: [ExtractedDocument]) throws -> String {
        guard let latest = documents.max(by: { $0.pageCount < $1.pageCount }) else {
            return "# Canonical Transcript\n\nNo PDFs found."
        }
        var markdown = """
        # Canonical CloneWatch Transcript

        This transcript uses the richest PDF export currently available as the main narrative source, while preserving every raw PDF and every per-PDF extraction in the repository.

        - Canonical source chosen: `\(latest.pdfName)`
        - Page count: \(latest.pageCount)

        ---

        """
        markdown += latest.markdown
        return markdown
    }

    private func reconstructionNotes(for documents: [ExtractedDocument]) -> String {
        let ordered = documents.sorted { $0.pageCount < $1.pageCount }
        let bullets = ordered.map { "- `\($0.pdfName)`: \($0.pageCount) pages extracted." }.joined(separator: "\n")
        return """
        # Reconstruction Notes

        ## Method

        - Every raw PDF was copied into `docs/chat-history/raw-pdfs`.
        - Every PDF was extracted into a page-by-page Markdown file.
        - The canonical transcript currently uses the richest PDF by page count as the base narrative.
        - Older PDFs are still preserved because they capture intermediate export states.

        ## Inventory

        \(bullets)

        ## Remaining caveats

        - The PDFs contain overlapping exports of the same conversation.
        - The current canonical transcript favors completeness over aggressive deduplication.
        - Future iterations can segment user/assistant turns more precisely if needed.
        """
    }
}
