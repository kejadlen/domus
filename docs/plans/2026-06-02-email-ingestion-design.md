# Email ingestion design

Domus receives emails at a fixed address and saves them as searchable
records. Each email becomes an `email` record; each attachment becomes
a linked `attachment` record. This document covers the ingestion
pipeline only — storage, parsing, and persistence. It does not cover
display, search, or tagging.

## Schema

Two new tables:

**`emails`**

| column | type | notes |
|---|---|---|
| `id` | integer PK | |
| `path` | text not null | path to `.eml` file, relative to `storage_path` |
| `subject` | text | |
| `from` | text | |
| `received_at` | datetime | |
| `created_at` | datetime | |

**`attachments`**

| column | type | notes |
|---|---|---|
| `id` | integer PK | |
| `email_id` | integer not null | FK → `emails.id` |
| `path` | text not null | path to attachment file, relative to `storage_path` |
| `filename` | text not null | original filename from the email |
| `content_type` | text | |
| `created_at` | datetime | |

## File storage

`Config` gains a `storage_path` field, defaulting to `"storage"` relative to
the app root. Files land under two subdirectories:

```
storage/
  emails/
    2026-06-02-<uuid>.eml
  attachments/
    2026-06-02-<uuid>-<original-filename>
```

The date prefix keeps files browsable on disk. The UUID prevents collisions.
The `path` columns store paths relative to `storage_path`, so moving the
storage root requires no database updates.

SendGrid Inbound Parse must be configured in **raw mode**, which delivers the
full RFC 822 message as a single field. The stored `.eml` file is then a
valid, openable email.

## Webhook endpoint

`POST /inbound/email` receives the SendGrid payload.

### IP allowlisting

A middleware checks `REMOTE_ADDR` against SendGrid's published Inbound Parse
IP ranges before the request reaches the route handler. Requests from
unlisted IPs receive a 403 response. The middleware accepts a config override
for local development and testing.

### Processing

When a request passes the IP check, the handler:

1. Parses the multipart form — raw email in the `email` field, attachments as
   `attachment1`, `attachment2`, etc.
2. Writes the `.eml` to `storage/emails/`
3. Inserts an `emails` row
4. For each attachment: writes the file to `storage/attachments/` and inserts
   an `attachments` row linked to the email
5. Returns 200

Steps 2–4 run in a single database transaction. If any step fails, no partial
records are written and no files are kept.
