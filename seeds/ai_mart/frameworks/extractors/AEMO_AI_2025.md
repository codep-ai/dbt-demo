# TinyFish Extraction Prompt — AEMO_AI_2025

> **Framework:** AEMO AI guidance for market participants (NEM + WEM)
> **Publisher:** Australian Energy Market Operator
> **Jurisdiction:** AU-ENERGY
> **Effective:** 2025-01-01
> **Stage:** Complete on top-level; refresh for regulator updates

## 1. Framework metadata

| Column | Value |
|---|---|
| `framework_code` | `AEMO_AI_2025` |
| `framework_publisher` | `Australian Energy Market Operator` |
| `jurisdiction_code` | `AU-ENERGY` |
| `country_code` | `AU` |
| `is_mandatory` | `true` |
| `industry_scope` | `energy` |
| `source_url` | `https://aemo.com.au/initiatives/major-programs/engineering-framework` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://aemo.com.au/initiatives/major-programs/engineering-framework
  supplementary_urls:
    - https://aemo.com.au/energy-systems/electricity/national-electricity-market-nem
    - https://aemo.com.au/en/consultations
    - https://aemo.com.au/en/news
  content_type: auto
  javascript: enabled
  timeout_seconds: 120
```

## 3. Extraction prompt

```
Extract obligations from this framework that apply to AI systems used in
Australian energy sector operations (utilities, networks, O&G, renewables,
market operations).

Control ID pattern: AEMO.<AREA>  AREA ∈ {BID_AI, FORECAST_AI, CAUSER_PAYS, DISPATCH_OVERRIDE, ESCO_AI, RERT_AI, SETTLEMENTS_AI, DATA_QUALITY, WEM_AI, STTM_AI, TRANSPARENCY, INCIDENT_REPORT}

Obligation family mapping:
AEMO.BID_AI         → risk_management (market integrity)
AEMO.FORECAST_AI    → transparency
AEMO.CAUSER_PAYS    → testing_monitoring
AEMO.DISPATCH_OVERRIDE → human_oversight
AEMO.ESCO_AI        → risk_management
AEMO.RERT_AI        → testing_monitoring
AEMO.SETTLEMENTS_AI → recordkeeping
AEMO.DATA_QUALITY   → data_governance
AEMO.WEM_AI         → accountability (WA-specific)
AEMO.STTM_AI        → risk_management (gas STTM)
AEMO.TRANSPARENCY   → transparency
AEMO.INCIDENT_REPORT→ recordkeeping

Invariants:
- industry_scope = 'energy' on every row.
- jurisdiction_code = 'AU-ENERGY' on every row.
- Where the obligation cross-refs another regulator's control (e.g.
  AESCSF citing SOCI, IEC 62443, AU Privacy APPs), preserve the
  cross-reference in `notes`.
```

## 4. Edge cases

1. NEM (NER) and WEM (WEM Rules) have separate rule sets — create distinct rows where obligations diverge.
2. AEMO Engineering Framework guidance is iterative — refresh weekly for current-issues notices.
3. STTM (gas) separate from NEM (electricity) — preserve market attribution in notes.
4. Market-integrity AI concern peaked post-2022 price event; expect updates.
