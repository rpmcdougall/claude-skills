---
name: v17-rule
description: Use when the user asks "what does v17 say about X", "look up the <mechanic> rule", "find the rules text for X", or needs a verbatim rules citation for code review. Searches rules_export/ (v17 core PDF + v18 playtest PDF + plain-text changelists) and returns quoted rules text with page numbers, flagging v17/v18 divergence.
---

# v17-rule skill

Look up an exact rule from the Turnip28 rules PDFs in `rules_export/`.

## Files
- `rules_export/Turnip28 V17 Core Rules For Print-2.pdf` — v17 (authoritative).
- `rules_export/Turnip28_V18_Core Rules_PLAYTEST.pdf` — v18 playtest.
- `rules_export/Change list v17.txt` — v17 changelog (fast to grep).
- `rules_export/TURNIP CORE RULES v18 CHANGELIST.txt` — v18 changelog.

## Steps

1. Grep the two changelist `.txt` files first for the user's keywords. These are plain text and much faster than PDF scans — they often point to the right page or section.
2. If the changelists don't locate it, scan the v17 PDF. **PDFs >10 pages require `pages:` on the Read tool** — never read the whole PDF at once. Strategy:
   - Ask the user for a page hint if one is likely known.
   - Otherwise read the table of contents page first (usually early), then jump to the target pages.
3. Return:
   - Verbatim quoted rules text (keep original wording — this is a citation, not a paraphrase).
   - Page number(s) in v17.
   - **Divergence flag**: if the v18 changelist mentions this rule, note "v18 changes this — see page N of playtest PDF" and quote both versions.
4. If the rule is not found, say so explicitly — do not fabricate.

## Output shape

```
**v17 (page N):**
> <verbatim quote>

**v18 playtest (page M):** <divergence note, or "unchanged">
> <verbatim quote if changed>
```

## Rules
- Never paraphrase when the user wants a citation.
- Never guess page numbers — if uncertain, say "approx. page N" and verify.
- Don't open PDFs larger than 10 pages without `pages:`; that read will fail.
