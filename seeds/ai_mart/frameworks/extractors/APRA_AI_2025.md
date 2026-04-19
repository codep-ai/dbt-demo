# TinyFish Extraction Prompt — APRA_AI_2025

> **Framework:** APRA AI Regulatory Expectations (CPS 230 + supervisory engagements + Transparency Statement)
> **Publisher:** Australian Prudential Regulation Authority
> **Jurisdiction:** AU-FIN (Australian financial services — banks, insurers, superannuation funds)
> **Effective:** CPS 230 from 1 July 2025; ongoing supervisory engagements 2025-26
> **Stage:** Stub — TinyFish refreshes verify + expand from canonical sources
> **Canonical location after Phase 2.2:** `datapai-platform-be/governance/framework_extractors/prompts/APRA_AI_2025.md`

---

## 1. Framework metadata (constants — pre-populate on every extracted row)

| Column | Value |
|---|---|
| `framework_code` | `APRA_AI_2025` |
| `framework_name` | `APRA AI Regulatory Expectations (CPS 230 + supervisory)` |
| `framework_publisher` | `Australian Prudential Regulation Authority` |
| `jurisdiction_code` | `AU-FIN` |
| `country_code` | `AU` |
| `effective_from` | `2025-07-01` |
| `is_mandatory` | `true` |
| `source_url` | `https://www.apra.gov.au/operational-risk-management` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://www.apra.gov.au/operational-risk-management
  supplementary_urls:
    - https://www.apra.gov.au/sites/default/files/2023-07/Prudential%20Standard%20CPS%20230%20Operational%20Risk%20Management.pdf
    - https://www.apra.gov.au/news-and-publications/apras-priorities-2025-26
    - https://www.apra.gov.au/news-and-publications/apra-transparency-statement-artificial-intelligence
  content_type: auto
  javascript: enabled
  timeout_seconds: 90
  retry_on_failure: 2
  capture:
    - full_page_text
    - content_sha256
    - retrieved_at_utc
```

Abort if primary + all supplementary return <5KB or HTTP 4xx/5xx.

## 3. AI extraction prompt (core instructions to the extractor AI)

```
You are extracting AI-governance control rows for the APRA_AI_2025
framework bundle. Sources include CPS 230 itself plus APRA publications
about AI supervision and APRA's own AI Transparency Statement.

Emit controls that directly affect AFSL holders and APRA-regulated
entities when they deploy or rely on AI. Do NOT emit general operational
risk controls that are unrelated to AI — keep the catalog AI-specific.

=== OUTPUT SCHEMA (CSV, 18 columns) ===
framework_code,framework_name,framework_publisher,jurisdiction_code,country_code,effective_from,is_mandatory,source_url,control_id,control_name,control_description,control_category,obligation_family,mandatory_records,source_section,retrieved_date,status,notes

=== CONSTANTS (pre-populate every row) ===
framework_code: APRA_AI_2025
framework_name: APRA AI Regulatory Expectations (CPS 230 + supervisory)
framework_publisher: Australian Prudential Regulation Authority
jurisdiction_code: AU-FIN
country_code: AU
effective_from: 2025-07-01
is_mandatory: true
retrieved_date: <today ISO 8601>
status: complete (unless ambiguity → top_level_only or stub)

=== STABLE CONTROL IDS (map semantically — these are our internal IDs) ===
CPS230.AI_OP_RISK         — AI as operational risk
CPS230.THIRD_PARTY_AI     — Third-party AI provider risk
CPS230.CRITICAL_OPS       — Critical operations continuity
CPS230.ACCOUNTABLE_PERSON — Named accountable person (FAR-aligned)
CPS230.INCIDENT_REPORT    — Operational incident reporting to APRA
CPS230.TEST_MONITOR       — Testing and monitoring

Additional controls may be emitted with new IDs prefixed CPS230.* or
SUPERVISORY.* if APRA publishes new requirements. Flag any new ID in
the structural_flags diff output.

=== OBLIGATION FAMILY MAPPING (fixed) ===
CPS230.AI_OP_RISK         → risk_management
CPS230.THIRD_PARTY_AI     → third_party_supply_chain
CPS230.CRITICAL_OPS       → risk_management
CPS230.ACCOUNTABLE_PERSON → accountability
CPS230.INCIDENT_REPORT    → recordkeeping
CPS230.TEST_MONITOR       → testing_monitoring

=== EXTRACTION RULES ===
1. control_description: one sentence, source-cited, AFSL/APRA-regulated
   entity perspective — "Entities must…", "APRA-regulated firms must…"
2. source_section: the exact CPS 230 paragraph or APRA publication
   heading (e.g. "CPS 230 §Service provider management").
3. mandatory_records: pipe-separated list reflecting APRA's supervisory
   evidence expectations — e.g.
     "operational risk profile|AI inventory|risk heat map"
4. If text indicates FAR (Financial Accountability Regime) overlap
   (bank/insurer senior executives), note in the control_description.

=== INVARIANTS ===
- Never auto-merge. PR requires compliance-team review.
- Never mutate published rows if APRA releases a new CPS version —
  create APRA_AI_2027 or similar and leave 2025 rows intact.
- Abort + structural_flag if CPS 230 is superseded or withdrawn.
```

## 4. Diff output schema

```json
{
  "framework_code": "APRA_AI_2025",
  "retrieved_date": "<today>",
  "rows_extracted": <int>,
  "rows_matching_seed": <int>,
  "rows_with_changes": <int>,
  "changes": [...],
  "structural_flags": []
}
```

## 5. Known edge cases

1. CPS 230 is NOT primarily an AI standard — it's operational risk. Extract only AI-relevant sections (service-provider management, critical ops, testing, incident notification where AI applies). Do NOT populate the catalog with generic operational-risk controls.
2. APRA's "supervisory engagements" 2025-26 are closed-door (not fully public). Use published summaries + speeches only.
3. FAR (Financial Accountability Regime) replaced BEAR in 2024-03. Control `CPS230.ACCOUNTABLE_PERSON` must reference FAR, not BEAR.
