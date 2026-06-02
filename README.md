# Domus

A household management system.

## Overview

Domus is where I keep household records. Today that's an inventory of the stuff we own and a filing cabinet for family documents. More may come; the name is broader than the current scope on purpose.

Inventory replaces [homebox](https://homebox.software/). Documents replace [paperless-ngx](https://docs.paperless-ngx.com/). Both do more than I need, and I want to keep only the parts I'll actually use.

Scope is one household. No multi-tenancy, no public sharing, no login screen — authentication happens at the network layer via a reverse proxy header, same pattern as [ketchup](https://github.com/kejadlen/ketchup).

## Domain model

### Tags

Any entity in the system can have tags. A tag is a short label — "garage," "kitchen," "pending." Tags also support a `key:value` form — "location:garage," "status:sold," "year:2023" — where the key names a dimension and the value qualifies it. Plain and key-value tags coexist freely on the same entity.

Key-value tags make it possible to group and filter by structured dimensions without dedicated schema fields. "location:garage" is both the label "garage" and a statement that the relevant dimension is "location."

### Assets

An **asset** is something I own worth tracking. Each asset has:

- a markdown description, with the first line as the display name
- tags, primarily for location
- purchase information: where I bought it, when, how much, optional receipt
- a maintenance log for things that need periodic attention

Purchase dates are fuzzy. Some receipts are decades old, and forcing an exact day when I only remember the year is friction I don't want. A purchase date can be a year, a year and month, or a full date.

### Documents

A **document** is any file the household wants to keep findable — tax returns, school records, contracts, warranties, manuals, medical paperwork. Supported file types include PDFs, images, and emails. Documents don't have to relate to the home itself; the inventory is one source of documents, not the only one. Documents have tags. OCR comes later.

Where a document does relate to an asset (a receipt, a manual), the two cross-reference each other.

## Stack

Same shape as [ketchup](https://github.com/kejadlen/ketchup): Roda for routing, Sequel and SQLite for persistence, Phlex for views, Alpine.js on the client, Puma serving it.

## Status

Early. No code yet — this README is the design sketch.
