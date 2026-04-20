# TinyFish Extraction Prompt — OWASP_AGENTIC_2026

> **Framework:** OWASP Top 10 for Agentic Applications 2026
> **Publisher:** OWASP Gen AI Security Project
> **Jurisdiction:** INT (international — OWASP community standard)
> **Effective:** 2026 annual release; updated by OWASP community
> **Stage:** Complete on top-10 items; check for v2026 updates / sub-controls / example expansions

## 1. Framework metadata (constants — pre-populate on every extracted row)

| Column | Value |
|---|---|
| `framework_code` | `OWASP_AGENTIC_2026` |
| `framework_name` | `OWASP Top 10 for Agentic Applications 2026` |
| `framework_publisher` | `OWASP Gen AI Security Project` |
| `jurisdiction_code` | `INT` |
| `jurisdiction_scope` | `international` |
| `country_code` | `INT` |
| `effective_from` | `2026-01-01` |
| `is_mandatory` | `false` |
| `source_url` | `https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/
  supplementary_urls:
    - https://genai.owasp.org/  # landing page may update with new version links
  pdf_fallback: true  # primary content is usually in PDF download link
  content_type: auto
  javascript: enabled
  timeout_seconds: 90
  capture:
    - full_page_text
    - linked_pdf_content
    - content_sha256
    - retrieved_at_utc
```

## 3. Extraction prompt

```
You are extracting control rows for the OWASP Top 10 for Agentic
Applications 2026 framework. Source: OWASP Gen AI Security Project.

Emit one row per top-level item (ASI01..ASI10). If OWASP publishes
sub-items (e.g. ASI01.1) in future versions, emit sub-rows with
dot-notation control_ids — hierarchy is derived automatically.

=== STABLE CONTROL IDS ===
ASI01 — Agent Goal Hijack
ASI02 — Tool Misuse and Exploitation
ASI03 — Identity and Privilege Abuse
ASI04 — Agentic Supply Chain Vulnerabilities
ASI05 — Unexpected Code Execution
ASI06 — Memory and Context Poisoning
ASI07 — Insecure Inter-Agent Communication
ASI08 — Cascading Failures
ASI09 — Human-Agent Trust Exploitation
ASI10 — Rogue Agents

=== OBLIGATION FAMILY MAPPING (fixed) ===
ASI01 → testing_monitoring       (detection of manipulated prompts)
ASI02 → risk_management          (permission scoping)
ASI03 → accountability           (credential / identity management)
ASI04 → third_party_supply_chain
ASI05 → risk_management          (sandboxing / code execution safety)
ASI06 → data_governance          (memory / RAG integrity)
ASI07 → risk_management          (communication security)
ASI08 → risk_management          (isolation / circuit breakers)
ASI09 → human_oversight          (forced confirmations)
ASI10 → testing_monitoring       (behavioural monitoring)

=== EXTRACTION RULES ===
1. control_description: one sentence — the threat statement.
2. mandatory_records: pipe-separated list of controls / mitigations from
   the OWASP Top 10 document per item.
3. source_section: "OWASP Agentic Top 10 §ASI0N"
4. notes: example attacks explicitly listed by OWASP.
5. Watch for OWASP publishing sub-items / technical variants in future
   versions — flag via structural_flags if ASI01.1 / ASI02.a / similar
   new IDs appear.

=== INVARIANTS ===
- OWASP is a community standard — refresh quarterly at most (not weekly)
  since updates are infrequent vs regulator sources.
- Never mutate existing ASI01-ASI10 rows if OWASP publishes a 2027
  version — create framework_code OWASP_AGENTIC_2027 instead.
- The Least Agency principle is the umbrella — note in
  framework-level description, not a separate row.
```

## 4. Diff output schema

Same as other frameworks — JSON with rows_extracted / rows_with_changes / structural_flags.

## 5. Known edge cases

1. Primary content is in a downloadable PDF, not inline on the page — fetcher must follow the download link.
2. OWASP community expands lists over time (example: OWASP LLM Top 10 grew sub-items between 2023 and 2024). Be ready for ASI0N.M sub-items.
3. Cross-reference with OWASP Agentic AI Red Teaming and Agentic AI Security Solutions landscape reports — those provide supplementary controls OWASP expects, worth adding as notes.
