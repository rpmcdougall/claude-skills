---
name: sql-explainer
description: Explain SQL queries as a layered learning tool, optimized for Snowflake / Oracle / Databricks. Use this skill whenever the user pastes a SQL query and asks what it does, how it works, why it was written that way, or to walk through / break down / analyze / demystify it — even if they don't explicitly say "explain." Also use when the user wants a query cataloged for later reference, or asks about a specific clause, window function, CTE, join pattern, or performance characteristic inside a query they've shared. Produces a four-layer explanation (TL;DR → logical execution order → line-by-line → patterns/techniques) plus a row trace, performance notes, and pitfalls, and can save the explanation to a user-specified local directory for cataloging.
---

# SQL Explainer

A learning-oriented SQL query explainer. The goal is not just to answer "what does this query do" — it's to make the *way* SQL works stick, so the user internalizes patterns rather than re-looking them up. The user is a working data engineer (Snowflake, Oracle, Databricks) who wants to learn SQL deeply without carving out extra study time — explanations happen in the flow of their real work.

## When to use this skill

Trigger when the user:
- Pastes a SQL query and asks to explain / break down / walk through / demystify / analyze it
- Asks what a specific clause, window function, CTE, subquery, or join in a shared query is doing
- Asks why a query was written a particular way
- Wants a query cataloged to their local reference library

Don't trigger when:
- The user is asking a general SQL concept question with no specific query (e.g. "what's a window function?") — answer directly
- The user wants the query *written*, not explained — help them write it
- The user wants the query optimized or debugged as the primary goal — treat that as a different task, though this skill's performance and pitfalls sections are useful inputs

## Core output structure

ALWAYS produce the explanation in this exact order. Each section has a clear purpose and builds on the last — skipping ahead defeats the learning value.

```
### TL;DR
One sentence. Plain English. What the query returns / does, no jargon.

### Logical execution order
How the database actually processes the query, stage by stage, in the order
the engine evaluates them — NOT the order the clauses appear in the source.
For each stage, name the stage and say what it does to the data so far.

### Line-by-line walkthrough
Each clause / expression in written order, with enough depth that the user
learns *why* each piece is there — not just what it does syntactically.
Call out non-obvious semantics (NULL behavior, implicit casts, ordering
guarantees, etc.) inline.

### Patterns & techniques
Name the patterns the author used (anti-join, gaps-and-islands, running
total via window function, latest-row-per-group, pivot, etc.). For each,
explain the problem it solves and when to reach for it. This is the
highest-leverage section for retention — patterns transfer across queries.

### Sample row trace
Invent 2–4 representative input rows (tiny, realistic) and show how they
flow through each logical stage. Use a small table format. If the query
spans multiple tables, invent a few rows from each. Pick rows that
exercise the interesting behavior (e.g. NULLs, ties, boundary conditions).

### Performance notes
Call out things that matter at scale: pruning opportunities, join
strategy implications, data skew risks, clustering / partitioning
interactions, spill risk, redundant scans, anything the engine can or
can't optimize away. Be specific about which engine (Snowflake / Oracle
/ Databricks) the observation applies to when it differs.

### Pitfalls & silent bugs
Things that could be wrong and wouldn't throw an error:
- NULL handling (especially in NOT IN, aggregates, joins)
- Implicit casts and precision loss
- Duplicate rows from fan-out joins
- Ordering assumptions that aren't guaranteed
- Time zone / date boundary bugs
- SELECT DISTINCT masking a real join problem
- Aggregation missing a GROUP BY column
Only include this section if there's something real to say — don't
manufacture pitfalls where none exist.
```

If a section genuinely doesn't apply to a given query (e.g. a trivial `SELECT col FROM t` has no interesting patterns), say so in one line rather than padding. But prefer including all sections — even simple queries often have more teaching value than they appear to on the surface.

## Dialect handling

The user works in Snowflake, Oracle, and Databricks. Default the explanation to **Snowflake** semantics unless the query visibly uses Oracle (`DUAL`, `CONNECT BY`, `(+)` joins, `NVL`, `ROWNUM`, `MERGE` with Oracle quirks) or Databricks (`LATERAL VIEW`, Delta-specific syntax, `ZORDER`, `OPTIMIZE`) syntax, in which case default to that dialect.

Whenever a feature behaves differently across the three, call it out in a short inline note. Examples:
- `QUALIFY` — Snowflake & Databricks yes, Oracle no (use a subquery wrapping `ROW_NUMBER()`)
- `NULLS FIRST/LAST` — all three support it, but default ordering of NULLs differs
- `LISTAGG` — Snowflake & Oracle have it; Databricks uses `collect_list` + `concat_ws` or `array_join`
- `FLATTEN` / `LATERAL FLATTEN` — Snowflake; Databricks uses `LATERAL VIEW explode`; Oracle uses `XMLTABLE`/`JSON_TABLE` depending on type
- Data type differences (`VARCHAR2` in Oracle vs `VARCHAR` / `STRING`; `VARIANT` in Snowflake vs `STRUCT`/`MAP` in Databricks vs JSON columns in Oracle)

Don't derail the explanation with dialect tangents — keep the note tight (one line where possible) and only include it when the difference is actually relevant to the query being explained.

## Cataloging (file output)

The user wants each explanation saved to a local directory they choose, so their explanations accumulate into a personal reference library.

