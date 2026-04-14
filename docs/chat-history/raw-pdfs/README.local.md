# Raw PDF Archive (Local)

This folder is intentionally treated as a **local archive**.

- Keep the original chat export PDFs here on your Mac.
- They remain part of the project workspace.
- They are ignored by Git to avoid push failures and unstable sync caused by very large binary files.

Why:

- GitHub blocks very large files in normal Git history.
- Large binary pushes are more likely to fail on weaker or unstable connections.

Recommended sharing strategy:

1. Keep canonical extracted Markdown in Git (`docs/chat-history/extracted` and `canonical-transcript.md`).
2. Keep raw PDFs locally in this folder.
3. If needed, publish raw PDFs separately (for example as Release assets or cloud storage links) and reference them from docs.
