# TinyFish Extraction Prompt — CER_EMISSIONS_2025

> **Framework:** Clean Energy Regulator AI integrity for emissions + certificate markets
> **Publisher:** Clean Energy Regulator
> **Jurisdiction:** AU-ENERGY
> **Effective:** 2012-07-01
> **Stage:** Complete on top-level; refresh for regulator updates

## 1. Framework metadata

| Column | Value |
|---|---|
| `framework_code` | `CER_EMISSIONS_2025` |
| `framework_publisher` | `Clean Energy Regulator` |
| `jurisdiction_code` | `AU-ENERGY` |
| `country_code` | `AU` |
| `is_mandatory` | `true` |
| `industry_scope` | `energy` |
| `source_url` | `https://www.cleanenergyregulator.gov.au/` |

## 2. Fetch configuration

```yaml
fetch:
  primary_url: https://www.cleanenergyregulator.gov.au/
  supplementary_urls:
    - https://www.cleanenergyregulator.gov.au/NGER
    - https://www.cleanenergyregulator.gov.au/ERF
    - https://www.cleanenergyregulator.gov.au/RET
  content_type: auto
  javascript: enabled
  timeout_seconds: 120
```

## 3. Extraction prompt

```
Extract obligations from this framework that apply to AI systems used in
Australian energy sector operations (utilities, networks, O&G, renewables,
market operations).

Control ID pattern: CER.<AREA>  AREA ∈ {NGER, ACCU_PROJECTS, SAFEGUARD, LRET_STC, MARKET_INTEGRITY, DATA_QUALITY, AUDIT_READINESS, FRAUD_PREVENTION, CLIMATE_ACTIVE, NETZERO_DISCLOSURE}

Obligation family mapping:
CER.NGER            → recordkeeping
CER.ACCU_PROJECTS   → testing_monitoring (methodology compliance)
CER.SAFEGUARD       → recordkeeping
CER.LRET_STC        → testing_monitoring
CER.MARKET_INTEGRITY→ risk_management (no wash trades / spoofing)
CER.DATA_QUALITY    → data_governance
CER.AUDIT_READINESS → recordkeeping (reproducibility)
CER.FRAUD_PREVENTION→ risk_management
CER.CLIMATE_ACTIVE  → transparency
CER.NETZERO_DISCLOSURE → transparency (AASB S2)

Invariants:
- industry_scope = 'energy' on every row.
- jurisdiction_code = 'AU-ENERGY' on every row.
- Where the obligation cross-refs another regulator's control (e.g.
  AESCSF citing SOCI, IEC 62443, AU Privacy APPs), preserve the
  cross-reference in `notes`.
```

## 4. Edge cases

1. AASB S2 (climate disclosure) from 2025 — track large-corp applicability thresholds.
2. ACCU market integrity under review (Chubb Review 2023) — updates expected.
3. Safeguard Mechanism reform in effect from 2023 — baseline mechanics evolving.
4. RET sunset: LRET continues, STC phasing out by 2030.
