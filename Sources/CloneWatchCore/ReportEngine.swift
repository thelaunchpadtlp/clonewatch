import Foundation

public struct ReportEngine {
    public init() {}

    public func makeSummaryMarkdown(job: CloneJob, preflight: PreflightResult, verification: VerificationResult) -> String {
        """
        # CloneWatch Audit Summary

        ## What happened

        - Job ID: `\(job.id.uuidString)`
        - Source: `\(job.source.path)`
        - Destination: `\(job.destination.path)`
        - Intent: `\(job.intent.rawValue)`
        - Copy mode: `\(job.copyMode.rawValue)`
        - Verification mode: `\(job.verificationMode.rawValue)`
        - Post action policy: `\(job.postActionPolicy.rawValue)`

        ## Preflight

        \(preflight.checks.map { "- \($0.passed ? "PASS" : "FAIL"): \($0.label) — \($0.detail)" }.joined(separator: "\n"))

        ## Permissions

        \(preflight.permissions.map { "- \($0.requirement.displayName): \($0.status) — \($0.detail)" }.joined(separator: "\n"))

        ## Environment Notes

        \(preflight.sourceEnvironment?.notes.map { "- Source: \($0)" }.joined(separator: "\n") ?? "- Source: no special notes")
        \(preflight.destinationEnvironment?.notes.map { "- Destination: \($0)" }.joined(separator: "\n") ?? "- Destination: no special notes")

        ## Storage Risks

        \(preflight.risks.isEmpty ? "- No major storage risks were detected during preflight." : preflight.risks.map { "- [\($0.level.rawValue.uppercased())] \($0.title): \($0.detail)" }.joined(separator: "\n"))

        ## Verification Summary

        - Identical entries: \(verification.summary.identicalCount)
        - Missing in destination: \(verification.summary.missingCount)
        - Extra in destination: \(verification.summary.extraCount)
        - Different entries: \(verification.summary.differentCount)
        - Warnings: \(verification.summary.warningCount)
        - Confidence: `\(verification.summary.confidence)`
        - Safe to delete source: `\(verification.summary.safeToDeleteSource ? "yes" : "no")`

        ## Why this bundle matters

        This bundle works as a durable operation record. It helps prove what was cloned, review differences, decide what to do with the original, and inspect the source/destination contents later without rerunning the job.

        CloneWatch can also reinforce an existing clone efficiently. In that mode it uses `rsync` to transfer only changes, instead of blindly copying every file again.
        """
    }

    public func makeDecisionMarkdown(verification: VerificationResult) -> String {
        let recommendation: String
        if verification.summary.safeToDeleteSource {
            recommendation = "The clone appears complete enough to consider deleting or archiving the source, but CloneWatch still recommends a final manual review before destructive actions."
        } else {
            recommendation = "Do not delete the source yet. Resolve or understand the remaining differences first."
        }

        return """
        # CloneWatch Decision Report

        ## Recommendation

        \(recommendation)

        ## Highlights

        - Confidence: `\(verification.summary.confidence)`
        - Missing entries: \(verification.summary.missingCount)
        - Extra entries: \(verification.summary.extraCount)
        - Different entries: \(verification.summary.differentCount)
        - Warnings: \(verification.summary.warningCount)
        """
    }

    public func makeHTMLReport(job: CloneJob, verification: VerificationResult) -> String {
        let topRows = verification.differences.prefix(250).map { diff in
            "<tr><td><code>\(escapeHTML(diff.relativePath))</code></td><td>\(escapeHTML(diff.status.rawValue))</td><td>\(diff.sourceSize.map(String.init) ?? "—")</td><td>\(diff.destinationSize.map(String.init) ?? "—")</td><td>\(escapeHTML(diff.detail))</td></tr>"
        }.joined(separator: "\n")

        return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>CloneWatch Report</title>
          <style>
            :root { --bg:#f5f1e8; --ink:#1d1d1f; --panel:#fffdf8; --line:#d8ccb6; --accent:#215f52; --warn:#8f5a00; --danger:#962d3e; }
            body { margin:0; background:radial-gradient(circle at top, #fffaf0, var(--bg)); color:var(--ink); font-family: "Iowan Old Style", "Palatino Linotype", serif; }
            main { max-width: 1100px; margin: 0 auto; padding: 32px 20px 60px; }
            .hero, section { background:rgba(255,253,248,0.92); border:1px solid var(--line); border-radius:20px; padding:20px; box-shadow:0 12px 30px rgba(71,56,32,0.08); margin-bottom:20px; }
            .cards { display:grid; grid-template-columns:repeat(auto-fit, minmax(180px, 1fr)); gap:12px; }
            .card { padding:14px; border-radius:16px; background:#fff; border:1px solid var(--line); }
            table { width:100%; border-collapse:collapse; font-size:14px; }
            th, td { text-align:left; padding:8px 10px; border-bottom:1px solid var(--line); vertical-align:top; }
            code { word-break:break-word; }
          </style>
        </head>
        <body>
          <main>
            <section class="hero">
              <h1>CloneWatch</h1>
              <p>Pedagogical clone report for <code>\(escapeHTML(job.source.path))</code> to <code>\(escapeHTML(job.destination.path))</code>.</p>
            </section>
            <section>
              <div class="cards">
                <div class="card"><strong>Confidence</strong><br>\(escapeHTML(verification.summary.confidence))</div>
                <div class="card"><strong>Identical</strong><br>\(verification.summary.identicalCount)</div>
                <div class="card"><strong>Missing</strong><br>\(verification.summary.missingCount)</div>
                <div class="card"><strong>Extra</strong><br>\(verification.summary.extraCount)</div>
                <div class="card"><strong>Different</strong><br>\(verification.summary.differentCount)</div>
                <div class="card"><strong>Safe To Delete Source</strong><br>\(verification.summary.safeToDeleteSource ? "Not yet confirmed manually" : "No")</div>
              </div>
            </section>
            <section>
              <h2>First Differences</h2>
              <p>This HTML is meant to be easy to open from another Mac, iPhone, or local browser. The complete machine-readable record lives in the JSON and SQLite artifacts.</p>
              <table>
                <thead>
                  <tr><th>Relative Path</th><th>Status</th><th>Source Size</th><th>Destination Size</th><th>Detail</th></tr>
                </thead>
                <tbody>
                  \(topRows.isEmpty ? "<tr><td colspan=\"5\">No differences found.</td></tr>" : topRows)
                </tbody>
              </table>
            </section>
          </main>
        </body>
        </html>
        """
    }

    public func makeInventoryMarkdown(title: String, snapshot: InventorySnapshot, limit: Int = 300) -> String {
        let rows = snapshot.entries.prefix(limit).map { entry in
            "- `\(entry.relativePath)` | \(entry.itemType) | size: \(entry.size.map(String.init) ?? "—") | perms: \(entry.permissions ?? "—")"
        }.joined(separator: "\n")

        return """
        # \(title)

        - Root: `\(snapshot.rootPath)`
        - Captured: `\(FileSystemHelper.isoString(from: snapshot.createdAt))`
        - Entries: \(snapshot.entries.count)
        - Depth: `\(snapshot.depth.rawValue)`

        ## First \(min(limit, snapshot.entries.count)) entries

        \(rows)
        """
    }

    private func escapeHTML(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
