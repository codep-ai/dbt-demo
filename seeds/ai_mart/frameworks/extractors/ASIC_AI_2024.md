# TinyFish Extraction Prompt — ASIC_AI_2024

> **Framework:** ASIC AI Regulatory Expectations (REP 798 + Corporations Act s912A + 2026 enforcement priorities)
> **Publisher:** Australian Securities and Investments Commission
> **Jurisdiction:** AU-FIN (Australian financial services — AFSL holders, market participants)
> **Effective:** REP 798 published 2024-10-29; Corporations Act s912A evergreen; enforcement priorities updated annually via ASIC Corporate Plan
> **Stage:** Stub — TinyFish refreshes verify + expand from canonical ASIC sources
> **Canonical location after Phase 2.2:** `datapai-platform-be/governance/framework_extractors/prompts/ASIC_AI_2024.md`

---

## 1. Framework metadata (constants — pre-populate on every extracted row)

| Column | Value |
|---|---|
| `framework_code` | `ASIC_AI_2024` |
| `framework_name` | `ASIC AI Regulatory Expectations (REP 798 + s912A + 2026 priorities)` |
| `framework_publisher` | `Australian Securities and Investments Commission` |
| `jurisdiction_code` | `AU-FIN` |
| `country_code` | `AU` |
| `effective_from` | `2024-10-29` |
| `is_mandatory` | `true` |
| `source_url` | `https://asic.gov.au/regulatory-resources/find-a-document/reports/rep-798-beware-the-gap-governance-arrangements-in-the-face-of-ai-innovation/` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://asic.gov.au/regulatory-resources/find-a-document/reports/rep-798-beware-the-gap-governance-arrangements-in-the-face-of-ai-innovation/
  supplementary_urls:
    - https://asic.gov.au/about-asic/corporate-publications/asic-corporate-plan/
    - https://asic.gov.au/regulatory-resources/markets/market-integrity-rules/
    - https://asic.gov.au/regulatory-resources/financial-services/financial-services-and-credit-panel/
    - https://asic.gov.au/about-asic/news-centre/speeches/
  search_filter: "artificial intelligence OR AI OR machine learning OR algorithmic OR agentic"
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
You are extracting AI-governance control rows for the ASIC_AI_2024
framework bundle. Sources: REP 798, Corporations Act s912A, annual
ASIC Corporate Plan enforcement priorities, relevant Chair speeches,
and market integrity rules where they touch AI-driven trading.

Focus on obligations that bind AFSL holders and market participants
when deploying AI in consumer-facing financial services or markets.

=== OUTPUT SCHEMA (CSV, 18 columns) ===
framework_code,framework_name,framework_publisher,jurisdiction_code,country_code,effective_from,is_mandatory,source_url,control_id,control_name,control_description,control_category,obligation_family,mandatory_records,source_section,retrieved_date,status,notes

=== CONSTANTS (pre-populate every row) ===
framework_code: ASIC_AI_2024
framework_name: ASIC AI Regulatory Expectations (REP 798 + s912A + 2026 priorities)
framework_publisher: Australian Securities and Investments Commission
jurisdiction_code: AU-FIN
country_code: AU
effective_from: 2024-10-29
is_mandatory: true
retrieved_date: <today ISO 8601>
status: complete (unless ambiguity)

=== STABLE CONTROL IDS (map semantically — these are our internal IDs) ===
ASIC.CORP_ACT_912A     — Corporations Act s912A efficient, honest, fairly duty
ASIC.GOV_PACE          — Governance framework must match AI adoption pace
ASIC.CONSUMER_HARM     — Preventing consumer harm from AI / automated decisions
ASIC.AGENTIC_AI        — Agentic AI risk (2026 enforcement priority)
ASIC.MARKET_INTEGRITY  — Market integrity obligations when AI used in trading/markets
ASIC.DISCLOSURE        — Disclosure obligations for AI use (DDO + RG 274)

New controls may be emitted as ASIC.* with new IDs if ASIC publishes new
guidance (e.g. fresh RG or Info Sheet on AI). Flag via structural_flags.

=== OBLIGATION FAMILY MAPPING (fixed) ===
ASIC.CORP_ACT_912A   → accountability
ASIC.GOV_PACE        → accountability
ASIC.CONSUMER_HARM   → impact_assessment
ASIC.AGENTIC_AI      → risk_management
ASIC.MARKET_INTEGRITY → transparency
ASIC.DISCLOSURE      → transparency

=== EXTRACTION RULES ===
1. control_description: one sentence, AFSL/AU-licensee perspective.
   Example: "AFSL holders must provide financial services efficiently
   honestly and fairly under s912A — AI-mediated actions remain bound
   by this duty."
2. source_section: the exact REP / Corporations Act / Corporate Plan
   reference (e.g. "REP 798 main thesis", "Corporations Act 2001 s912A",
   "ASIC 2025-26 Corporate Plan Enforcement Priority 3").
3. mandatory_records: ASIC's supervisory evidence expectations —
   pipe-separated, e.g.
     "AFSL compliance plan covering AI|breach reports under RG 78|
      conduct monitoring records"
4. Specially for ASIC.AGENTIC_AI: emphasize ASIC's 2026 priority
   specifically targets multi-step autonomous agents.
5. Specially for ASIC.GOV_PACE: cite REP 798's core finding that
   governance arrangements are lagging adoption.

=== INVARIANTS ===
- Never auto-merge.
- Never mutate rows if ASIC issues a new REP — create new framework_code
  e.g. ASIC_AI_2027 and leave 2024 rows intact.
- Abort + structural_flag if REP 798 is superseded or withdrawn.
- If ASIC issues a formal Regulatory Guide (RG) on AI, that becomes a
  new framework_code (e.g. ASIC_RG_XXX_YEAR) — not an extension of this one.
```

## 4. Diff output schema

```json
{
  "framework_code": "ASIC_AI_2024",
  "retrieved_date": "<today>",
  "rows_extracted": <int>,
  "rows_matching_seed": <int>,
  "rows_with_changes": <int>,
  "changes": [...],
  "structural_flags": []
}
```

## 5. Known edge cases

1. REP 798 is a REPORT (observations), not binding regulation. The BINDING obligations come from the Corporations Act s912A and Market Integrity Rules. Controls must reference the binding instrument where applicable.
2. ASIC Chair speeches (Joe Longo) are informal signals — do NOT extract controls from speeches alone. Use them as supplementary context to interpret REP 798.
3. Corporate Plan enforcement priorities change annually (2024-25, 2025-26, 2026-27). Current stub references 2026 priorities; when ASIC publishes 2027-28 priorities, refresh will flag `structural_flag: "new_enforcement_priorities"` and propose an ASIC.PRIORITIES_2027 control or similar.
4. Cross-reference with Design and Distribution Obligations (DDO) + RG 274 + RG 78 when extracting ASIC.DISCLOSURE and ASIC.CONSUMER_HARM.

---

## Strategic positioning note (for compliance-sales pitch)

ASIC has publicly declared the problem: *"Beware the gap: Governance arrangements in the face of AI innovation"* (REP 798 title). DATAPAI's compliance assessor **directly addresses this named gap** — any AFSL holder in the room knows the regulator has targeted them. The 2026 priorities add urgency: agentic AI + automated consumer decisions will be examined.

This is the strongest single framework-to-product-market-fit alignment in our catalog today. Treat ASIC assessments as the leading demo for AU financial-services customers.