**First query of a session:** ask where to save the catalog. Phrase it as a single question, and offer a sensible default:

> Where should I save these explanations? (e.g., `~/sql-catalog/`, or paste any path — I'll create it if it doesn't exist.)

Once the user provides a path (or says "skip cataloging"), remember it for the rest of the session and don't ask again. If the user says to skip, don't save files but still provide the full explanation in chat.

**Subsequent queries in the same session:** save automatically to the same directory without re-asking.

**Filename convention:** `YYYY-MM-DD_<short-slug>.md`. The slug should be 3–6 words describing what the query does in kebab-case. Examples:
- `2026-04-22_top-customers-by-revenue.md`
- `2026-04-22_gaps-and-islands-login-streak.md`
- `2026-04-22_latest-order-per-customer.md`

If a file with that name already exists, append `-2`, `-3`, etc. rather than overwriting.

**File contents:** the full explanation (all sections above) plus a header block at the top:

```markdown
# <Human-readable title describing what the query does>

**Dialect:** Snowflake | Oracle | Databricks | (mixed/ANSI)
**Saved:** <ISO date>
**Tags:** <2–5 short tags — e.g. "window-functions, anti-join, gaps-and-islands">

## Original query

​```sql
<the exact query the user pasted, preserved verbatim>
​```

<then the four-layer explanation + row trace + performance + pitfalls>
```

The tags matter — they're how the user will later grep `~/sql-catalog/` to find all the window-function examples or all the gaps-and-islands patterns. Pick tags that name transferable *patterns* and *techniques*, not just surface features of this particular query.

**After saving:** tell the user the full path of the file you wrote, on its own line, so they can copy it. Don't bury it in prose.

## Writing style for the explanation

- Explain *why*, not just *what*. "GROUP BY customer_id" is a syntactic fact; "GROUP BY customer_id collapses each customer's rows into one, which is required because we're aggregating with SUM — every non-aggregated column in the SELECT must appear in the GROUP BY or the query will error" is a teaching explanation.
- Use the user's existing knowledge as scaffolding. They're a working data engineer, not a beginner — don't over-explain what `JOIN` is, but do unpack subtleties like the difference between `JOIN ON` and `JOIN USING`, or why `LEFT JOIN ... WHERE right_table.col IS NOT NULL` becomes effectively an INNER JOIN.
- Name things. When you describe a pattern, give it its proper name ("this is the gaps-and-islands pattern," "this is a semi-join expressed as EXISTS"). Names are what the user will remember and search for later.
- Keep jargon when it's the right word; translate it when it isn't. "Correlated subquery" is worth learning. "Predicate" is fine. "Cardinality" is fine in the performance section. But avoid performative academic phrasing.
- Prefer tables for the row trace and for any multi-value comparison (like dialect differences across three engines). Prose for the conceptual parts.
- Don't hedge. If the query has a bug, say so. If a pattern is bad practice, say so. The user has explicitly said they value honest evaluation over cushioning.

## Handling edge cases in input

- **Partial queries / fragments:** explain what you can and flag what's ambiguous. Don't refuse.
- **Queries with obvious bugs:** explain what the query *as written* does, then flag the bug in the Pitfalls section. Don't silently "fix" it in the explanation.
- **Massive queries (500+ lines, many CTEs):** structure the walkthrough CTE-by-CTE. For each CTE, give it a TL;DR and a line-by-line, then at the end show how they compose. The full sample row trace may be impractical — in that case, trace rows through 2–3 of the most interesting CTEs and say which you're tracing and why.
- **Generated/obfuscated SQL (e.g. from dbt, ORM output):** note the origin if obvious, explain the logical structure, and deprioritize line-by-line syntactic detail in favor of "what business question is this answering."
- **Dialect-ambiguous syntax:** if the query is valid in multiple dialects and the user didn't say which, ask once, then default to Snowflake if they don't specify.

## Quick reference: common patterns to name explicitly

When you spot any of these, name them in the Patterns & techniques section:

- **Latest-row-per-group** — `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ... DESC) = 1`, or `QUALIFY` in Snowflake/Databricks
- **Gaps and islands** — finding consecutive runs using `ROW_NUMBER` differences
- **Running total / moving average** — window with `ORDER BY` and optional frame
- **Anti-join** — `LEFT JOIN ... WHERE right IS NULL`, or `NOT EXISTS`, or `EXCEPT`
- **Semi-join** — `EXISTS` or `IN (SELECT ...)`
- **Fan-out and dedup** — when a join multiplies rows and `DISTINCT` / `GROUP BY` hides it
- **Pivot / unpivot** — explicit `PIVOT` clause or `CASE WHEN` aggregation
- **Bucketing / NTILE** — splitting rows into N equal groups
- **Self-join for hierarchies** — `CONNECT BY` in Oracle, recursive CTE elsewhere
- **Date spine / calendar join** — generating dates and left-joining facts onto them
- **Conditional aggregation** — `SUM(CASE WHEN ... THEN 1 ELSE 0 END)` for counting subsets
- **Deduplication via GROUP BY vs DISTINCT vs QUALIFY ROW_NUMBER** — and when each is right
- **Correlated subquery** — and when it's expensive vs when the optimizer rewrites it to a join

Naming these patterns is the single highest-leverage thing the skill does for retention. The user can forget the exact syntax of any one query, but once "gaps and islands" is a named concept in their head, they recognize it everywhere.
