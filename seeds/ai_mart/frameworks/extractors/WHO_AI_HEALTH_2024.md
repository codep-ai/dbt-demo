# TinyFish Extraction Prompt — WHO_AI_HEALTH_2024

> **Framework:** WHO Ethics & Governance of Artificial Intelligence for Health (2021 + LMM guidance 2024)
> **Publisher:** World Health Organization
> **Jurisdiction:** INT-HEALTH (international)
> **Effective:** 2021-06-28 (core report); 2024-01 (LMM Guidance supplement)
> **Stage:** Top-level principles complete; LMM/GenAI obligations refresh quarterly as WHO publishes updates

## 1. Framework metadata

| Column | Value |
|---|---|
| `framework_code` | `WHO_AI_HEALTH_2024` |
| `framework_publisher` | `World Health Organization` |
| `jurisdiction_code` | `INT-HEALTH` |
| `country_code` | `INT` |
| `is_mandatory` | `false` |
| `industry_scope` | `healthcare` |
| `source_url` | `https://www.who.int/publications/i/item/9789240029200` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://www.who.int/publications/i/item/9789240029200
  supplementary_urls:
    - https://www.who.int/publications/i/item/9789240084759       # LMM Guidance 2024
    - https://www.who.int/health-topics/digital-health
    - https://www.who.int/teams/digital-health-and-innovation/governance-of-artificial-intelligence
  pdf_fallback: true
  content_type: auto
  timeout_seconds: 180
```

## 3. Extraction prompt

```
Extract the 6 core ethical principles + supplementary obligations
covering LMICs, workforce, data governance, and LLM/GenAI for health.

Control ID pattern: WHO.P<N>.<AREA> for the 6 principles; WHO.GEN.<AREA>
for supplementary; WHO.2024.<AREA> for LMM-specific updates.

Obligation family mapping:
  P1 AUTONOMY     → human_oversight
  P2 WELLBEING    → risk_management
  P3 TRANSPARENCY → transparency
  P4 ACCOUNTABILITY → accountability
  P5 INCLUSIVE    → impact_assessment (equity + bias)
  P6 RESPONSIVE   → risk_management
  GEN.LMIC        → testing_monitoring
  GEN.WORKFORCE   → impact_assessment
  GEN.DATA_GOV    → data_governance
  GEN.LIAB        → accountability
  GEN.INTERNATL   → third_party_supply_chain
  2024.GENAI      → testing_monitoring (LLM/GenAI-specific)

Invariants:
- Principles are non-binding but widely cited in national regulations —
  customers often ask for WHO alignment even without mandate.
- LMM Guidance (Jan 2024) is the source for LLM/GenAI-specific
  obligations — cite separately from the 2021 core report.
```

## 4. Edge cases

1. PDF is the canonical source for the 2021 report; WHO site HTML is summary. Always parse PDF.
2. WHO periodically publishes supplementary docs (rehabilitation AI, digital twin, pandemic surveillance) — add new `framework_code`s rather than stuffing into this one.
3. UN Res + WHO WHA resolutions on AI may amend principles — watch for annual World Health Assembly updates.
