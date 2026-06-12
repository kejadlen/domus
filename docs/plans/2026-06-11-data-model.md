# Data model

This note records the intended shape of Domus storage as of the capture
flow landing. It supersedes the unified-`documents` thinking in
`2026-06-02-documents-schema.md`, which was written for the
since-removed email ingestion path.

## The layering

Storage is three layers, each building on the one below.

### Files

A file is one stored blob — the raw bytes plus enough metadata to find
them again. Every uploaded or ingested byte stream becomes exactly one
`files` row, regardless of what it represents.

| Column | Notes |
|--------|-------|
| `id` | primary key |
| `extension` | original file extension, e.g. `.png` (lowercased) |
| `created_at` | when the row was written |

The blob lives on disk at `storage_path/files/<id><extension>`; the path
is derived from the row rather than stored, so there is one source of
truth for where a file lives (`App#file_path`).

### Documents

A document is a logical document — today that means a PDF — that points
at a file. The document layer carries document-level meaning (title,
received date, classification) while delegating the bytes to a `files`
row. One file backs one document.

The current `documents` table predates this model: it still has the
`path`, `kind`, and `received_at` columns from the unified design and
does not yet reference `files`. Reshaping it to point at a file is
follow-up work, not part of the capture flow.

### Assets

An asset is a thing the user is tracking — a piece of equipment, a
property, an account — that has attachments. Each attachment can be any
file, so the asset-to-file relationship is many-to-many through a join,
with no constraint that attachments be PDFs or images.

Assets are not built yet; they are recorded here so the file and
document layers stay general enough to support them.

## Why layer it this way

Keeping `files` as a thin, universal base means every higher concept
reuses one storage and addressing scheme. Documents and assets differ in
what they *mean* and how they relate to other records, not in how their
bytes are stored. That separation lets the capture flow ship against
`files` alone while documents and assets are designed independently.
