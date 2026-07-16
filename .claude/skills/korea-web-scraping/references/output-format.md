# Structured research deliverable format

When a task asks for OSINT/business-intelligence output on Korean companies or people (e.g. "find the leadership/contact info for these companies"), deliver it as three files, not a single blob — this is the format that held up well in practice and is worth reusing rather than inventing a new shape each time.

```
<topic>.csv          # flat, spreadsheet-friendly
<topic>.json          # same data, structured/nested, grouped by entity
research_log.csv      # what was queried/fetched, when, and what was declined
```

## `<topic>.csv`

One row per person (not per company) so a company with multiple named personnel gets multiple rows sharing the same company columns. Columns:

```
company, platform, full_name, designation, contact_email, contact_phone,
hq_address, business_reg_no, source_url, confidence, notes
```

- `contact_email` / `contact_phone`: only what's actually published (usually a general office/support address, not a personal one) — put `not published on site` rather than leaving it blank or guessing.
- `confidence`: `high` (primary source — the entity's own official site or a government/business registry) / `medium` (secondary source — press profile, recruiting-site listing, LinkedIn snippet surfaced via public search indexing) / `low` (plausible but unverified — flag it, don't silently include it as fact).
- `notes`: cross-references, caveats, why confidence is what it is.

## `<topic>.json`

Same data, grouped by company so the org structure is legible without re-joining rows:

```json
{
  "research_objective": "...",
  "date_compiled": "YYYY-MM-DD",
  "method_note": "...",
  "companies": [
    {
      "company_name_en": "...", "company_name_kr": "...",
      "platform": "...", "official_site": "...",
      "business_registration_no": "...", "hq_address": "...",
      "personnel": [
        { "full_name": "...", "designation": "...", "contact_email": null,
          "contact_phone": null, "source_url": "...", "confidence": "high",
          "notes": "..." }
      ]
    }
  ]
}
```

`method_note` at the top level is where you state what data-collection approach was used and, as importantly, what wasn't — see below.

## `research_log.csv`

Every fetch/search that shaped the output, in order:

```
seq, session_date, action, tool, target_url_or_query, result, notes
```

`action` is `fetch` or `search`; `result` records the outcome plainly, including failures (`403 Forbidden`, `no direct match`, `ambiguous — ...`). Don't omit the failed attempts — a log that only shows successes isn't an audit trail.

End the log with a `deliberately_not_done` block — the same shape, `action: declined` — documenting anything the brief asked for that wasn't done and why:

```
-, <date>, declined, n/a, "<what was asked for>", n/a, "<why — be specific>"
```

This matters more than it looks: a research brief will sometimes ask for something that sounds like routine data collection but is actually a request to defeat a platform's anti-automation controls (see below). Recording the declined item and the reason is what makes the deliverable trustworthy rather than silently incomplete.

## The line this format exists to make visible

"Publicly available" and "safe to scrape programmatically" are not the same thing. Two patterns that come up often in requests like this:

- **LinkedIn (and similarly defended platforms).** A brief that asks for "adaptive, human-like pacing... to avoid triggers that lead to IP/account blocks" is asking for anti-bot-detection evasion, not just data collection — regardless of how public or professional the target data is. Decline the automated-crawl part specifically; LinkedIn data that surfaces through a third-party search engine's public indexing (a `site:linkedin.com ...` search) is a different, non-evasive path to the same cross-reference and is fine to use.
- **Login-walled content on any site**, including the target company's own site if it happens to gate the page you need.

When you hit one of these, don't just skip it silently — say what you're not doing and why (in the response and in the `deliberately_not_done` log block), then deliver everything that's reachable through legitimate channels: the entity's own official site, government/business-registry lookups, and public search-engine results. That's usually most of what was actually needed.
